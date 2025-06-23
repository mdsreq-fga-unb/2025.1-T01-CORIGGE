import asyncio
from base64 import b64decode, b64encode
from io import BytesIO
from typing import Dict
from PIL import Image
import cv2
from fastapi import UploadFile
import numpy as np
import websockets
from websockets.exceptions import ConnectionClosedError
import json
from queue import SimpleQueue
import traceback
from find_circles import find_circles_cv2, find_circles_fallback
from read_to_images import read_to_images
from websocket_types import BoxRectangleType, WebsocketMessageCommand, WebsocketMessageStatus
from copy import deepcopy
from utils import Utils
import psutil
import os
import sys
from config_loader import config

# Load memory configuration from environment
MEMORY_CONFIG = config.get_memory_config()
MEMORY_THRESHOLD_PERCENT = MEMORY_CONFIG['threshold_percent']
CHECK_INTERVAL = MEMORY_CONFIG['check_interval']
CHUNK_SIZE = 1024 * 200  

# Local server configuration
LOCAL_CONFIG = {
    'host': 'localhost',
    'port': 8765
}

class InternalClientMessageType:
    FILE_RECEIVED = "fileReceived"

def image_as_encoded(image):
    byte_arr = BytesIO()
    image.save(byte_arr, format='PNG') # convert the PIL image to byte array
    encoded_img = b64encode(byte_arr.getvalue()).decode('utf-8') # encode as base64
    return encoded_img

async def send_bytes_in_chunks(websocket, task_id: str, file_data: bytes, file_id: str):
    Utils.log_info(f"Sending file in chunks: {file_id}, size: {len(file_data)}")
    for i in range(0, len(file_data), CHUNK_SIZE):
        chunk = file_data[i:i+CHUNK_SIZE]
        status = WebsocketMessageStatus.SENDING_CHUNK
        if i + CHUNK_SIZE >= len(file_data):
            status = WebsocketMessageStatus.FINAL_CHUNK
        await websocket.send(json.dumps({"status": status,'data': {
            'task_id': task_id,
            'chunk': b64encode(chunk).decode('utf-8'),
            "file_id": file_id
        }}))

# Storage for active connections and their data
connected_clients = {}
chunks_per_file_id = {}
files_received: Dict[str, bytearray] = {}
messages_per_task_id: Dict[str, SimpleQueue] = {}

async def handle_job_received(job, websocket):
    try:
        files_to_wait_for: list = deepcopy(job["file_ids"])

        # Create task queue if it doesn't exist
        if job["task_id"] not in messages_per_task_id:
            messages_per_task_id[job["task_id"]] = SimpleQueue()

        while True:
            if messages_per_task_id[job["task_id"]].empty():
                await asyncio.sleep(0.1)
                continue
            message = messages_per_task_id[job["task_id"]].get()
            
            if message["status"] == InternalClientMessageType.FILE_RECEIVED:
                files_to_wait_for.remove(message["data"]["file_id"])     

            if len(files_to_wait_for) > 0:     
                continue

            await send_progress(websocket, "All files received on local server, starting job", job["task_id"])
            
            try:
                if job["command"] == WebsocketMessageCommand.READ_TO_IMAGES:
                    await handle_read_to_images(job, websocket)
                elif job["command"] == WebsocketMessageCommand.FIND_CIRCLES:
                    await handle_find_circles(job, websocket)
            finally:
                # Clean up resources
                for file_id in job["file_ids"]:
                    if file_id in files_received:
                        del files_received[file_id]
                    if file_id in chunks_per_file_id:
                        del chunks_per_file_id[file_id]
                if job["task_id"] in messages_per_task_id:
                    del messages_per_task_id[job["task_id"]]
            return
    except Exception as e:
        Utils.log_error(f"Error in handle_job_received: {str(e)}")
        try:
            await websocket.send(json.dumps({
                "status": WebsocketMessageStatus.ERROR,
                "data": {
                    "task_id": job["task_id"],
                    "error": str(e)
                }
            }))
        except:
            pass
        # Clean up on error
        for file_id in job.get("file_ids", []):
            if file_id in files_received:
                del files_received[file_id]
            if file_id in chunks_per_file_id:
                del chunks_per_file_id[file_id]
        if job.get("task_id") in messages_per_task_id:
            del messages_per_task_id[job["task_id"]]

