import os
import subprocess
import signal
import time
import logging
import argparse
from pathlib import Path
from dotenv import load_dotenv
import threading
import gc
import psutil
from logging.handlers import RotatingFileHandler

# Load environment variables from .env file
load_dotenv()

# Set up logging with rotation to prevent unbounded log file growth
log_dir = Path(__file__).parent / "logs"
log_dir.mkdir(exist_ok=True)  # Create logs directory if it doesn't exist
log_file = log_dir / "process.log"

# File handler for persistent logs
file_handler = RotatingFileHandler(
    log_file, 
    maxBytes=10*1024*1024,  # 10MB max file size
    backupCount=5  # Keep 5 backup files
)
file_handler.setFormatter(logging.Formatter(
    "[corigge][monitor] %(asctime)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
))

# Console handler for Docker logs visibility
console_handler = logging.StreamHandler()
console_handler.setFormatter(logging.Formatter(
    "[corigge][monitor] %(asctime)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
))

logging.basicConfig(
    level=logging.INFO,
    handlers=[file_handler, console_handler]
)

# Global variables for thread management
active_threads = []
shutdown_event = threading.Event()

def log_message(message):
    print(message)
    logging.info(message)

def cleanup_threads():
    """Clean up any active threads."""
    global active_threads
    shutdown_event.set()
    
    for thread in active_threads[:]:  # Create a copy of the list
        if thread.is_alive():
            thread.join(timeout=2.0)  # Wait up to 2 seconds for thread to finish
        active_threads.remove(thread)
    
    shutdown_event.clear()
    gc.collect()  # Force garbage collection

def log_memory_usage():
    """Log current memory usage for monitoring."""
    try:
        process = psutil.Process()
        memory_info = process.memory_info()
        memory_mb = memory_info.rss / 1024 / 1024
        log_message(f"Corigge: Memory usage: {memory_mb:.2f} MB, Active threads: {len(active_threads)}")
    except Exception as e:
        log_message(f"Corigge: Error getting memory info: {e}")

def run_git_command_safely(command, cwd=None, timeout=30):
    """Run git command with proper resource cleanup and timeout."""
    try:
        result = subprocess.run(
            command,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False  # Don't raise exception on non-zero exit
        )
        
        # Only log errors or important failures
        if result.returncode != 0 and result.stderr.strip():
            log_message(f"Corigge: Git command failed: {' '.join(command)} - {result.stderr.strip()}")
            
        return result
    except subprocess.TimeoutExpired:
        log_message(f"Corigge: Git command timed out: {' '.join(command)}")
        return None
    except Exception as e:
        log_message(f"Corigge: Error running git command {' '.join(command)}: {e}")
        return None

def cleanup_git_stashes(repo_dir):
    """Clean up old git stashes to prevent accumulation.
    
    This function is Docker-specific and only runs inside containers.
    """
    try:
        # Check how many stashes we have
        stash_list = run_git_command_safely(["git", "stash", "list"], cwd=repo_dir)
        if stash_list and stash_list.returncode == 0:
            stash_count = len(stash_list.stdout.strip().split('\n')) if stash_list.stdout.strip() else 0
            if stash_count > 10:  # Only clean up if we have more than 10 stashes
                log_message(f"Corigge: Cleaning up {stash_count} git stashes")
                run_git_command_safely(["git", "stash", "clear"], cwd=repo_dir)
    except Exception as e:
        log_message(f"Corigge: Warning - Could not clean up git stashes: {e}")

def check_for_updates(repo_dir, branch):
    """Check if the remote repository has new commits."""
    original_dir = os.getcwd()
    try:
        os.chdir(repo_dir)
        
        # Check git setup first
        if not os.path.exists('.git'):
            log_message("Corigge: Error - .git directory not found in repository")
            return False
            
        # Test basic git operations
        test_result = run_git_command_safely(["git", "rev-parse", "--git-dir"], cwd=repo_dir)
        if test_result is None or test_result.returncode != 0:
            log_message("Corigge: Git repository not accessible - auto-updates disabled")
            return False
            
        # Use safe git command runner
        fetch_result = run_git_command_safely(["git", "fetch", "origin"], cwd=repo_dir)
        if fetch_result is None or fetch_result.returncode != 0:
            error_msg = fetch_result.stderr if fetch_result and fetch_result.stderr else "Unknown error"
            log_message(f"Corigge: Warning - Failed to fetch from origin: {error_msg.strip()}")
            return False
            
        local_result = run_git_command_safely(["git", "rev-parse", "HEAD"], cwd=repo_dir)
        remote_result = run_git_command_safely(["git", "rev-parse", f"origin/{branch}"], cwd=repo_dir)
        
        if local_result is None or remote_result is None:
            log_message("Corigge: Warning - Failed to get commit hashes")
            return False
            
        local_commit = local_result.stdout.strip()
        remote_commit = remote_result.stdout.strip()
        
        return local_commit != remote_commit
        
    except Exception as e:
        log_message(f"Corigge: Error checking for updates: {e}")
        return False
    finally:
        os.chdir(original_dir)

