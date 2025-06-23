import argparse
import io
import os
import random
import tempfile
import sys
import platform
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
    # Get the base path where the script is located
    if getattr(sys, 'frozen', False):
        # Running in a PyInstaller bundle
        base_path = Path(sys._MEIPASS)
    else:
        # Running in normal Python environment
        base_path = Path(__file__).parent

    # Get the current platform
    system = platform.system().lower()
    
    # Construct platform-specific poppler path
    if system == 'windows':
        poppler_path = base_path / "poppler" / "bin_windows"
    elif system == 'darwin':  # macOS
        poppler_path = base_path / "poppler" / "bin_macos"
    elif system == 'linux':
        poppler_path = base_path / "poppler" / "bin_linux"
    else:
        Utils.log_error(f"Unsupported platform: {system}")
        return None

    if poppler_path.exists():
        Utils.log_info(f"Using bundled poppler from: {poppler_path}")
        return str(poppler_path)
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
                Utils.log_error(poppler_error)
                if on_progress:
                    await on_progress(poppler_error)
            
            return None
    else:
        images = [Image.open(io.BytesIO(bytes_arr))]
        if on_progress:
            await on_progress("Read image")

    final_json = {
        "images": {},
        "image_calibration_rects": {},
        "image_sizes": {},
    }

    with tempfile.TemporaryDirectory() as temp_dir:
        for i, image in enumerate(images):
            if on_progress:
                await on_progress(f"Processing image {i}...")

            random_hash = random.randbytes(8).hex()
            image_path = os.path.join(temp_dir, f"image_{random_hash}.png")

            print(f"Saving image to {image_path}")

            # Resize if width is greater than 800
            if image.width > 800:
                width_ratio = 800 / image.width
                image = image.resize(
                    (int(image.width * width_ratio), int(image.height * width_ratio))
                )

            # save to file

            image.save(image_path)

            if needs_calibration:
                #calibration_rect = get_calibration_rect_for_image(image_path, img=image)
                #if calibration_rect is None:
                #    await on_progress(f"Calibration rect not found for image {i}, are you sure it is a valid gabarito?")
                #    continue
                if on_progress:
                    await on_progress(f"Applying calibration to image {i}")

                img = apply_calibration_to_image(image)
                img, _alpha, _beta = Utils.automatic_brightness_and_contrast(img)
                img = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))

                if on_progress:
                    await on_progress(f"Applied calibration to image {i}")

                final_json["image_calibration_rects"][random_hash] = {"x": 0.0, "y": 0.0}
            else:
                img = image

            final_json["images"][random_hash] = img
            final_json["image_sizes"][random_hash] = {
                "width": float(img.width),
                "height": float(img.height),
            }

    if not needs_calibration:
        return list(final_json["images"].keys())

    return final_json
