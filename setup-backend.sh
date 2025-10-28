#!/bin/bash

# Connect to EC2 and deploy backend
ssh -i quiz-platform-key.pem -o StrictHostKeyChecking=no ec2-user@3.15.195.165 << 'EOF'

# Update system
sudo yum update -y

# Install Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs git

# Install PM2 globally
sudo npm install -g pm2

# Create app directory
mkdir -p ~/quiz-platform
cd ~/quiz-platform

# For now, we'll create a minimal backend setup
# In a real deployment, you'd clone from GitHub

echo "✅ EC2 instance ready for backend deployment"
echo "🌐 Public IP: 3.15.195.165"

EOF