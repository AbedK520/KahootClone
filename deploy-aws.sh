#!/bin/bash

# AWS EC2 Deployment Script for Quiz Platform
# This script sets up the application on a fresh Ubuntu EC2 instance

set -e

echo "🚀 Starting AWS EC2 deployment..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker
echo "🐳 Installing Docker..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
echo "🔧 Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add current user to docker group
sudo usermod -aG docker $USER

# Install Git
echo "📥 Installing Git..."
sudo apt install -y git

# Clone the repository
echo "📂 Cloning repository..."
if [ -d "KahootClone" ]; then
    echo "Repository already exists, pulling latest changes..."
    cd KahootClone
    git pull origin main
else
    git clone https://github.com/AbedK520/KahootClone.git
    cd KahootClone
fi

# Set up environment variables
echo "⚙️ Setting up environment variables..."
if [ ! -f ".env" ]; then
    cp .env.production .env
    echo "📝 Please edit .env file with your production values:"
    echo "   - Set a secure POSTGRES_PASSWORD"
    echo "   - Set a secure JWT_SECRET"
    echo "   - Configure other environment variables as needed"
    echo ""
    echo "Press any key to continue after editing .env file..."
    read -n 1 -s
fi

# Create necessary directories
mkdir -p logs

# Set up firewall rules
echo "🔒 Configuring firewall..."
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw --force enable

# Build and start the application
echo "🏗️ Building and starting the application..."
sudo docker-compose -f docker-compose.prod.yml up -d --build

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 30

# Check if services are running
echo "🔍 Checking service status..."
sudo docker-compose -f docker-compose.prod.yml ps

# Display logs
echo "📋 Recent logs:"
sudo docker-compose -f docker-compose.prod.yml logs --tail=20

echo ""
echo "✅ Deployment completed!"
echo ""
echo "🌐 Your application should be available at:"
echo "   http://$(curl -s http://checkip.amazonaws.com)"
echo ""
echo "📊 To monitor logs:"
echo "   sudo docker-compose -f docker-compose.prod.yml logs -f"
echo ""
echo "🔄 To restart services:"
echo "   sudo docker-compose -f docker-compose.prod.yml restart"
echo ""
echo "🛑 To stop services:"
echo "   sudo docker-compose -f docker-compose.prod.yml down"