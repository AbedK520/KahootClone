#!/bin/bash

# Complete AWS EC2 Deployment Script for Quiz Platform
set -e

echo "🚀 Starting AWS EC2 deployment for Quiz Platform..."

# Check prerequisites
check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI not found. Installing..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        echo "❌ Terraform not found. Installing..."
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update && sudo apt install terraform
    fi
    
    # Check SSH key
    if [ ! -f ~/.ssh/id_rsa.pub ]; then
        echo "🔑 Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    fi
    
    echo "✅ Prerequisites check completed"
}

# Deploy infrastructure
deploy_infrastructure() {
    echo "🏗️ Deploying AWS infrastructure..."
    
    cd terraform
    terraform init
    terraform plan
    terraform apply -auto-approve
    
    # Get outputs
    INSTANCE_IP=$(terraform output -raw instance_public_ip)
    SSH_COMMAND=$(terraform output -raw ssh_command)
    
    echo "✅ Infrastructure deployed successfully!"
    echo "📍 Instance IP: $INSTANCE_IP"
    
    cd ..
}

check_prerequisites
deploy_infrastructure# Wait
 for instance to be ready
wait_for_instance() {
    echo "⏳ Waiting for EC2 instance to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt/$max_attempts: Checking instance readiness..."
        
        if ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@$INSTANCE_IP "test -f /home/ubuntu/deployment-ready" 2>/dev/null; then
            echo "✅ Instance is ready!"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            echo "❌ Instance not ready after $max_attempts attempts"
            exit 1
        fi
        
        echo "Instance not ready yet, waiting 30 seconds..."
        sleep 30
        ((attempt++))
    done
}

# Create deployment package
create_package() {
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
        --exclude='*.pem' \
        --exclude='terraform/.terraform' \
        --exclude='terraform/terraform.tfstate*' \
        --exclude='dist' \
        --exclude='build' \
        -czf "$PACKAGE_NAME" .
    
    echo "✅ Package created: $PACKAGE_NAME"
}

# Transfer and deploy application
deploy_application() {
    echo "🚀 Deploying application to EC2..."
    
    # Transfer package to EC2
    echo "📤 Transferring application package..."
    scp -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no "$PACKAGE_NAME" ubuntu@$INSTANCE_IP:~/
    
    # Extract and deploy on EC2
    echo "🔧 Setting up application on EC2..."
    ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP << 'EOF'
        # Extract package
        tar -xzf quiz-platform-*.tar.gz
        
        # Make scripts executable
        chmod +x *.sh
        
        # Run deployment
        ./deploy-direct.sh
EOF
    
    echo "✅ Application deployed successfully!"
}

# Main deployment flow
main() {
    check_prerequisites
    deploy_infrastructure
    wait_for_instance
    create_package
    deploy_application
    
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "🌐 Your Quiz Platform is available at:"
    echo "   http://$INSTANCE_IP"
    echo ""
    echo "🔗 SSH Access:"
    echo "   $SSH_COMMAND"
    echo ""
    echo "📊 To monitor the application:"
    echo "   ssh -i ~/.ssh/id_rsa ubuntu@$INSTANCE_IP"
    echo "   sudo docker-compose -f docker-compose.prod.yml logs -f"
}

# Run main function
main