def pull_updates(repo_dir, branch):
    """Pull the latest changes from the remote repository.
    
    Stashes local changes, pulls updates, and falls back to hard reset if needed.
    """
    original_dir = os.getcwd()
    try:
        os.chdir(repo_dir)
        log_message(f"Corigge: Pulling updates from {branch}.")
        
        # Stash any local changes to avoid conflicts
        stash_result = run_git_command_safely(["git", "stash", "push", "-m", "Auto-stash before update"], cwd=repo_dir)
        if stash_result and stash_result.returncode != 0:
            log_message("Corigge: Warning - Could not stash changes, continuing with pull...")
        
        # Pull the latest changes
        pull_result = run_git_command_safely(["git", "pull", "origin", branch], cwd=repo_dir)
        if pull_result is None or pull_result.returncode != 0:
            # If pull fails, try a hard reset to force update
            log_message("Corigge: Pull failed, attempting hard reset...")
            reset_result = run_git_command_safely(["git", "reset", "--hard", f"origin/{branch}"], cwd=repo_dir)
            if reset_result is None or reset_result.returncode != 0:
                log_message("Corigge: Warning - Could not update repository, continuing with existing files")
            else:
                log_message("Corigge: Successfully updated via hard reset")
        else:
            log_message("Corigge: Successfully pulled updates")
            
    except Exception as e:
        log_message(f"Corigge: Error pulling updates: {e}")
        # Don't raise exception, just log and continue
        log_message("Corigge: Continuing with existing code despite update failure")
    finally:
        os.chdir(original_dir)

def start_process(command):
    """Start a subprocess with the given command and print logs in real time."""
    log_message(f"Corigge: Starting subprocess with command: {command}")
    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        shell=True,
        text=True,                 # Decode bytes to string automatically
        preexec_fn=os.setsid
    )
    # Print the logs in a separate thread or inline
    print_logs_in_real_time(process)
    return process

def print_logs_in_real_time(process):
    """Print logs from the subprocess in real time with proper resource management."""
    def stream_output(stream, prefix):
        try:
            while not shutdown_event.is_set():
                line = stream.readline()
                if not line:  # End of stream
                    break
                if line.strip():  # Only log non-empty lines
                    message = f"{prefix}: {line.strip()}"
                    log_message(message)
        except Exception as e:
            log_message(f"Corigge: Error reading from {prefix}: {e}")
        finally:
            try:
                stream.close()
            except:
                pass
    
    # Create threads for stdout and stderr with proper management
    stdout_thread = threading.Thread(target=stream_output, args=(process.stdout, "STDOUT"), daemon=True)
    stderr_thread = threading.Thread(target=stream_output, args=(process.stderr, "STDERR"), daemon=True)
    
    stdout_thread.start()
    stderr_thread.start()
    
    active_threads.extend([stdout_thread, stderr_thread])

def stop_process(process):
    """Stop the given subprocess with proper cleanup."""
    try:
        if process and process.poll() is None:  # Check if process is running
            # First, try graceful termination
            os.killpg(os.getpgid(process.pid), signal.SIGTERM)
            
            # Wait for process to terminate gracefully
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                # Force kill if it doesn't terminate gracefully
                log_message("Corigge: Process didn't terminate gracefully, force killing...")
                os.killpg(os.getpgid(process.pid), signal.SIGKILL)
                process.wait()
            
            # Clean up process resources
            if process.stdout and not process.stdout.closed:
                process.stdout.close()
            if process.stderr and not process.stderr.closed:
                process.stderr.close()
            if process.stdin and not process.stdin.closed:
                process.stdin.close()
                
        # Clean up threads after stopping process
        cleanup_threads()
        
    except Exception as e:
        log_message(f"Corigge: Error stopping process: {e}")

