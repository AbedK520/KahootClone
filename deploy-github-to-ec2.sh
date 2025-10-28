#!/bin/bash

# Complete GitHub to EC2 Deployment Script
# This script creates EC2 infrastructure and deploys from GitHub

set -e

echo "🚀 GitHub to EC2 Deployment for Quiz Platform"
echo "============================================="

# Configuration
REGION="us-east-2"
INSTANCE_TYPE="t3.medium"
KEY_NAME="quiz-platform-key"
SECURITY_GROUP_NAME="quiz-platform-sg"
GITHUB_REPO="https://github.com/AbedK520/KahootClone.git"

# Check if AWS CLI is configured
check_aws_config() {
    echo "🔍 Checking AWS configuration..."
    
    if ! aws sts get-caller-identity &>/dev/null; then
        echo "❌ AWS CLI not configured. Please run:"
        echo "   aws configure"
        echo "   Enter your AWS Access Key ID, Secret Access Key, and region (us-east-2)"
        exit 1
    fi
    
    echo "✅ AWS CLI configured"
}

# Create key pair if it doesn't exist
create_key_pair() {
    echo "🔑 Setting up SSH key pair..."
    
    if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$REGION" &>/dev/null; then
        echo "✅ Key pair '$KEY_NAME' already exists"
    else
        echo "Creating new key pair..."
        aws ec2 create-key-pair \
            --key-name "$KEY_NAME" \
            --region "$REGION" \
            --query 'KeyMaterial' \
            --output text > "${KEY_NAME}.pem"
        
        chmod 400 "${KEY_NAME}.pem"
        echo "✅ Key pair created: ${KEY_NAME}.pem"
    fi
}

# Create security group
create_security_group() {
    echo "🔒 Setting up security group..."
    
    # Get default VPC ID
    VPC_ID=$(aws ec2 describe-vpcs --region "$REGION" --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text)
    
    if aws ec2 describe-security-groups --group-names "$SECURITY_GROUP_NAME" --region "$REGION" &>/dev/null; then
        echo "✅ Security group '$SECURITY_GROUP_NAME' already exists"
        SG_ID=$(aws ec2 describe-security-groups --group-names "$SECURITY_GROUP_NAME" --region "$REGION" --query 'SecurityGroups[0].GroupId' --output text)
    else
        echo "Creating security group..."
        SG_ID=$(aws ec2 create-security-group \
            --group-name "$SECURITY_GROUP_NAME" \
            --description "Security group for Quiz Platform" \
            --vpc-id "$VPC_ID" \
            --region "$REGION" \
            --query 'GroupId' \
            --output text)
        
        # Add rules
        aws ec2 authorize-security-group-ingress \
            --group-id "$SG_ID" \
            --protocol tcp \
            --port 22 \
            --cidr 0.0.0.0/0 \
            --region "$REGION"
        
        aws ec2 authorize-security-group-ingress \
            --group-id "$SG_ID" \
            --protocol tcp \
            --port 80 \
            --cidr 0.0.0.0/0 \
            --region "$REGION"
        
        aws ec2 authorize-security-group-ingress \
            --group-id "$SG_ID" \
            --protocol tcp \
            --port 443 \
            --cidr 0.0.0.0/0 \
            --region "$REGION"
        
        echo "✅ Security group created: $SG_ID"
    fi
}

