#!/bin/bash

# Quick AWS EC2 Deployment for Quiz Platform
# This script helps you deploy quickly using AWS CLI

set -e

echo "🚀 Quick AWS EC2 Deployment for Quiz Platform"
echo "=============================================="

# Configuration
REGION="us-east-2"
INSTANCE_TYPE="t3.medium"
KEY_NAME="quiz-platform-key"
SECURITY_GROUP_NAME="quiz-platform-sg"

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

# Launch EC2 instance
launch_instance() {
    echo "🚀 Launching EC2 instance..."
    
    # Get Ubuntu 22.04 AMI ID
    AMI_ID=$(aws ec2 describe-images \
        --owners 099720109477 \
        --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
        --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
        --output text \
        --region "$REGION")
    
    echo "Using AMI: $AMI_ID"
    
    # User data script
    USER_DATA=$(base64 -w 0 << 'EOF'
#!/bin/bash
apt-get update && apt-get upgrade -y
apt-get install -y docker.io docker-compose git curl htop
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker
touch /home/ubuntu/instance-ready
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

# Main deployment
main() {
    check_aws_config
    create_key_pair
    create_security_group
    launch_instance
    
    echo ""
    echo "🎉 AWS Infrastructure deployed successfully!"
    echo ""
    echo "📍 Instance Details:"
    echo "   Instance ID: $INSTANCE_ID"
    echo "   Public IP: $PUBLIC_IP"
    echo "   SSH Key: ${KEY_NAME}.pem"
    echo ""
    echo "🔗 Next Steps:"
    echo "1. Wait 2-3 minutes for instance initialization"
    echo "2. Connect: ssh -i ${KEY_NAME}.pem ubuntu@$PUBLIC_IP"
    echo "3. Transfer your application files"
    echo "4. Run: ./deploy-direct.sh"
    echo ""
    echo "🌐 Your app will be available at: http://$PUBLIC_IP"
}

main