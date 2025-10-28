#!/bin/bash

# Prepare project for GitHub upload
echo "📦 Preparing Quiz Platform for GitHub upload..."

# Create a clean directory for GitHub upload
GITHUB_DIR="quiz-platform-github"
rm -rf "$GITHUB_DIR"
mkdir "$GITHUB_DIR"

echo "📁 Creating clean project structure..."

# Copy all necessary files, excluding development artifacts
rsync -av --progress \
    --exclude='node_modules' \
    --exclude='.git' \
    --exclude='*.log' \
    --exclude='logs' \
    --exclude='.DS_Store' \
    --exclude='*.tar.gz' \
    --exclude='*.pem' \
    --exclude='dist' \
    --exclude='build' \
    --exclude='terraform/.terraform' \
    --exclude='terraform/terraform.tfstate*' \
    --exclude='.env' \
    ./ "$GITHUB_DIR/"

# Create a comprehensive README for GitHub
cat > "$GITHUB_DIR/README.md" << 'EOF'
# 🎮 Competitive Quiz Platform (Kahoot Clone)

A real-time multiplayer trivia platform that brings the excitement of game shows to digital competition. Built with React, Node.js, PostgreSQL, and Socket.io.

![Quiz Platform](https://img.shields.io/badge/Status-Production%20Ready-green)
![License](https://img.shields.io/badge/License-MIT-blue)
![Node](https://img.shields.io/badge/Node.js-18+-green)
![React](https://img.shields.io/badge/React-18-blue)

## 🚀 Quick Deploy to AWS EC2

Deploy this application to AWS EC2 in us-east-2 with one command:

```bash
curl -fsSL https://raw.githubusercontent.com/AbedK520/KahootClone/main/deploy-github-to-ec2.sh | bash
```

Or manually:
```bash
git clone https://github.com/AbedK520/KahootClone.git
cd KahootClone
./deploy-from-github.sh
```

## ✨ Features

- 🎮 **Real-time Multiplayer**: Live competition with WebSocket communication
- 👥 **Team Battles**: Create teams and compete collaboratively  
- 🏆 **Multiple Game Modes**: Quick match, tournaments, practice mode
- 📊 **Dynamic Scoring**: Points based on accuracy, speed, and difficulty
- 📱 **Responsive Design**: Works on desktop, tablet, and mobile
- 🎯 **50+ Questions**: Diverse categories and difficulty levels
- 🔐 **User Authentication**: Secure JWT-based authentication
- 📈 **Real-time Leaderboards**: Live score tracking and rankings
- 🎨 **Modern UI**: Clean, intuitive interface with smooth animations

## 🛠️ Tech Stack

### Frontend
- **React 18** with TypeScript
- **Vite** for fast development and building
- **Tailwind CSS** for styling
- **Socket.io Client** for real-time communication
- **React Router** for navigation
- **Axios** for API calls

### Backend
- **Node.js** with Express
- **TypeScript** for type safety
- **Socket.io** for WebSocket connections
- **Prisma ORM** with PostgreSQL
- **Redis** for session management
- **JWT** authentication
- **bcrypt** for password hashing

### Infrastructure
- **Docker** containerization
- **Nginx** reverse proxy
- **PostgreSQL** database
- **Redis** caching
- **AWS EC2** deployment ready

## 🚀 Deployment Options

### 1. AWS EC2 (Recommended)
```bash
# Automated deployment
./deploy-github-to-ec2.sh

# Manual deployment
./deploy-from-github.sh
```

### 2. Docker Compose
```bash
# Development
docker-compose up -d

# Production
docker-compose -f docker-compose.prod.yml up -d
```

### 3. Local Development
```bash
# Install dependencies
npm run install:all

# Start development servers
npm run dev
```

## 📋 Prerequisites

- **Node.js 18+**
- **Docker & Docker Compose**
- **Git**
- **AWS CLI** (for AWS deployment)

## 🎮 Game Modes

1. **Quick Match**: Instant matchmaking for solo or multiplayer games
2. **Team Battle**: Team-based competitions with collective scoring
3. **Tournament**: Elimination bracket competitions  
4. **Practice**: Individual skill development without pressure

## 📊 Scoring System

- **Base Points**: Determined by question difficulty (Easy: 100, Medium: 200, Hard: 300)
- **Speed Bonus**: Up to 50% bonus for quick answers
- **Accuracy Bonus**: Streak bonuses for consecutive correct answers
- **Team Scoring**: Aggregated individual scores with team bonuses

## 🔧 Configuration

### Environment Variables
```bash
# Copy and edit environment file
cp .env.production .env
nano .env
```

Key variables:
- `POSTGRES_PASSWORD`: Database password
- `JWT_SECRET`: JWT signing secret
- `NODE_ENV`: Environment (production/development)

## 📚 API Documentation

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh` - Refresh JWT token

### Games
- `POST /api/games` - Create game session
- `GET /api/games/:id` - Get game details
- `POST /api/games/:id/join` - Join game

### WebSocket Events
- `join-game` - Join game room
- `start-game` - Start game session
- `question-presented` - New question broadcast
- `answer-submitted` - Submit answer
- `game-complete` - Game finished

## 🔄 Updates

To update your deployed application:
```bash
cd /path/to/quiz-platform
git pull origin main
sudo docker-compose -f docker-compose.prod.yml up -d --build
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/AbedK520/KahootClone/issues)
- **Documentation**: Check the `/docs` folder
- **Deployment Guide**: See `GITHUB_UPLOAD_GUIDE.md`

## 🎯 Demo

Try the live demo: [Your deployed URL here]

---

**Built with ❤️ for competitive learning and fun!**
EOF

# Create a simple LICENSE file
cat > "$GITHUB_DIR/LICENSE" << 'EOF'
MIT License

Copyright (c) 2024 Quiz Platform

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# Create .gitignore for the GitHub repository
cat > "$GITHUB_DIR/.gitignore" << 'EOF'
# Dependencies
node_modules/
*/node_modules/

# Production builds
dist/
build/
*/dist/
*/build/

# Environment variables
.env
.env.local
.env.production.local
.env.development.local

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Runtime data
pids/
*.pid
*.seed
*.pid.lock

# Coverage directory
coverage/
.nyc_output/

# Dependency directories
jspm_packages/

# Optional npm cache directory
.npm

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# dotenv environment variables file
.env.test

# parcel-bundler cache
.cache
.parcel-cache

# next.js build output
.next

# nuxt.js build output
.nuxt

# vuepress build output
.vuepress/dist

# Serverless directories
.serverless

# FuseBox cache
.fusebox/

# DynamoDB Local files
.dynamodb/

# TernJS port file
.tern-port

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# Database
*.sqlite
*.db

# Backup files
*.backup
*.bak

# Temporary files
tmp/
temp/

# AWS
.aws/

# Terraform
*.tfstate
*.tfstate.*
.terraform/

# Keys and certificates
*.pem
*.key
*.crt
*.p12
*.pfx

# Compressed files
*.tar.gz
*.zip
*.rar
EOF

# Create a ZIP file for easy upload
cd "$GITHUB_DIR"
zip -r "../quiz-platform-github-upload.zip" . -x "*.DS_Store" "*.git*"
cd ..

echo ""
echo "✅ GitHub upload package prepared!"
echo ""
echo "📁 Files prepared in: $GITHUB_DIR/"
echo "📦 ZIP package created: quiz-platform-github-upload.zip"
echo ""
echo "🚀 Next steps:"
echo "1. Go to https://github.com/AbedK520/KahootClone"
echo "2. Create new repository (if not exists)"
echo "3. Upload files from '$GITHUB_DIR/' directory"
echo "   OR"
echo "   Upload the ZIP file: quiz-platform-github-upload.zip"
echo ""
echo "4. After upload, deploy to EC2:"
echo "   curl -fsSL https://raw.githubusercontent.com/AbedK520/KahootClone/main/deploy-github-to-ec2.sh | bash"
echo ""
echo "📋 Repository structure:"
find "$GITHUB_DIR" -type f | head -20
echo "   ... and more files"