# Launch EC2 instance with GitHub deployment
launch_instance() {
    echo "🚀 Launching EC2 instance with GitHub deployment..."
    
    # Get Ubuntu 22.04 AMI ID
    AMI_ID=$(aws ec2 describe-images \
        --owners 099720109477 \
        --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
        --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
        --output text \
        --region "$REGION")
    
    echo "Using AMI: $AMI_ID"
    
    # Create user data script that deploys from GitHub
    USER_DATA=$(base64 -w 0 << EOF
#!/bin/bash

# Log everything
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting Quiz Platform GitHub deployment..."

# Update system
apt-get update && apt-get upgrade -y

# Install dependencies
apt-get install -y git curl wget unzip htop ufw apt-transport-https ca-certificates gnupg lsb-release

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Set up firewall
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Clone repository and deploy
cd /home/ubuntu
git clone $GITHUB_REPO quiz-platform
cd quiz-platform

# Make scripts executable
chmod +x *.sh 2>/dev/null || true

# Set up environment
if [ -f ".env.production" ]; then
    cp .env.production .env
else
    cat > .env << 'ENVEOF'
POSTGRES_DB=quiz_platform
POSTGRES_USER=quiz_user
POSTGRES_PASSWORD=SecurePassword123!
JWT_SECRET=your-super-secure-jwt-secret-key
NODE_ENV=production
PORT=3001
ENVEOF
fi

# Generate secure passwords
DB_PASSWORD=\$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
JWT_SECRET=\$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)

# Update .env file
sed -i "s/SecurePassword123!/\$DB_PASSWORD/g" .env
sed -i "s/your-super-secure-jwt-secret-key/\$JWT_SECRET/g" .env

# Change ownership
chown -R ubuntu:ubuntu /home/ubuntu/quiz-platform

# Deploy application
docker-compose -f docker-compose.prod.yml up -d --build

# Create deployment complete indicator
touch /home/ubuntu/deployment-complete

echo "Quiz Platform deployment completed successfully!"
EOF
)
    
    # Launch instance
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --count 1 \
        --instance-type "$INSTANCE_TYPE" \
        --key-name "$KEY_NAME" \
        --security-group-ids "$SG_ID" \
        --user-data "$USER_DATA" \
        --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":20,"VolumeType":"gp3","Encrypted":true}}]' \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=quiz-platform-server}]' \
        --region "$REGION" \
        --query 'Instances[0].InstanceId' \
        --output text)
    
    echo "✅ Instance launched: $INSTANCE_ID"
    
    # Wait for instance to be running
    echo "⏳ Waiting for instance to be running..."
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$REGION"
    
    # Get public IP
    PUBLIC_IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --region "$REGION" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)
    
    echo "✅ Instance is running at: $PUBLIC_IP"
}

# Wait for deployment to complete
wait_for_deployment() {
    echo "⏳ Waiting for application deployment to complete..."
    echo "This may take 5-10 minutes for the first deployment..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "Checking deployment progress... ($attempt/$max_attempts)"
        
        if ssh -i "${KEY_NAME}.pem" -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@$PUBLIC_IP "test -f /home/ubuntu/deployment-complete" 2>/dev/null; then
            echo "✅ Deployment completed successfully!"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            echo "⚠️  Deployment is taking longer than expected."
            echo "You can check the progress by connecting to the instance:"
            echo "ssh -i ${KEY_NAME}.pem ubuntu@$PUBLIC_IP"
            echo "tail -f /var/log/user-data.log"
            break
        fi
        
        sleep 30
        ((attempt++))
    done
}

# Main deployment
main() {
    check_aws_config
    create_key_pair
    create_security_group
    launch_instance
    wait_for_deployment
    
    echo ""
    echo "🎉 GitHub to EC2 deployment completed!"
    echo "====================================="
    echo ""
    echo "📍 Instance Details:"
    echo "   Instance ID: $INSTANCE_ID"
    echo "   Public IP: $PUBLIC_IP"
    echo "   SSH Key: ${KEY_NAME}.pem"
    echo ""
    echo "🌐 Application URL: http://$PUBLIC_IP"
    echo ""
    echo "🔗 SSH Access:"
    echo "   ssh -i ${KEY_NAME}.pem ubuntu@$PUBLIC_IP"
    echo ""
    echo "📊 Monitor deployment:"
    echo "   ssh -i ${KEY_NAME}.pem ubuntu@$PUBLIC_IP"
    echo "   tail -f /var/log/user-data.log"
    echo "   sudo docker-compose -f /home/ubuntu/quiz-platform/docker-compose.prod.yml logs -f"
    echo ""
    echo "🔄 Update application:"
    echo "   ssh -i ${KEY_NAME}.pem ubuntu@$PUBLIC_IP"
    echo "   cd /home/ubuntu/quiz-platform"
    echo "   git pull"
    echo "   sudo docker-compose -f docker-compose.prod.yml up -d --build"
    echo ""
    echo "🎮 Test your Quiz Platform at: http://$PUBLIC_IP"
}

main