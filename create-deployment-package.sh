#!/bin/bash

# Create deployment package for AWS EC2
echo "📦 Creating deployment package..."

# Create timestamp for unique filename
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
PACKAGE_NAME="quiz-platform-${TIMESTAMP}.tar.gz"

# Create tar archive excluding unnecessary files
tar --exclude='node_modules' \
    --exclude='.git' \
    --exclude='*.log' \
    --exclude='logs' \
    --exclude='.DS_Store' \
    --exclude='*.tar.gz' \
    --exclude='quiz-backend*.tar.gz' \
    --exclude='*.pem' \
    --exclude='.env' \
    --exclude='dist' \
    --exclude='build' \
    -czf "$PACKAGE_NAME" .

echo "✅ Package created: $PACKAGE_NAME"
echo ""
echo "📋 Next steps:"
echo "1. Transfer to EC2: scp -i your-key.pem $PACKAGE_NAME ubuntu@your-ec2-ip:~/"
echo "2. Connect to EC2: ssh -i your-key.pem ubuntu@your-ec2-ip"
echo "3. Extract: tar -xzf $PACKAGE_NAME"
echo "4. Deploy: ./deploy-direct.sh"
echo ""
echo "📊 Package size:"
ls -lh "$PACKAGE_NAME"