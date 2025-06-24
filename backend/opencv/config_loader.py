#!/usr/bin/env python3
"""
Configuration loader for Answer Card Analyzer
Handles loading configuration from environment files with fallback defaults.
"""

import os
from pathlib import Path
from typing import Dict, Any, Optional


class ConfigLoader:
    """Handles loading and managing configuration from environment files."""

    def __init__(self, config_file: str = "runtime_config.env"):
        self.config_file = config_file
        self.config: Dict[str, str] = {}
        self._load_config()

    def _load_config(self) -> None:
        """Load configuration from file with fallback to environment variables."""
        # Try to load python-dotenv if available
        try:
            from dotenv import load_dotenv
            # Load from file if it exists
            if Path(self.config_file).exists():
                load_dotenv(self.config_file)
        except ImportError:
            # Fallback to manual loading if python-dotenv is not available
            self._manual_load_config()

        # Load from os.environ (which now includes values from dotenv)
        self.config = dict(os.environ)

    def _manual_load_config(self) -> None:
        """Manually load config file if python-dotenv is not available."""
        config_path = Path(self.config_file)
        if not config_path.exists():
            return

        with open(config_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key.strip()] = value.strip()

    def get(self, key: str, default: Any = None) -> str:
        """Get configuration value with optional default."""
        return self.config.get(key, str(default) if default is not None else "")

    def get_bool(self, key: str, default: bool = False) -> bool:
        """Get boolean configuration value."""
        value = self.get(key, str(default)).lower()
        return value in ('true', '1', 'yes', 'on')

    def get_int(self, key: str, default: int = 0) -> int:
        """Get integer configuration value."""
        try:
            return int(self.get(key, str(default)))
        except ValueError:
            return default

    def get_float(self, key: str, default: float = 0.0) -> float:
        """Get float configuration value."""
        try:
            return float(self.get(key, str(default)))
        except ValueError:
            return default

    def is_debug_mode(self) -> bool:
        """Check if debug mode is enabled."""
        return self.get_bool('DEBUG_MODE', False)

    def is_dev_environment(self) -> bool:
        """Check if running in development environment."""
        env = self.get('ENVIRONMENT', 'PROD').upper()
        return env == 'DEV'

    def get_log_level(self) -> str:
        """Get logging level."""
        return self.get('LOG_LEVEL', 'INFO').upper()

    def get_http_config(self) -> Dict[str, Any]:
        """Get HTTP server configuration."""
        is_dev = self.is_dev_environment()
        return {
            'host': self.get('HTTP_HOST', '0.0.0.0'),
            'port': self.get_int('HTTP_PORT_DEV' if is_dev else 'HTTP_PORT_PROD', 8000 if is_dev else 8080),
            'is_dev': is_dev
        }

    def get_websocket_uri(self) -> str:
        """Get WebSocket URI based on environment."""
        if self.is_dev_environment():
            return self.get('WEBSOCKET_URI_DEV', 'ws://localhost:8000')
        else:
            return self.get('WEBSOCKET_URI_PROD', 'wss://orca-app-h5tlv.ondigitalocean.app')

    def get_memory_config(self) -> Dict[str, Any]:
        """Get memory monitoring configuration."""
        return {
            'threshold_percent': self.get_int('MEMORY_THRESHOLD_PERCENT', 90),
            'check_interval': self.get_int('MEMORY_CHECK_INTERVAL', 2)
        }

    def print_config_summary(self) -> None:
        """Print configuration summary for debugging."""
        print("🔧 Configuration Summary:")
        print(f"   Debug Mode: {self.is_debug_mode()}")
        print(f"   Environment: {self.get('ENVIRONMENT', 'PROD')}")
        print(f"   Log Level: {self.get_log_level()}")
        print(f"   HTTP Config: {self.get_http_config()}")
        print(f"   WebSocket URI: {self.get_websocket_uri()}")
        print(f"   Memory Config: {self.get_memory_config()}")
        print()


# Global configuration instance
config = ConfigLoader() 