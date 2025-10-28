#!/bin/bash

# Direct AWS EC2 Deployment Script for Quiz Platform
# This script deploys the application directly to EC2 without GitHub

set -e

echo "🚀 Starting direct AWS EC2 deployment..."

# Check if we're on EC2 instance
if [ ! -f /etc/cloud/cloud.cfg ]; then
    echo "❌ This script should be run on an AWS EC2 instance"
    echo "Please:"
    echo "1. Launch an Ubuntu 22.04 EC2 instance"
    echo "2. Copy this project to the instance using scp or rsync"
    echo "3. Run this script on the EC2 instance"
    exit 1
fi

# Update system packages
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker
echo "🐳 Installing Docker..."
if ! command -v docker &> /dev/null; then
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker $USER
    echo "Docker installed successfully"
else
    echo "Docker already installed"
fi

# Install Docker Compose
echo "🔧 Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed successfully"
else
    echo "Docker Compose already installed"
fi

# Set up environment variables
echo "⚙️ Setting up environment variables..."
if [ ! -f ".env" ]; then
    cp .env.production .env
    
    # Generate secure passwords
    DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)
    
    # Update .env file with generated values
    sed -i "s/your_secure_database_password_here/$DB_PASSWORD/g" .env
    sed -i "s/your_very_secure_jwt_secret_key_here/$JWT_SECRET/g" .env
    
    echo "✅ Environment variables configured with secure random values"
else
    echo "✅ Environment file already exists"
fi

# Create necessary directories
mkdir -p logs

# Set up firewall rules
echo "🔒 Configuring firewall..."
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw --force enable

# Stop any existing containers
echo "🛑 Stopping existing containers..."
sudo docker-compose -f docker-compose.prod.yml down 2>/dev/null || true

# Build and start the application
echo "🏗️ Building and starting the application..."
sudo docker-compose -f docker-compose.prod.yml up -d --build

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 45

# Check if services are running
echo "🔍 Checking service status..."
sudo docker-compose -f docker-compose.prod.yml ps

# Test database connection
echo "🔍 Testing database connection..."
for i in {1..10}; do
    if sudo docker-compose -f docker-compose.prod.yml exec -T postgres pg_isready -U quiz_user -d quiz_platform; then
        echo "✅ Database is ready"
        break
    else
        echo "⏳ Waiting for database... ($i/10)"
        sleep 5
    fi
done

# Display logs
echo "📋 Recent application logs:"
sudo docker-compose -f docker-compose.prod.yml logs --tail=30 app

# Get public IP
PUBLIC_IP=$(curl -s http://checkip.amazonaws.com || echo "Unable to get public IP")

echo ""
echo "✅ Deployment completed!"
echo ""
echo "🌐 Your application should be available at:"
echo "   http://$PUBLIC_IP"
echo ""
echo "📊 To monitor logs:"
echo "   sudo docker-compose -f docker-compose.prod.yml logs -f"
echo ""
echo "🔄 To restart services:"
echo "   sudo docker-compose -f docker-compose.prod.yml restart"
echo ""
echo "🛑 To stop services:"
echo "   sudo docker-compose -f docker-compose.prod.yml down"
echo ""
echo "🔧 Environment file location: $(pwd)/.env"
echo ""
echo "🎮 Test the application by:"
echo "1. Opening http://$PUBLIC_IP in your browser"
echo "2. Registering a new account"
echo "3. Creating or joining a quiz game"