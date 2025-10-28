#!/bin/bash

echo "🔄 Redeploying backend with SQLite fixes..."

EC2_IP="3.15.195.165"
KEY_FILE="quiz-platform-key.pem"

# Create new deployment package
tar -czf quiz-backend-fixed.tar.gz backend/ --exclude=node_modules --exclude=.env --exclude=prisma/migrations

# Copy to EC2
scp -i $KEY_FILE -o StrictHostKeyChecking=no quiz-backend-fixed.tar.gz ec2-user@$EC2_IP:/home/ec2-user/

# Redeploy
ssh -i $KEY_FILE -o StrictHostKeyChecking=no ec2-user@$EC2_IP << 'EOF'
# Stop existing process
pm2 stop quiz-backend || true
pm2 delete quiz-backend || true

# Remove old backend
rm -rf backend

# Extract new version
tar -xzf quiz-backend-fixed.tar.gz
cd backend

# Install dependencies
npm install

# Copy production environment
cp .env.production .env

# Reset Prisma for SQLite
rm -rf prisma/migrations
npx prisma migrate dev --name init --skip-seed

# Generate client
npx prisma generate

# Build
npm run build

# Create simple seed for SQLite
cat > simple-seed.js << 'SEED_EOF'
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  // Create sample questions
  await prisma.question.createMany({
    data: [
      {
        text: "What is the capital of France?",
        type: "MULTIPLE_CHOICE",
        category: "Geography",
        difficulty: "EASY",
        options: JSON.stringify(["London", "Berlin", "Paris", "Madrid"]),
        correctAnswer: "Paris",
        pointValue: 10
      },
      {
        text: "What is 2 + 2?",
        type: "MULTIPLE_CHOICE", 
        category: "Math",
        difficulty: "EASY",
        options: JSON.stringify(["3", "4", "5", "6"]),
        correctAnswer: "4",
        pointValue: 10
      },
      {
        text: "Is the Earth round?",
        type: "TRUE_FALSE",
        category: "Science", 
        difficulty: "EASY",
        options: JSON.stringify(["True", "False"]),
        correctAnswer: "True",
        pointValue: 10
      }
    ]
  });
  
  console.log('✅ Sample questions created');
}

main().catch(console.error).finally(() => prisma.$disconnect());
SEED_EOF

# Run simple seed
node simple-seed.js

# Start with PM2
pm2 start dist/server.js --name "quiz-backend"

echo "✅ Backend redeployed successfully!"
EOF

echo "🎉 Redeployment complete!"