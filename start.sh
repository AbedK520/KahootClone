#!/bin/sh

# Start nginx in background
nginx -g "daemon off;" &

# Wait for database to be ready
echo "Waiting for database connection..."
cd /app/backend

# Run database migrations
npx prisma migrate deploy
npx prisma generate

# Seed database if needed
npm run seed

# Start the backend server
echo "Starting backend server..."
node dist/server.js