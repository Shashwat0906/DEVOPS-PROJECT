# Multi-stage Docker build for DevOps application

# =====================================================================
# STAGE 1: Dependencies & Build
# =====================================================================
FROM node:20-alpine AS builder

LABEL maintainer="DevOps Team"

# Set working directory
WORKDIR /app

# Copy package files
COPY backend/package*.json ./backend/
COPY frontend/package*.json ./frontend/

# Install dependencies
RUN cd backend && npm ci --only=production

# Copy source code
COPY backend/ ./backend/
COPY frontend/ ./frontend/

# Build frontend (if needed)
RUN cd frontend && npm ci && npm run build || true

# =====================================================================
# STAGE 2: Runtime
# =====================================================================
FROM node:20-alpine

LABEL maintainer="DevOps Team"
LABEL version="1.0"
LABEL description="DevOps Application - AWS ECS Fargate Deployment"

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init curl

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Set working directory
WORKDIR /app

# Copy built application from builder stage
COPY --from=builder /app/backend/ ./backend/

# Copy frontend build artifacts
COPY --from=builder /app/frontend/build/ ./frontend/build/

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV NODE_OPTIONS="--max-old-space-size=512"

# Change ownership to non-root user
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Healthcheck to ensure container is running properly
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["/usr/sbin/dumb-init", "--"]

# Start application
CMD ["node", "backend/server.js"]
