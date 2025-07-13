#!/usr/bin/env python3
"""
Script to install dependencies and run the backend server with monitoring.
This script handles the complete setup and execution of the backend server.
"""

import os
import subprocess
import sys
import argparse
from pathlib import Path

def log_message(message):
    """Print a timestamped message."""
    import datetime
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}")

def run_command(command, cwd=None, check=True):
    """Run a command and handle errors gracefully."""
    try:
        log_message(f"Running: {command}")
        result = subprocess.run(
            command,
            shell=True,
            cwd=cwd,
            check=check,
            text=True,
            capture_output=False  # Show output in real-time
        )
        return result.returncode == 0
    except subprocess.CalledProcessError as e:
        log_message(f"Command failed with exit code {e.returncode}: {command}")
        return False
    except Exception as e:
        log_message(f"Error running command: {e}")
        return False

def install_python_dependencies():
    """Install Python dependencies for the monitoring script."""
    log_message("Installing Python dependencies...")
    
    # Get the project root directory
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    backend_servidor_dir = project_root / "backend" / "servidor"
    requirements_file = backend_servidor_dir / "requirements.txt"
    
    if not requirements_file.exists():
        log_message(f"Requirements file not found: {requirements_file}")
        return False
    
    # Install dependencies
    pip_command = f"{sys.executable} -m pip install -r {requirements_file}"
    return run_command(pip_command)

def install_node_dependencies():
    """Install Node.js dependencies for the backend server."""
    log_message("Installing Node.js dependencies...")
    
    # Get the project root directory
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    backend_servidor_dir = project_root / "backend" / "servidor"
    
    if not backend_servidor_dir.exists():
        log_message(f"Backend servidor directory not found: {backend_servidor_dir}")
        return False
    
    # Check if package.json exists
    package_json = backend_servidor_dir / "package.json"
    if not package_json.exists():
        log_message(f"package.json not found: {package_json}")
        return False
    
    # Install Node.js dependencies
    npm_command = "npm install"
    return run_command(npm_command, cwd=str(backend_servidor_dir))

def run_monitoring_script(branch="main"):
    """Run the start_and_monitor.py script."""
    log_message(f"Starting backend server with monitoring (branch: {branch})...")
    
    # Get the project root directory
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    backend_servidor_dir = project_root / "backend" / "servidor"
    monitor_script = backend_servidor_dir / "start_and_monitor.py"
    
    if not monitor_script.exists():
        log_message(f"Monitoring script not found: {monitor_script}")
        return False
    
    # Run the monitoring script
    python_command = f"{sys.executable} {monitor_script} --branch {branch}"
    return run_command(python_command, cwd=str(backend_servidor_dir), check=False)

def main():
    """Main function to orchestrate the setup and execution."""
    parser = argparse.ArgumentParser(description='Install dependencies and run backend server with monitoring.')
    parser.add_argument('--branch', default='main', help='Git branch to monitor (default: main)')
    parser.add_argument('--skip-deps', action='store_true', help='Skip dependency installation')
    args = parser.parse_args()
    
    log_message("Starting backend server setup and monitoring...")
    
    # Install dependencies unless skipped
    if not args.skip_deps:
        log_message("Installing dependencies...")
        
        # Install Python dependencies
        if not install_python_dependencies():
            log_message("Failed to install Python dependencies")
            sys.exit(1)
        
        # Install Node.js dependencies
        if not install_node_dependencies():
            log_message("Failed to install Node.js dependencies")
            sys.exit(1)
        
        log_message("Dependencies installed successfully!")
    else:
        log_message("Skipping dependency installation...")
    
    # Run the monitoring script
    log_message("Starting monitoring script...")
    try:
        run_monitoring_script(args.branch)
    except KeyboardInterrupt:
        log_message("Monitoring script interrupted by user")
    except Exception as e:
        log_message(f"Error running monitoring script: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 