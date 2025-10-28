# Multi-stage build for production deployment
FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY frontend/package*.json ./frontend/
COPY backend/package*.json ./backend/

# Install dependencies
RUN npm ci --only=production && npm cache clean --force
RUN cd frontend && npm ci --only=production && npm cache clean --force
RUN cd backend && npm ci --only=production && npm cache clean --force

# Build frontend
FROM base AS frontend-builder
WORKDIR /app/frontend

COPY frontend/package*.json ./
RUN npm ci

COPY frontend/ ./
RUN npm run build

# Build backend
FROM base AS backend-builder
WORKDIR /app/backend

COPY backend/package*.json ./
RUN npm ci

COPY backend/ ./
RUN npm run build

# Production image
FROM base AS runner
WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy built applications
COPY --from=frontend-builder /app/frontend/dist ./frontend/dist
COPY --from=backend-builder /app/backend/dist ./backend/dist
COPY --from=backend-builder /app/backend/prisma ./backend/prisma
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/backend/node_modules ./backend/node_modules

# Copy package files
COPY package*.json ./
COPY backend/package*.json ./backend/

# Set up nginx for frontend
RUN apk add --no-cache nginx

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Change ownership
RUN chown -R nextjs:nodejs /app
USER nextjs

EXPOSE 80 3001

# Start script
COPY start.sh ./
RUN chmod +x start.sh

CMD ["./start.sh"]