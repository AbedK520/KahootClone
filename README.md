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
