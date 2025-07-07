import argparse
import io
import os
import random
import tempfile
import sys
import platform
import subprocess
from pathlib import Path
from PIL import Image
import cv2
from pdf2image import convert_from_bytes
import json
from find_circles import find_circles, find_circles_cv2
from legacy_calibrate import (
    apply_calibration_to_image,
)
from fastapi import UploadFile

from utils import Utils

def get_poppler_path():
    """Get the path to poppler binaries based on the current platform."""
    # Get the current platform
    system = platform.system().lower()
    
    if system == 'darwin':  # macOS
        # First try Homebrew's poppler
        try:
            result = subprocess.run(["brew", "--prefix", "poppler"], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                brew_path = result.stdout.strip()
                bin_path = Path(brew_path) / "bin"
                if bin_path.exists() and (bin_path / "pdftoppm").exists():
                    Utils.log_info(f"Using Homebrew's poppler from: {bin_path}")
                    # Set library paths for macOS
                    lib_path = Path(brew_path) / "lib"
                    os.environ['DYLD_LIBRARY_PATH'] = f"{lib_path}"
                    os.environ['DYLD_FALLBACK_LIBRARY_PATH'] = f"{lib_path}"
                    return str(bin_path)
        except Exception as e:
            Utils.log_info(f"Could not find Homebrew's poppler: {e}")
    
    # Get the base path where the script is located
    if getattr(sys, 'frozen', False):
        # Running in a PyInstaller bundle
        base_path = Path(sys._MEIPASS)
    else:
        # Running in normal Python environment
        base_path = Path(__file__).parent

    # Get the platform-specific poppler path
    if system == 'windows':
        poppler_path = base_path / "poppler" / "bin_windows"
    elif system == 'darwin':  # macOS
        poppler_path = base_path / "poppler" / "bin_macos"
        if poppler_path.exists():
            # Set library paths for macOS
            os.environ['DYLD_LIBRARY_PATH'] = str(poppler_path)
            os.environ['DYLD_FALLBACK_LIBRARY_PATH'] = str(poppler_path)
    elif system == 'linux':
        poppler_path = base_path / "poppler" / "bin_linux"
        if poppler_path.exists():
            os.environ['LD_LIBRARY_PATH'] = str(poppler_path)
    else:
        Utils.log_error(f"Unsupported platform: {system}")
        return None

    if poppler_path.exists():
        # Check if the required binary exists
        required_binary = "pdftoppm.exe" if system == 'windows' else "pdftoppm"
        binary_path = poppler_path / required_binary
        
        if binary_path.exists():
            Utils.log_info(f"Using bundled poppler from: {poppler_path}")
            return str(poppler_path)
        else:
            Utils.log_info(f"Poppler binary {required_binary} not found in {poppler_path}")
            return None
    else:
        Utils.log_info(f"Bundled poppler not found at {poppler_path}, falling back to system poppler")
        return None

async def read_to_images(file: UploadFile, needs_calibration=True, on_progress=None):
    Utils.log_info("Reading data to images...")

    # Read file bytes
    bytes_arr = await file.read()

    if file.filename.endswith(".pdf"):
        if on_progress:
            await on_progress("Converting PDF to images...")

        try:
            # Get poppler path for PyInstaller builds
            poppler_path = get_poppler_path()
            
            if poppler_path:
                # Use bundled poppler
                images = convert_from_bytes(bytes_arr, thread_count=4, poppler_path=poppler_path)
            else:
                # Use system poppler
                images = convert_from_bytes(bytes_arr, thread_count=4)

            if on_progress:
                await on_progress(f"Converted PDF, {len(images)} pages")
        except Exception as e:
            error_msg = f"Error converting PDF to images: {str(e)}"
            print(error_msg)
            Utils.log_error(error_msg)
            
            # Provide helpful error message for poppler issues
            if "poppler" in str(e).lower() or "Unable to get page count" in str(e):
                poppler_error = "PDF conversion failed - poppler not found. "
                if getattr(sys, 'frozen', False):
                    poppler_error += "This executable was built without poppler support. Please rebuild with poppler included."
                else:
                    poppler_error += "Please install poppler-utils for your system."
                raise Exception(poppler_error) from e
            raise

        # Convert PIL images to base64
        result = {"images": {}, "image_sizes": {}}
        for i, image in enumerate(images):
            # Generate a unique ID for this image
            image_id = f"image_{random.randint(0, 1000000)}"
            result["images"][image_id] = image
            result["image_sizes"][image_id] = {
                "width": image.width,
                "height": image.height
            }

        return result
    else:
        # Handle non-PDF files
        image = Image.open(io.BytesIO(bytes_arr))
        image_id = f"image_{random.randint(0, 1000000)}"
        return {
            "images": {image_id: image},
            "image_sizes": {
                image_id: {
                    "width": image.width,
                    "height": image.height
                }
            }
        }
