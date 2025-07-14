#!/usr/bin/env python3
"""
Corigge OpenCV Backend Development Runner
This script installs requirements and runs the OpenCV processing server for development.
"""

import os
import sys
import subprocess
import time
from pathlib import Path

def log_message(message):
    """Log a message with timestamp and Corigge branding."""
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    print(f"[corigge][opencv-dev] {timestamp} - {message}")

def run_command(command, cwd=None, check=True):
    """Run a command and handle errors."""
    try:
        log_message(f"Running: {' '.join(command)}")
        result = subprocess.run(
            command,
            cwd=cwd,
            check=check,
            capture_output=False,
            text=True
        )
        return result.returncode == 0
    except subprocess.CalledProcessError as e:
        log_message(f"Command failed with exit code {e.returncode}")
        return False
    except Exception as e:
        log_message(f"Error running command: {e}")
        return False

def check_python_version():
    """Check if Python version is compatible."""
    if sys.version_info < (3, 8):
        log_message("Error: Python 3.8 or higher is required")
        return False
    log_message(f"Python version: {sys.version}")
    return True

def install_requirements():
    """Install the OpenCV requirements."""
    log_message("Installing OpenCV backend requirements...")
    
    # Get the project root (parent of scripts folder)
    project_root = Path(__file__).parent.parent
    opencv_dir = project_root / "backend" / "opencv"
    requirements_file = opencv_dir / "requirements.txt"
    
    if not requirements_file.exists():
        log_message(f"Error: Requirements file not found at {requirements_file}")
        return False
    
    log_message(f"Requirements file found: {requirements_file}")
    
    # Install requirements
    success = run_command([
        sys.executable, "-m", "pip", "install", "-r", str(requirements_file)
    ])
    
    if success:
        log_message("✅ Requirements installed successfully")
    else:
        log_message("❌ Failed to install requirements")
    
    return success

def run_opencv_server():
    """Run the OpenCV processing server."""
    log_message("Starting OpenCV processing server...")
    
    # Get the project root (parent of scripts folder)
    project_root = Path(__file__).parent.parent
    opencv_dir = project_root / "backend" / "opencv"
    main_script = opencv_dir / "main_processing_computer_local.py"
    
    if not main_script.exists():
        log_message(f"Error: Main script not found at {main_script}")
        return False
    
    log_message(f"Main script found: {main_script}")
    log_message("🚀 Starting Corigge OpenCV Backend Server for Development")
    log_message("Press Ctrl+C to stop the server")
    
    # Set debug mode for development
    os.environ['DEBUG_MODE'] = 'true'
    
    try:
        # Run the server (this will block until interrupted)
        subprocess.run([
            sys.executable, str(main_script)
        ], cwd=str(opencv_dir), check=False)
        
    except KeyboardInterrupt:
        log_message("🛑 Server stopped by user")
        return True
    except Exception as e:
        log_message(f"❌ Error running server: {e}")
        return False
    
    return True

def main():
    """Main function to run the development server."""
    log_message("🐳 Corigge OpenCV Backend Development Server")
    log_message("=" * 60)
    
    # Check Python version
    if not check_python_version():
        sys.exit(1)
    
    # Install requirements
    if not install_requirements():
        log_message("❌ Failed to install requirements. Exiting.")
        sys.exit(1)
    
    # Run the server
    log_message("=" * 60)
    if not run_opencv_server():
        log_message("❌ Server failed to start or crashed. Exiting.")
        sys.exit(1)
    
    log_message("✅ Development server session completed")

if __name__ == "__main__":
    main() 