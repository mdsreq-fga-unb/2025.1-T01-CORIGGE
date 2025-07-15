#!/usr/bin/env python3
"""
Docker Log Following Script
Simple script to follow logs from Docker containers.
"""

import subprocess
import sys
import time
import signal
import os
from pathlib import Path

class LogFollower:
    def __init__(self):
        self.project_containers = ['corigge-backend', 'corigge-nginx']
        self.compose_file = 'docker-compose.yml'
        self.project_root = Path(__file__).parent.parent
        
    def run_command(self, command, shell=True, capture_output=True):
        """Run a command and return the result."""
        try:
            if capture_output:
                result = subprocess.run(
                    command, 
                    shell=shell, 
                    capture_output=True, 
                    text=True,
                    cwd=self.project_root
                )
                return result
            else:
                # For commands that need real-time output (like logs)
                process = subprocess.Popen(
                    command,
                    shell=shell,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    cwd=self.project_root
                )
                return process
        except Exception as e:
            print(f"❌ Error running command '{command}': {e}")
            return None

    def check_docker_running(self):
        """Check if Docker is running."""
        print("🐳 Checking if Docker is running...")
        result = self.run_command("docker info")
        if result and result.returncode == 0:
            print("✅ Docker is running")
            return True
        else:
            print("❌ Docker is not running. Please start Docker and try again.")
            return False

    def get_running_containers(self):
        """Get list of running containers for this project."""
        print("🔍 Checking for running project containers...")
        result = self.run_command("docker ps --format '{{.Names}}'")
        if result and result.returncode == 0:
            all_containers = result.stdout.strip().split('\n') if result.stdout.strip() else []
            project_containers = [c for c in all_containers if c in self.project_containers]
            if project_containers:
                print(f"📦 Found running containers: {', '.join(project_containers)}")
                return project_containers
            else:
                print("📦 No project containers currently running")
                print("💡 Tip: Start containers first with 'docker-compose up -d'")
                return []
        return []

    def check_containers_exist(self):
        """Check if containers exist (running or stopped)."""
        print("🔍 Checking if project containers exist...")
        result = self.run_command("docker ps -a --format '{{.Names}}'")
        if result and result.returncode == 0:
            all_containers = result.stdout.strip().split('\n') if result.stdout.strip() else []
            project_containers = [c for c in all_containers if c in self.project_containers]
            if project_containers:
                print(f"📦 Found project containers: {', '.join(project_containers)}")
                return True
            else:
                print("📦 No project containers found")
                print("💡 Tip: Build and start containers first with 'docker-compose up -d'")
                return False
        return False

    def follow_logs(self):
        """Follow logs from all containers."""
        print("📋 Following container logs... (Press Ctrl+C to stop)")
        print("=" * 60)
        
        try:
            # Use docker-compose logs with follow
            process = self.run_command("docker-compose logs -f --tail=50", capture_output=False)
            if process:
                print("🔍 Log stream started - showing real-time output:")
                print("-" * 50)
                
                # Stream the output in real-time
                for line in process.stdout:
                    print(line.rstrip())
                    
                process.wait()
            else:
                print("❌ Failed to start log following")
                return False
                
        except KeyboardInterrupt:
            print("\n📋 Stopped following logs")
            if process:
                process.terminate()
                process.wait()
        finally:
            print("\n" + "=" * 60)
            print("📋 Log following session ended")
        
        return True

    def main(self):
        """Main execution flow."""
        print("📋 Docker Log Following Script")
        print("=" * 50)
        
        # Change to project root directory
        os.chdir(self.project_root)
        print(f"📂 Working directory: {self.project_root}")
        
        # Check if docker-compose.yml exists
        if not os.path.exists(self.compose_file):
            print(f"❌ {self.compose_file} not found in project root")
            return 1
        
        # Check if Docker is running
        if not self.check_docker_running():
            return 1

        # Check if containers exist
        if not self.check_containers_exist():
            return 1
        
        # Check for running containers
        running_containers = self.get_running_containers()
        if not running_containers:
            print("\n⚠️  No containers are currently running.")
            print("💡 You can start them with: docker-compose up -d")
            choice = input("📋 Do you want to follow logs anyway? (y/N): ").strip().lower()
            if choice not in ['y', 'yes']:
                return 0
        
        try:
            # Follow logs
            self.follow_logs()
            return 0
            
        except KeyboardInterrupt:
            print("\n⚠️  Process interrupted by user")
            return 1
        except Exception as e:
            print(f"❌ Unexpected error: {e}")
            return 1

def signal_handler(signum, frame):
    """Handle Ctrl+C gracefully."""
    print("\n⚠️  Received interrupt signal. Cleaning up...")
    sys.exit(1)

if __name__ == "__main__":
    # Set up signal handler for graceful shutdown
    signal.signal(signal.SIGINT, signal_handler)
    
    # Run the log follower
    follower = LogFollower()
    exit_code = follower.main()
    sys.exit(exit_code) 