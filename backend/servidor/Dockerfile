# Build stage
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM node:18-alpine AS production

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production

# Copy built files from builder stage
COPY --from=builder /app/dist ./dist

# Set default environment variables
ENV PORT=4512 \
    NODE_ENV=production \
    CORS_ORIGIN=http://localhost:4512

# Expose the port the app runs on
EXPOSE 4512

# Start the application
CMD ["npm", "run", "start"] 