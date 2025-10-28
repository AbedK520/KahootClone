#!/bin/bash

# Deploy Quiz Platform from GitHub to AWS EC2
# This script pulls the latest code from GitHub and deploys it

set -e

echo "🚀 Deploying Quiz Platform from GitHub to EC2..."

# Configuration
GITHUB_REPO="https://github.com/AbedK520/KahootClone.git"
APP_DIR="/home/ubuntu/quiz-platform"
BACKUP_DIR="/home/ubuntu/backups"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Check if running on EC2
check_environment() {
    log "Checking environment..."
    
    if [ ! -f /etc/cloud/cloud.cfg ]; then
        error "This script should be run on an AWS EC2 instance"
        exit 1
    fi
    
    log "✅ Running on EC2 instance"
}

# Install dependencies
install_dependencies() {
    log "Installing system dependencies..."
    
    # Update system
    sudo apt-get update
    sudo apt-get upgrade -y
    
    # Install required packages
    sudo apt-get install -y \
        git \
        curl \
        wget \
        unzip \
        htop \
        ufw \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release
    
    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        log "Installing Docker..."
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        sudo usermod -aG docker ubuntu
        log "✅ Docker installed"
    else
        log "✅ Docker already installed"
    fi
    
    # Install Docker Compose if not present
    if ! command -v docker-compose &> /dev/null; then
        log "Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        log "✅ Docker Compose installed"
    else
        log "✅ Docker Compose already installed"
    fi
}

# Configure firewall
setup_firewall() {
    log "Configuring firewall..."
    
    sudo ufw allow 22/tcp   # SSH
    sudo ufw allow 80/tcp   # HTTP
    sudo ufw allow 443/tcp  # HTTPS
    sudo ufw --force enable
    
    log "✅ Firewall configured"
}

# Clone or update repository
setup_repository() {
    log "Setting up repository..."
    
    # Create backup directory
    sudo mkdir -p "$BACKUP_DIR"
    sudo chown ubuntu:ubuntu "$BACKUP_DIR"
    
    # Backup existing deployment if it exists
    if [ -d "$APP_DIR" ]; then
        warn "Existing deployment found, creating backup..."
        BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S)"
        sudo cp -r "$APP_DIR" "$BACKUP_DIR/$BACKUP_NAME"
        log "✅ Backup created: $BACKUP_DIR/$BACKUP_NAME"
        
        # Stop existing services
        cd "$APP_DIR"
        if [ -f "docker-compose.prod.yml" ]; then
            log "Stopping existing services..."
            sudo docker-compose -f docker-compose.prod.yml down || true
        fi
        
        # Remove old directory
        cd /home/ubuntu
        sudo rm -rf "$APP_DIR"
    fi
    
    # Clone repository
    log "Cloning repository from GitHub..."
    git clone "$GITHUB_REPO" "$APP_DIR"
    cd "$APP_DIR"
    
    # Make scripts executable
    chmod +x *.sh 2>/dev/null || true
    
    log "✅ Repository cloned successfully"
}

# Set up environment variables
setup_environment() {
    log "Setting up environment variables..."
    
    if [ ! -f ".env" ]; then
        if [ -f ".env.production" ]; then
            cp .env.production .env
        else
            # Create basic .env file
            cat > .env << 'EOF'
# Production Environment Variables
POSTGRES_DB=quiz_platform
POSTGRES_USER=quiz_user
POSTGRES_PASSWORD=SecurePassword123!
JWT_SECRET=your-super-secure-jwt-secret-key-change-this-in-production
NODE_ENV=production
PORT=3001
EOF
        fi
        
        # Generate secure passwords
        DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)
        
        # Update .env file with generated values
        sed -i "s/SecurePassword123!/$DB_PASSWORD/g" .env
        sed -i "s/your-super-secure-jwt-secret-key-change-this-in-production/$JWT_SECRET/g" .env
        
        log "✅ Environment variables configured with secure random values"
    else
        log "✅ Environment file already exists"
    fi
}

# Deploy application
deploy_application() {
    log "Deploying application..."
    
    # Build and start services
    log "Building and starting Docker containers..."
    sudo docker-compose -f docker-compose.prod.yml up -d --build
    
    # Wait for services to be ready
    log "Waiting for services to start..."
    sleep 30
    
    # Check service status
    log "Checking service status..."
    sudo docker-compose -f docker-compose.prod.yml ps
    
    log "✅ Application deployed successfully"
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Check if containers are running
    if sudo docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
        log "✅ Containers are running"
    else
        error "Some containers are not running"
        sudo docker-compose -f docker-compose.prod.yml logs
        exit 1
    fi
    
    # Test database connection
    log "Testing database connection..."
    for i in {1..10}; do
        if sudo docker-compose -f docker-compose.prod.yml exec -T postgres pg_isready -U quiz_user -d quiz_platform; then
            log "✅ Database is ready"
            break
        else
            if [ $i -eq 10 ]; then
                error "Database connection failed after 10 attempts"
                exit 1
            fi
            log "Waiting for database... ($i/10)"
            sleep 5
        fi
    done
    
    # Get public IP
    PUBLIC_IP=$(curl -s http://checkip.amazonaws.com || echo "Unable to get public IP")
    
    log "✅ Deployment verification completed"
}

# Display deployment information
show_deployment_info() {
    echo ""
    echo "🎉 Quiz Platform deployed successfully!"
    echo "======================================"
    echo ""
    echo "🌐 Application URL: http://$PUBLIC_IP"
    echo "📁 Application Directory: $APP_DIR"
    echo "💾 Backup Directory: $BACKUP_DIR"
    echo ""
    echo "📊 Useful Commands:"
    echo "  View logs:     sudo docker-compose -f docker-compose.prod.yml logs -f"
    echo "  Restart app:   sudo docker-compose -f docker-compose.prod.yml restart"
    echo "  Stop app:      sudo docker-compose -f docker-compose.prod.yml down"
    echo "  Update app:    cd $APP_DIR && git pull && sudo docker-compose -f docker-compose.prod.yml up -d --build"
    echo ""
    echo "🔧 Environment file: $APP_DIR/.env"
    echo ""
    echo "🎮 Test your application:"
    echo "1. Open http://$PUBLIC_IP in your browser"
    echo "2. Register a new account"
    echo "3. Create or join a quiz game"
    echo ""
}

# Main deployment function
main() {
    log "Starting GitHub-based deployment..."
    
    check_environment
    install_dependencies
    setup_firewall
    setup_repository
    setup_environment
    deploy_application
    verify_deployment
    show_deployment_info
    
    log "🎉 Deployment completed successfully!"
}

# Run main function
main "$@"