def restart_process_if_crashed(process, command):
    """Check if the process has crashed and restart it."""
    try:
        if process.poll() is not None:  # If process is not running
            log_message("Corigge: Process crashed. Restarting...")
            return start_process(command)
    except Exception as e:
        log_message(f"Corigge: Error occurred: {e}")
        return None
    return process

def main():
    parser = argparse.ArgumentParser(description='Monitor and auto-update Corigge git repository.')
    parser.add_argument('--branch', default='main', help='Git branch to monitor (default: main)')
    args = parser.parse_args()

    # Determine repository directory - should be the mounted volume root  
    # Since we're running from /app/backend/servidor but .git is at /app
    REPO_DIR = "/app" if os.path.exists('/app/.git') else "../.."
    START_COMMAND = "npm run build-and-start"
    CHECK_INTERVAL = 10  # Interval in seconds to check for updates
    BRANCH = args.branch
    
    # Try to fix git permissions if running in Docker with mounted volumes
    if os.path.exists('/.dockerenv') and os.path.exists('/app/.git'):
        try:
            # Test if we can access git
            test_result = subprocess.run(['git', 'status', '--porcelain'], 
                                       cwd='/app', capture_output=True, text=True, timeout=5)
            if test_result.returncode != 0:
                # Try to fix ownership (requires sudo access which is configured in Dockerfile)
                subprocess.run(['sudo', 'chown', '-R', 'appuser:appuser', '/app/.git'], 
                             check=False, capture_output=True)
        except Exception:
            pass  # Continue silently
    
    # Fix Python package installation permissions in Docker
    if os.path.exists('/app') and os.path.exists('/.dockerenv'):
        os.environ['PYTHONUSERBASE'] = '/app/.local'
        os.environ['PIP_USER'] = '1'
        # Try to create the directory, if it fails due to permissions, continue
        try:
            os.makedirs('/app/.local', exist_ok=True)
        except PermissionError:
            pass  # Directory should be handled by Docker volume
    
    current_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(current_dir)

    log_message(f"Corigge: Monitoring branch: {BRANCH}")
    
    # Set git environment variables
    os.environ['GIT_DISCOVERY_ACROSS_FILESYSTEM'] = '1'
    
    # Check if git repository is accessible
    git_path = os.path.join(REPO_DIR, '.git')
    if os.path.exists(git_path):
        log_message("Corigge: Git auto-update enabled for all files")
    else:
        log_message("Corigge: Git repository not found - auto-updates disabled")

    process = start_process(START_COMMAND)
    
    # Memory monitoring counter
    memory_check_counter = 0
    MEMORY_CHECK_INTERVAL = 60  # Log memory every 60 iterations (10 minutes)
    
    # Git cleanup counter
    git_cleanup_counter = 0
    GIT_CLEANUP_INTERVAL = 360  # Clean up git stashes every 360 iterations (1 hour)

    try:
        while True:
            # Log memory usage periodically
            memory_check_counter += 1
            if memory_check_counter >= MEMORY_CHECK_INTERVAL:
                log_memory_usage()
                memory_check_counter = 0
            
            # Clean up git stashes periodically (only in Docker containers)
            git_cleanup_counter += 1
            if git_cleanup_counter >= GIT_CLEANUP_INTERVAL and os.path.exists('/.dockerenv'):
                cleanup_git_stashes(REPO_DIR)
                git_cleanup_counter = 0
            
            if check_for_updates(REPO_DIR, BRANCH):
                log_message(f"Corigge: New changes detected in branch {BRANCH}. Updating...")
                stop_process(process)
                pull_updates(REPO_DIR, BRANCH)
                
                log_message("Corigge: Starting the process...")
                process = start_process(START_COMMAND)
                
                # Force garbage collection after major operations
                gc.collect()
                log_memory_usage()
            else:
                new_process = restart_process_if_crashed(process, START_COMMAND)
                if new_process is None:
                    log_message("Corigge: Process crashed and could not be restarted. trying again in 10 seconds...")

                    while new_process is None:
                        time.sleep(10)
                        new_process = start_process(START_COMMAND)
                else:
                    process = new_process

            time.sleep(CHECK_INTERVAL)
    except KeyboardInterrupt:
        log_message("Corigge: Exiting. Stopping subprocess...")
        stop_process(process)
    finally:
        cleanup_threads()

if __name__ == "__main__":
    main() 