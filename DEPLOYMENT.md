# Deployment Guide

This guide covers deploying the Competitive Quiz Platform to GitHub and AWS EC2.

## Prerequisites

- AWS Account with EC2 access
- GitHub account
- Local Git installation
- SSH key pair for EC2 access

## Step 1: Push to GitHub Repository

1. **Initialize Git repository (if not already done):**
   ```bash
   git init
   git add .
   git commit -m "Initial commit: Competitive Quiz Platform"
   ```

2. **Add GitHub remote:**
   ```bash
   git remote add origin https://github.com/AbedK520/KahootClone.git
   ```

3. **Push to GitHub:**
   ```bash
   git branch -M main
   git push -u origin main
   ```

## Step 2: Set Up AWS EC2 Instance

### Launch EC2 Instance

1. **Go to AWS EC2 Console**
2. **Launch Instance:**
   - **AMI:** Ubuntu Server 22.04 LTS
   - **Instance Type:** t3.medium (minimum recommended)
   - **Key Pair:** Create or select existing key pair
   - **Security Group:** Create with the following rules:
     - SSH (22) - Your IP
     - HTTP (80) - Anywhere (0.0.0.0/0)
     - HTTPS (443) - Anywhere (0.0.0.0/0)
   - **Storage:** 20 GB gp3 (minimum)

3. **Launch the instance and note the public IP**

### Connect to EC2 Instance

```bash
ssh -i your-key.pem ubuntu@your-ec2-public-ip
```

## Step 3: Deploy Application

### Option A: Automated Deployment (Recommended)

1. **Run the deployment script:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/AbedK520/KahootClone/main/deploy-aws.sh | bash
   ```

2. **Configure environment variables:**
   - Edit the `.env` file when prompted
   - Set secure passwords and secrets
   - Save and continue

### Option B: Manual Deployment

1. **Update system and install dependencies:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y docker.io docker-compose git
   sudo usermod -aG docker $USER
   ```

2. **Clone repository:**
   ```bash
   git clone https://github.com/AbedK520/KahootClone.git
   cd KahootClone
   ```

3. **Set up environment:**
   ```bash
   cp .env.production .env
   # Edit .env with your production values
   nano .env
   ```

4. **Deploy with Docker:**
   ```bash
   sudo docker-compose -f docker-compose.prod.yml up -d --build
   ```

## Step 4: Configure Environment Variables

Edit the `.env` file with your production values:

```bash
# Database Configuration
POSTGRES_DB=quiz_platform
POSTGRES_USER=quiz_user
POSTGRES_PASSWORD=your_secure_password_here

# JWT Secret (generate with: openssl rand -base64 32)
JWT_SECRET=your_jwt_secret_here

# Optional: Domain configuration
DOMAIN=your-domain.com
```

## Step 5: Verify Deployment

1. **Check service status:**
   ```bash
   sudo docker-compose -f docker-compose.prod.yml ps
   ```

2. **View logs:**
   ```bash
   sudo docker-compose -f docker-compose.prod.yml logs -f
   ```

3. **Test the application:**
   - Open browser to `http://your-ec2-public-ip`
   - Register a new account
   - Test game functionality

## Step 6: Optional - Set Up Domain and SSL

### Configure Domain (Optional)

1. **Point your domain to EC2 IP:**
   - Create A record: `your-domain.com` → `your-ec2-ip`
   - Create A record: `www.your-domain.com` → `your-ec2-ip`

2. **Install Certbot for SSL:**
   ```bash
   sudo apt install -y certbot python3-certbot-nginx
   sudo certbot --nginx -d your-domain.com -d www.your-domain.com
   ```

## Maintenance Commands

### View Application Logs
```bash
sudo docker-compose -f docker-compose.prod.yml logs -f app
```

### Restart Services
```bash
sudo docker-compose -f docker-compose.prod.yml restart
```

### Update Application
```bash
git pull origin main
sudo docker-compose -f docker-compose.prod.yml up -d --build
```

### Backup Database
```bash
sudo docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U quiz_user quiz_platform > backup.sql
```

### Restore Database
```bash
sudo docker-compose -f docker-compose.prod.yml exec -T postgres psql -U quiz_user quiz_platform < backup.sql
```

## Monitoring

### Check System Resources
```bash
# CPU and Memory usage
htop

# Disk usage
df -h

# Docker container stats
sudo docker stats
```

### Application Health
- Frontend: `http://your-server/`
- Backend API: `http://your-server/api/health`
- Database: Check logs for connection issues

## Troubleshooting

### Common Issues

1. **Port 80 already in use:**
   ```bash
   sudo lsof -i :80
   sudo systemctl stop apache2  # if Apache is running
   ```

2. **Database connection issues:**
   ```bash
   sudo docker-compose -f docker-compose.prod.yml logs postgres
   ```

3. **Frontend not loading:**
   ```bash
   sudo docker-compose -f docker-compose.prod.yml logs app
   ```

4. **WebSocket connection issues:**
   - Check security group allows traffic on port 80
   - Verify nginx configuration for WebSocket proxying

### Performance Optimization

1. **Enable gzip compression in nginx**
2. **Set up CloudFront CDN for static assets**
3. **Configure database connection pooling**
4. **Set up Redis for session management**

## Security Considerations

1. **Change default passwords**
2. **Use strong JWT secrets**
3. **Enable firewall (ufw)**
4. **Regular security updates**
5. **Monitor access logs**
6. **Use HTTPS in production**

## Scaling

For high traffic, consider:

1. **Load balancer with multiple EC2 instances**
2. **RDS for managed database**
3. **ElastiCache for Redis**
4. **CloudFront for CDN**
5. **Auto Scaling Groups**

## Support

- Check logs: `sudo docker-compose -f docker-compose.prod.yml logs`
- GitHub Issues: https://github.com/AbedK520/KahootClone/issues
- AWS Documentation: https://docs.aws.amazon.com/ec2/