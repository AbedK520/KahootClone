# AWS Console Deployment Guide

Deploy your Quiz Platform to AWS EC2 using the AWS Console in us-east-2.

## Step 1: Launch EC2 Instance

### 1.1 Go to AWS Console
- Navigate to **EC2 Dashboard** in **us-east-2** (Ohio) region
- Click **Launch Instance**

### 1.2 Configure Instance
**Name:** `quiz-platform-server`

**Application and OS Images:**
- **AMI:** Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
- **Architecture:** 64-bit (x86)

**Instance Type:**
- **Type:** t3.medium (2 vCPU, 4 GiB Memory)

**Key Pair:**
- Create new key pair: `quiz-platform-key`
- **Type:** RSA
- **Format:** .pem
- Download and save the key file

**Network Settings:**
- **VPC:** Default VPC (or create new)
- **Subnet:** Public subnet with auto-assign public IP
- **Security Group:** Create new with these rules:
  ```
  SSH (22)    - Source: My IP (your current IP)
  HTTP (80)   - Source: Anywhere (0.0.0.0/0)
  HTTPS (443) - Source: Anywhere (0.0.0.0/0)
  ```

**Storage:**
- **Size:** 20 GiB
- **Volume Type:** gp3
- **Encryption:** Enabled

### 1.3 Advanced Details (Optional)
**User Data Script:** (Paste this in the User Data field)
```bash
#!/bin/bash
apt-get update && apt-get upgrade -y
apt-get install -y docker.io docker-compose git curl
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker
```

### 1.4 Launch Instance
- Review settings and click **Launch Instance**
- Note the **Instance ID** and **Public IP**

## Step 2: Connect to Instance

### 2.1 Set Key Permissions
```bash
chmod 400 ~/Downloads/quiz-platform-key.pem
```

### 2.2 Connect via SSH
```bash
ssh -i ~/Downloads/quiz-platform-key.pem ubuntu@YOUR_INSTANCE_PUBLIC_IP
```

## Step 3: Deploy Application

### 3.1 Transfer Application Files

**Option A: Direct Upload (if you have the package)**
```bash
# From your local machine
scp -i ~/Downloads/quiz-platform-key.pem quiz-platform-*.tar.gz ubuntu@YOUR_INSTANCE_IP:~/
```

**Option B: Clone from GitHub (if available)**
```bash
# On EC2 instance
git clone https://github.com/AbedK520/KahootClone.git
cd KahootClone
```

**Option C: Manual File Creation**
Create the necessary files manually on the EC2 instance (see file contents below).

### 3.2 Install Dependencies (if not done via User Data)
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install -y docker.io docker-compose git curl
sudo usermod -aG docker ubuntu
sudo systemctl enable docker
sudo systemctl start docker

# Logout and login again for docker group to take effect
exit
# SSH back in
ssh -i ~/Downloads/quiz-platform-key.pem ubuntu@YOUR_INSTANCE_IP
```

### 3.3 Set Up Application
```bash
# If you uploaded a package
tar -xzf quiz-platform-*.tar.gz

# Make scripts executable
chmod +x *.sh

# Run deployment
./deploy-direct.sh
```

## Step 4: Verify Deployment

### 4.1 Check Services
```bash
sudo docker-compose -f docker-compose.prod.yml ps
```

### 4.2 View Logs
```bash
sudo docker-compose -f docker-compose.prod.yml logs -f
```

### 4.3 Test Application
- Open browser to: `http://YOUR_INSTANCE_PUBLIC_IP`
- Register a new account
- Test game functionality

## Step 5: Optional - Set Up Domain

### 5.1 Configure Route 53 (if you have a domain)
1. Go to **Route 53** in AWS Console
2. Create **Hosted Zone** for your domain
3. Create **A Record** pointing to your EC2 public IP

### 5.2 Set Up SSL Certificate
```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get certificate (replace with your domain)
sudo certbot --nginx -d yourdomain.com
```

## Troubleshooting

### Common Issues:

1. **Can't connect via SSH:**
   - Check security group allows SSH from your IP
   - Verify key file permissions: `chmod 400 key.pem`
   - Check instance is in running state

2. **Application not accessible:**
   - Verify security group allows HTTP (80) from anywhere
   - Check if services are running: `sudo docker ps`
   - Review logs: `sudo docker-compose logs`

3. **Docker permission denied:**
   - Add user to docker group: `sudo usermod -aG docker ubuntu`
   - Logout and login again

4. **Out of memory:**
   - Use t3.medium or larger instance
   - Monitor with: `htop` or `free -h`

### Useful Commands:

```bash
# Check system resources
htop
df -h
free -h

# Docker commands
sudo docker ps
sudo docker-compose -f docker-compose.prod.yml logs -f
sudo docker-compose -f docker-compose.prod.yml restart

# System logs
sudo journalctl -u docker
tail -f /var/log/syslog
```

## Security Best Practices

1. **Restrict SSH access** to your IP only
2. **Use strong passwords** in .env file
3. **Enable automatic security updates:**
   ```bash
   sudo apt install unattended-upgrades
   sudo dpkg-reconfigure -plow unattended-upgrades
   ```
4. **Set up CloudWatch monitoring**
5. **Regular backups** of database

## Cost Optimization

- **Stop instance** when not in use
- **Use Spot Instances** for development
- **Set up billing alerts**
- **Monitor usage** with AWS Cost Explorer

Your Quiz Platform will be accessible at `http://YOUR_INSTANCE_PUBLIC_IP` once deployment is complete!