async def handle_read_to_images(job, websocket):
    await send_progress(websocket, "Starting to read PDF to images.", job["task_id"])
    images = {}
    
    for file_id in job["file_ids"]:
        try:
            if file_id not in files_received:
                raise Exception(f"File {file_id} not found")

            Utils.log_info(f"Processing file: {file_id} with size: {len(files_received[file_id])}")
            file = files_received[file_id]

            uploadFile = UploadFile(
                file=BytesIO(file),
                filename=job["filename"]
            )

            images_inner = await read_to_images(uploadFile, on_progress=lambda x: send_progress(websocket, x, job["task_id"]))
            await send_progress(websocket, "Completed reading PDF to images.", job["task_id"])
            
            for image in images_inner["images"]:
                try:
                    images_inner["images"][image] = image_as_encoded(images_inner["images"][image])
                except Exception as e:
                    Utils.log_error(f"Error encoding image {image}: {str(e)}")
                    continue

            for key in images_inner:
                if key not in images:
                    images[key] = images_inner[key]
                else:
                    images[key].extend(images_inner[key])

        except Exception as e:
            Utils.log_error(f"Error processing file {file_id}: {str(e)} {traceback.format_exc()}")
            raise

    await send_progress(websocket, "Sending images back to client...", job["task_id"])
    
    images_ids = []
    for index, image in enumerate(images.get("images", {})):
        images_ids.append(image)
        await send_progress(websocket, f"Sending images back to client {index}/{len(images['images'])}...", job["task_id"])
        await send_bytes_in_chunks(websocket, job["task_id"], b64decode(images["images"][image]), image)

    if "images" in images:
        del images["images"]
    
    await websocket.send(json.dumps({
        "status": WebsocketMessageStatus.COMPLETED_TASK,
        "data": {
            "task_id": job["task_id"],
            "images_ids": images_ids,
            **images
        }
    }))

