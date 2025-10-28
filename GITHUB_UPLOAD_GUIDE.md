# GitHub Upload and EC2 Deployment Guide

Since automated GitHub push is blocked by Code Defender, here's how to manually upload your code and deploy from GitHub.

## Step 1: Manual GitHub Upload

### Option A: GitHub Web Interface (Recommended)

1. **Go to GitHub.com and sign in**
2. **Create new repository:**
   - Repository name: `KahootClone`
   - Description: `Competitive Quiz Platform - Real-time multiplayer trivia game`
   - Set to Public
   - Don't initialize with README (we have our own)

3. **Upload files via web interface:**
   - Click "uploading an existing file"
   - Drag and drop all project files OR
   - Create a ZIP file and upload it

### Option B: GitHub Desktop (If Available)

1. **Install GitHub Desktop**
2. **Clone the empty repository**
3. **Copy all project files to the cloned folder**
4. **Commit and push through GitHub Desktop**

### Option C: Request Code Defender Approval

Run this command to request approval for personal project:
```bash
git-defender --request-repo --url https://github.com/AbedK520/KahootClone.git --reason 3
```

Then wait for approval and use:
```bash
git push -u origin main
```

## Step 2: Verify GitHub Repository

After upload, your repository should contain:

```
KahootClone/
├── README.md
├── package.json
├── docker-compose.yml
├── docker-compose.prod.yml
├── Dockerfile
├── nginx.conf
├── .env.production
├── deploy-from-github.sh
├── deploy-github-to-ec2.sh
├── frontend/
│   ├── package.json
│   ├── src/
│   └── ...
├── backend/
│   ├── package.json
│   ├── src/
│   ├── prisma/
│   └── ...
└── terraform/
    └── ...
```

## Step 3: Deploy to EC2 from GitHub

### Option A: Automated EC2 + GitHub Deployment

Run this script locally (requires AWS CLI configured):
```bash
./deploy-github-to-ec2.sh
```

This will:
- Create EC2 instance in us-east-2
- Automatically clone from GitHub
- Deploy the application
- Provide you with the public IP

### Option B: Manual EC2 Setup + GitHub Clone

1. **Launch EC2 Instance manually:**
   - Ubuntu 22.04 LTS
   - t3.medium instance type
   - Security group: SSH (22), HTTP (80), HTTPS (443)
   - 20GB storage

2. **Connect to EC2:**
   ```bash
   ssh -i your-key.pem ubuntu@your-ec2-ip
   ```

3. **Run GitHub deployment script:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/AbedK520/KahootClone/main/deploy-from-github.sh | bash
   ```

### Option C: Step-by-Step Manual Deployment

1. **Connect to EC2 instance**
2. **Clone repository:**
   ```bash
   git clone https://github.com/AbedK520/KahootClone.git
   cd KahootClone
   ```

3. **Install dependencies:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y docker.io docker-compose git
   sudo usermod -aG docker ubuntu
   ```

4. **Set up environment:**
   ```bash
   cp .env.production .env
   # Edit .env with secure passwords
   nano .env
   ```

5. **Deploy application:**
   ```bash
   sudo docker-compose -f docker-compose.prod.yml up -d --build
   ```

## Step 4: Update Application from GitHub

Once deployed, you can easily update your application:

```bash
# SSH to your EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# Navigate to application directory
cd /home/ubuntu/quiz-platform

# Pull latest changes
git pull origin main

# Rebuild and restart
sudo docker-compose -f docker-compose.prod.yml up -d --build
```

## Step 5: Continuous Deployment (Optional)

### GitHub Actions Workflow

Create `.github/workflows/deploy.yml` in your repository:

```yaml
name: Deploy to EC2

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Deploy to EC2
      uses: appleboy/ssh-action@v0.1.5
      with:
        host: ${{ secrets.EC2_HOST }}
        username: ubuntu
        key: ${{ secrets.EC2_SSH_KEY }}
        script: |
          cd /home/ubuntu/quiz-platform
          git pull origin main
          sudo docker-compose -f docker-compose.prod.yml up -d --build
```

Add these secrets to your GitHub repository:
- `EC2_HOST`: Your EC2 public IP
- `EC2_SSH_KEY`: Your private SSH key content

## Troubleshooting

### GitHub Upload Issues:
- **Large files:** Use Git LFS for files > 100MB
- **File limits:** GitHub has a 100MB file limit
- **Repository size:** Keep under 1GB for best performance

### Deployment Issues:
- **Permission denied:** Check SSH key permissions (`chmod 400 key.pem`)
- **Connection timeout:** Verify security group allows SSH from your IP
- **Docker errors:** Ensure user is in docker group and logout/login

### Application Issues:
- **Port 80 in use:** Check if Apache/Nginx is running (`sudo systemctl stop apache2`)
- **Database connection:** Verify environment variables in `.env`
- **Memory issues:** Use t3.medium or larger instance type

## Benefits of GitHub-based Deployment

1. **Version Control:** Track all changes and rollback if needed
2. **Easy Updates:** Simple `git pull` to update application
3. **Collaboration:** Multiple developers can contribute
4. **Backup:** Code is safely stored on GitHub
5. **CI/CD Ready:** Easy to set up automated deployments
6. **Documentation:** README and guides are version controlled

## Security Best Practices

1. **Never commit sensitive data:**
   - Add `.env` to `.gitignore`
   - Use `.env.example` for templates
   - Store secrets in GitHub Secrets for CI/CD

2. **Use SSH keys for GitHub:**
   - Generate SSH key: `ssh-keygen -t ed25519 -C "your-email@example.com"`
   - Add to GitHub: Settings > SSH and GPG keys

3. **Secure EC2 access:**
   - Restrict SSH to your IP only
   - Use strong passwords in `.env`
   - Enable automatic security updates

Your Quiz Platform will be deployed from GitHub and easily maintainable with version control!