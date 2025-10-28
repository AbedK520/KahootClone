#!/bin/bash

# Fix Node.js installation on Amazon Linux 2
echo "🔧 Fixing Node.js installation..."

EC2_IP="3.128.192.118"
KEY_FILE="quiz-platform-key.pem"

ssh -i $KEY_FILE -o StrictHostKeyChecking=no ec2-user@$EC2_IP << 'EOF'
# Install Node.js using Amazon Linux 2 compatible method
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 16
nvm use 16
nvm alias default 16

# Install PM2
npm install -g pm2

# Go to backend directory
cd backend

# Install dependencies
npm install

# Copy production environment
cp .env.production .env

# Generate Prisma client for SQLite
npx prisma generate

# Run database migrations
npx prisma migrate deploy

# Build the application
npm run build

# Seed the database
npm run seed

# Start with PM2
pm2 start dist/server.js --name "quiz-backend"
pm2 startup
pm2 save

echo "✅ Node.js fixed and backend deployed!"
EOF

echo "🎉 Backend should now be running!"
echo "🔗 Backend URL: http://3.128.192.118:3001"