async def handle_find_circles(job, websocket):
    await send_progress(websocket, "Starting to find circles in images.", job["task_id"])
    circles_final = {}
    
    total_files = len(job["file_ids"])
    
    # Add overall progress message
    if total_files > 1:
        await send_progress(websocket, f"Processing {total_files} pages for circle detection...", job["task_id"])
    
    for file_index, file_id in enumerate(job["file_ids"]):
        try:
            if file_id not in files_received:
                raise Exception(f"File {file_id} not found")

            file = files_received[file_id]
            
            try:
                image = Image.open(BytesIO(file))
                cv_image = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
                image.close()  # Explicitly close PIL Image
            except Exception as e:
                Utils.log_error(f"Error loading image {file_id}: {str(e)}")
                continue

            # Create page info for progress messages
            page_info = ""
            if total_files > 1:
                page_info = f"[Page {file_index + 1}/{total_files}] "

            await send_progress(websocket, f"{page_info}Processing image: {file_id}\nStarting page analysis...", job["task_id"])

            # Apply image transformations
            if job.get("image_offset"):
                M = np.float32([[1, 0, job["image_offset"]["x"]], [0, 1, job["image_offset"]["y"]]])
                cv_image = cv2.warpAffine(cv_image, M, cv_image.shape[1::-1], flags=cv2.INTER_LINEAR)

            if job.get("image_angle") is not None:
                center = (cv_image.shape[1] // 2, cv_image.shape[0] // 2)
                M = cv2.getRotationMatrix2D(center, -job["image_angle"], 1)
                cv_image = cv2.warpAffine(cv_image, M, cv_image.shape[1::-1])

            circles_per_box = {}
            
            # Sort boxes with exemplo circles first
            boxes = sorted(job.get("boxes", []), key=lambda x: 0 if x.get("rect_type") == BoxRectangleType.EXEMPLO_CIRCULO else 1)
            total_boxes = len(boxes)

            for box_index, box in enumerate(boxes):
                try:
                    rect = box.get("rect")
                    rect_type = box.get("rect_type")
                    box_name = box.get("name")
                    
                    if not all([rect, rect_type, box_name]):
                        continue

                    circle_size = job.get("circle_size")
                    if rect_type == BoxRectangleType.EXEMPLO_CIRCULO:
                        circle_size = None

                    # Prepare rectangle info for progress tracking
                    rectangle_info = {
                        'index': box_index + 1,
                        'total': total_boxes,
                        'name': box_name,
                        'page_info': page_info  # Add page info to rectangle info
                    }

                    if job.get("use_fallback_method") and box.get("template_circles"):
                        circles = await find_circles_fallback("",
                            rect,
                            rectangle_type=rect_type,
                            template_circles=box["template_circles"],
                            darkness_threshold=job.get("darkness_threshold", 0),
                            img=cv_image,
                            on_progress=lambda x: send_progress(websocket, f"{page_info}{x}", job["task_id"])
                        )
                    else:
                        circles = await find_circles_cv2("", rect, rect_type, 
                            img=cv_image,
                            circle_size=circle_size,
                            dp=job.get("inverse_ratio_accumulator_resolution", 1),
                            darkness_threshold=job.get("darkness_threshold", 0),
                            circle_precision_percentage=job.get("circle_precision_percentage", 1),
                            param2=job.get("param2", 30),
                            on_progress=lambda x: send_progress(websocket, f"{page_info}{x}", job["task_id"]),
                            rectangle_info=rectangle_info
                        )

                    # Process circles
                    if rect_type == BoxRectangleType.EXEMPLO_CIRCULO and circles:
                        job["circle_size"] = circles[0]["radius"] / cv_image.shape[1]

                    for circle in circles:
                        # Normalize coordinates
                        if job.get("image_offset"):
                            circle["center_x"] -= job["image_offset"]["x"]
                            circle["center_y"] -= job["image_offset"]["y"]

                        if job.get("image_angle") is not None:
                            center = (cv_image.shape[1] // 2, cv_image.shape[0] // 2)
                            M = cv2.getRotationMatrix2D(center, job["image_angle"], 1)
                            circle["center_x"], circle["center_y"] = cv2.transform(
                                np.array([[circle["center_x"],circle["center_y"]]]).reshape(-1,1,2),
                                M
                            ).reshape(2)

                        # Normalize to image dimensions
                        circle["center_x"] /= cv_image.shape[1]
                        circle["center_y"] /= cv_image.shape[0]
                        circle["radius"] /= cv_image.shape[1]

                    circles_per_box[box_name] = circles

                except Exception as e:
                    Utils.log_error(f"Error processing box {box_name}: {str(e)}")
                    circles_per_box[box_name] = []

            circles_final[file_id] = circles_per_box
            
            # Add page completion summary
            total_circles_on_page = sum(len(circles) for circles in circles_per_box.values())
            page_progress = f"({file_index + 1}/{total_files})" if total_files > 1 else ""
            await send_progress(websocket, f"{page_info}✅ Page {file_index + 1} complete! {page_progress}\nFound {total_circles_on_page} total circles across {len(circles_per_box)} regions", job["task_id"])

        except Exception as e:
            Utils.log_error(f"Error processing file {file_id}: {str(e)}")
            circles_final[file_id] = {}
            # Add error message for this page
            page_progress = f"({file_index + 1}/{total_files})" if total_files > 1 else ""
            await send_progress(websocket, f"{page_info}❌ Page {file_index + 1} failed {page_progress}\nError: {str(e)}", job["task_id"])

    # Add final summary for multi-page documents
    if total_files > 1:
        total_circles_all_pages = sum(
            sum(len(circles) for circles in page_circles.values()) 
            for page_circles in circles_final.values()
        )
        await send_progress(websocket, f"🎉 All {total_files} pages processed!\nTotal circles found: {total_circles_all_pages} across all pages", job["task_id"])

    await websocket.send(json.dumps({
        "status": WebsocketMessageStatus.COMPLETED_TASK,
        "data": {
            "task_id": job["task_id"],
            "circles": circles_final
        }
    }))

async def send_progress(websocket, message, task_id):
    Utils.log_info(f"Sending progress: {message}")
    await websocket.send(json.dumps({"status": WebsocketMessageStatus.PROGRESS,'data': {
        'task_id': task_id,
        'message': message
    }}))

async def handle_client(websocket, path):
    """Handle incoming WebSocket connections from desktop clients."""
    client_id = f"client_{id(websocket)}"
    connected_clients[client_id] = websocket
    
    Utils.log_info(f"🔗 Client connected: {client_id} from {websocket.remote_address}")
    
    try:
        # Send welcome message
        await websocket.send(json.dumps({
            "status": WebsocketMessageStatus.CONNECTED,
            "data": {
                "message": "Connected to local processing server",
                "server_version": Utils.get_version(),
                "client_id": client_id
            }
        }))
        
        async for message in websocket:
            try:
                response = json.loads(message)
                Utils.log_info(f"📨 Received message from {client_id}: {response.get('command', 'unknown')}")
                
                # Handle different message types
                if type(response["data"]) == dict and response["data"].get("task_id"):
                    task_id = response["data"]["task_id"]
                    if task_id not in messages_per_task_id:
                        messages_per_task_id[task_id] = SimpleQueue()
                
                if "command" in response:
                    if response["command"] == WebsocketMessageCommand.READ_TO_IMAGES or response["command"] == WebsocketMessageCommand.FIND_CIRCLES:
                        Utils.log_info(f"🎯 Processing {response['command']} command")
                        asyncio.create_task(handle_job_received({
                            "command": response["command"],
                            **response["data"]
                        }, websocket))
                    
                    elif response["command"] == WebsocketMessageCommand.PING:
                        await websocket.send(json.dumps({"status": WebsocketMessageStatus.PONG}))
                        Utils.log_info(f"🏓 Ping/Pong with {client_id}")
                
                else:
                    # Handle chunk messages
                    if response["status"] == WebsocketMessageStatus.SENDING_CHUNK:
                        task_id = response["data"]["task_id"]
                        file_id = response["data"]["file_id"]
                        
                        if file_id not in chunks_per_file_id:
                            chunks_per_file_id[file_id] = bytearray()
                        chunks_per_file_id[file_id] += bytearray(b64decode(response["data"]["chunk"]))
                        
                    elif response["status"] == WebsocketMessageStatus.FINAL_CHUNK:
                        task_id = response["data"]["task_id"]
                        file_id = response["data"]["file_id"]
                        
                        if file_id not in chunks_per_file_id:
                            chunks_per_file_id[file_id] = bytearray()
                        
                        Utils.log_info(f"📁 Received complete file: {file_id}")
                        chunks_per_file_id[file_id] += bytearray(b64decode(response["data"]["chunk"]))
                        files_received[file_id] = chunks_per_file_id[file_id]
                        del chunks_per_file_id[file_id]
                        
                        await send_progress(websocket, f'📁 File received: {len(files_received[file_id])} bytes', task_id)
                        
                        messages_per_task_id[task_id].put({"status": InternalClientMessageType.FILE_RECEIVED, "data": {
                            "file_id": file_id
                        }})
                    
                    elif response["status"] == WebsocketMessageStatus.ERROR:
                        Utils.log_error(f"❌ Client error: {response.get('error', 'Unknown error')}")
                        
            except json.JSONDecodeError as e:
                Utils.log_error(f"❌ Invalid JSON from {client_id}: {e}")
                await websocket.send(json.dumps({
                    "status": WebsocketMessageStatus.ERROR,
                    "data": {"error": "Invalid JSON format"}
                }))
            except Exception as e:
                Utils.log_error(f"❌ Error processing message from {client_id}: {str(e)}")
                await websocket.send(json.dumps({
                    "status": WebsocketMessageStatus.ERROR,
                    "data": {"error": str(e)}
                }))
                
    except ConnectionClosedError:
        Utils.log_info(f"🔌 Client disconnected: {client_id}")
    except Exception as e:
        Utils.log_error(f"❌ Error with client {client_id}: {str(e)}")
    finally:
        # Clean up client data
        if client_id in connected_clients:
            del connected_clients[client_id]
        Utils.log_info(f"🧹 Cleaned up client: {client_id}")

async def monitor_memory():
    """
    Monitors the memory usage and restarts the script if memory exceeds a threshold.
    Prints memory usage stats every 5 minutes.
    """
    process = psutil.Process(os.getpid())  # Get current process info
    print_counter = 0  # Counter for printing memory stats
    
    while True:
        mem_info = process.memory_info()
        system_memory = psutil.virtual_memory()
        used_memory_percent = system_memory.percent
        
        # Print memory stats every 5 minutes (60 iterations with 5-second sleep)
        if print_counter >= 60:
            print("\n💾 Memory Usage Stats:")
            print(f"Process RSS (Physical RAM Used): {mem_info.rss / 1024 / 1024:.2f} MB")
            print(f"Process VMS (Total Virtual Memory): {mem_info.vms / 1024 / 1024:.2f} MB")
            print(f"System Memory Used: {used_memory_percent:.1f}%")
            print(f"System Memory Available: {system_memory.available / 1024 / 1024:.2f} MB")
            print(f"Connected Clients: {len(connected_clients)}")
            print("-" * 60)
            print_counter = 0  # Reset counter
        
        if used_memory_percent > MEMORY_THRESHOLD_PERCENT:
            print(f"⚠️  Memory usage is too high ({used_memory_percent}%). Restarting the script.")
            await reset_script()

        await asyncio.sleep(CHECK_INTERVAL)  # Check based on config
        print_counter += 1

async def reset_script():
    """
    Resets the script by terminating the current process and restarting it.
    """
    print("🔄 Resetting the script...")

    if sys.executable:
        os.execv(sys.executable, [sys.executable] + sys.argv)

async def main():
    # Start memory monitoring task
    asyncio.create_task(monitor_memory())
    
    Utils.log_info(f"🚀 Starting Local Processing Server")
    Utils.log_info(f"🏠 Host: {LOCAL_CONFIG['host']}")
    Utils.log_info(f"🔌 Port: {LOCAL_CONFIG['port']}")
    Utils.log_info(f"📖 Version: {Utils.get_version()}")
    Utils.log_info(f"🔧 Debug Mode: {'Enabled' if Utils.is_debug() else 'Disabled'}")
    
    print(f"🎯 Local Processing Server Ready!")
    print(f"🔗 Desktop apps can connect to: ws://{LOCAL_CONFIG['host']}:{LOCAL_CONFIG['port']}")
    print(f"💡 Waiting for connections...")
    
    # Start the WebSocket server
    async with websockets.serve(handle_client, LOCAL_CONFIG['host'], LOCAL_CONFIG['port']):
        Utils.log_info(f"✅ Server listening on {LOCAL_CONFIG['host']}:{LOCAL_CONFIG['port']}")
        await asyncio.Future()  # run forever

if __name__ == "__main__":
    # Load and apply configuration
    if config.is_debug_mode():
        config.print_config_summary()
    
    Utils.set_debug(config.is_debug_mode())
    
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n👋 Server shutting down...")
    except Exception as e:
        Utils.log_error(f"❌ Server error: {str(e)}")
        sys.exit(1) 