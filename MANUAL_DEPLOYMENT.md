# Manual Deployment Guide

Since GitHub push is blocked by Code Defender, here's how to deploy your Quiz Platform directly to AWS EC2.

## Option 1: Direct File Transfer to EC2

### Step 1: Launch EC2 Instance

1. **Go to AWS EC2 Console (us-east-2 region)**
2. **Launch Instance:**
   - **AMI:** Ubuntu Server 22.04 LTS (ami-0ea3c35c5c3284d82)
   - **Instance Type:** t3.medium (2 vCPU, 4 GB RAM)
   - **Key Pair:** Create new or use existing
   - **Security Group:** Create with rules:
     ```
     SSH (22) - Your IP only
     HTTP (80) - Anywhere (0.0.0.0/0)
     HTTPS (443) - Anywhere (0.0.0.0/0)
     ```
   - **Storage:** 20 GB gp3

### Step 2: Transfer Files to EC2

**Option A: Using SCP (Recommended)**
```bash
# Create a tar archive of your project (excluding node_modules)
tar --exclude='node_modules' --exclude='.git' --exclude='*.log' -czf quiz-platform.tar.gz .

# Transfer to EC2
scp -i your-key.pem quiz-platform.tar.gz ubuntu@your-ec2-ip:~/

# Connect to EC2 and extract
ssh -i your-key.pem ubuntu@your-ec2-ip
tar -xzf quiz-platform.tar.gz
```

**Option B: Using rsync**
```bash
# Sync files to EC2 (excluding unnecessary files)
rsync -avz --exclude='node_modules' --exclude='.git' --exclude='*.log' \
  -e "ssh -i your-key.pem" \
  ./ ubuntu@your-ec2-ip:~/quiz-platform/
```

### Step 3: Deploy on EC2

```bash
# Connect to your EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# Navigate to project directory
cd quiz-platform  # or wherever you extracted the files

# Run the deployment script
chmod +x deploy-direct.sh
./deploy-direct.sh
```

## Option 2: Manual Setup on EC2

If you prefer to set up everything manually:

### Step 1: Connect to EC2 and Install Dependencies

```bash
ssh -i your-key.pem ubuntu@your-ec2-ip

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add user to docker group
sudo usermod -aG docker $USER
```

### Step 2: Create Project Structure

```bash
# Create project directory
mkdir -p ~/quiz-platform
cd ~/quiz-platform

# You'll need to manually create or transfer all the project files
# This includes all the files from your local project
```

### Step 3: Configure Environment

```bash
# Create environment file
cat > .env << 'EOF'
POSTGRES_DB=quiz_platform
POSTGRES_USER=quiz_user
POSTGRES_PASSWORD=SecurePassword123!
JWT_SECRET=your-super-secure-jwt-secret-key-here
AWS_REGION=us-east-2
EOF
```

### Step 4: Deploy Application

```bash
# Start the application
sudo docker-compose -f docker-compose.prod.yml up -d --build

# Check status
sudo docker-compose -f docker-compose.prod.yml ps

# View logs
sudo docker-compose -f docker-compose.prod.yml logs -f
```

## Option 3: Create GitHub Repository Manually

Since the automated push is blocked, you can:

1. **Go to GitHub.com**
2. **Create new repository:** `KahootClone`
3. **Upload files manually through GitHub web interface:**
   - Create a zip file of your project
   - Use GitHub's "Upload files" feature
   - Or use GitHub Desktop if available

4. **Then use the original deployment script:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/AbedK520/KahootClone/main/deploy-aws.sh | bash
   ```

## Quick Start Commands

Once your EC2 instance is ready and files are transferred:

```bash
# Make scripts executable
chmod +x *.sh

# Run deployment
./deploy-direct.sh

# Check application status
sudo docker-compose -f docker-compose.prod.yml ps

# View logs
sudo docker-compose -f docker-compose.prod.yml logs -f app

# Get your public IP
curl http://checkip.amazonaws.com
```

## Testing Your Deployment

1. **Open browser to:** `http://your-ec2-public-ip`
2. **Register a new account**
3. **Test game functionality:**
   - Create a game
   - Join a game
   - Answer questions
   - Check leaderboard

## Troubleshooting

### Common Issues:

1. **Can't connect to EC2:**
   - Check security group allows SSH (port 22) from your IP
   - Verify key pair permissions: `chmod 400 your-key.pem`

2. **Application not accessible:**
   - Check security group allows HTTP (port 80) from anywhere
   - Verify services are running: `sudo docker ps`

3. **Database connection errors:**
   - Check logs: `sudo docker-compose -f docker-compose.prod.yml logs postgres`
   - Verify environment variables in `.env`

4. **Out of memory:**
   - Use t3.medium or larger instance type
   - Monitor with: `htop` or `free -h`

### Useful Commands:

```bash
# Restart all services
sudo docker-compose -f docker-compose.prod.yml restart

# Stop all services
sudo docker-compose -f docker-compose.prod.yml down

# Update application (after file changes)
sudo docker-compose -f docker-compose.prod.yml up -d --build

# Backup database
sudo docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U quiz_user quiz_platform > backup.sql

# View system resources
htop
df -h
sudo docker stats
```

## Security Notes

1. **Change default passwords** in `.env` file
2. **Use strong JWT secrets**
3. **Restrict SSH access** to your IP only
4. **Enable firewall:** `sudo ufw enable`
5. **Regular updates:** `sudo apt update && sudo apt upgrade`

## Next Steps

After successful deployment:

1. **Set up domain name** (optional)
2. **Configure SSL certificate** with Let's Encrypt
3. **Set up monitoring** and alerts
4. **Configure backups**
5. **Set up CI/CD pipeline** when GitHub access is available

Your Quiz Platform should now be running at `http://your-ec2-public-ip`!