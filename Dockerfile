# Use an official Node.js runtime with Python support
FROM node:18-bullseye

# Set working directory
WORKDIR /app

# Install system dependencies for PDF processing and other requirements
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    poppler-utils \
    tesseract-ocr \
    tesseract-ocr-por \
    git \
    curl \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create a symbolic link for python command
RUN ln -s /usr/bin/python3 /usr/bin/python

# Copy package files for Node.js dependencies (from backend/servidor directory)
COPY backend/servidor/package*.json ./backend/servidor/

# Install Node.js dependencies
WORKDIR /app/backend/servidor
RUN npm install

# Copy Python requirements files
COPY backend/servidor/requirements.txt ./

# Install Python dependencies
RUN pip3 install -r requirements.txt

# Copy TypeScript configuration
COPY backend/servidor/tsconfig.json ./
COPY backend/servidor/nodemon.json ./

# Copy source code
COPY backend/servidor/src/ ./src/
COPY backend/servidor/start_and_monitor.py ./
# Copy docker-entrypoint.sh to /app (parent directory)
COPY docker-entrypoint.sh /app/

# Copy other necessary files
COPY backend/servidor/*.json ./

# Create necessary directories
RUN mkdir -p /app/dist /app/logs /app/uploads ./logs ./dist

# Set up git configuration for the container
RUN git config --global --add safe.directory /app
RUN git config --global --add safe.directory '/app/*'
RUN git config --global --add safe.directory '*'
RUN git config --global user.email "docker@corigge.com"
RUN git config --global user.name "Corigge Docker Container"
RUN git config --global init.defaultBranch main

# Make docker-entrypoint.sh executable
RUN chmod +x /app/docker-entrypoint.sh

# Set permissions on directories
RUN chmod -R 755 /app

# Build TypeScript code
RUN npm run build || echo "Build failed, will retry later"

# Set git environment variables for runtime
ENV GIT_DISCOVERY_ACROSS_FILESYSTEM=1

# Expose ports for HTTPS
EXPOSE 3325
EXPOSE 4652

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3325

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3325/health || exit 1

# Switch back to /app directory for entrypoint script
WORKDIR /app

# Run as root to avoid any permission issues with mounted files
# Use the entrypoint script that handles conditional arguments
CMD ["/bin/bash", "./docker-entrypoint.sh"] 