#!/bin/bash

set -e

echo "🚀 Starting Metronic Next.js DevContainer setup..."

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
until PGPASSWORD=nextjs_password psql -h db -U nextjs_user -d nextjs_db -c '\q' 2>/dev/null; do
  echo "   PostgreSQL is unavailable - sleeping"
  sleep 2
done
echo "✅ PostgreSQL is ready!"

# Install dependencies
if [ -f "package.json" ]; then
  echo "📦 Installing npm dependencies..."
  npm install
fi

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
  echo "🔐 Creating .env file..."
  cat > .env << 'EOF'
# Database
DATABASE_URL="postgresql://nextjs_user:nextjs_password@db:5432/nextjs_db"

# Next.js
NEXT_PUBLIC_APP_URL=http://localhost:3000
NODE_ENV=development

# Metronic Theme
NEXT_PUBLIC_THEME_MODE=light
EOF
fi

# Install Prisma if not already in dependencies
if ! grep -q "@prisma/client" package.json; then
  echo "📦 Installing Prisma..."
  npm install @prisma/client
  npm install -D prisma tsx
fi

# Initialize Prisma if schema doesn't exist
if [ ! -f "prisma/schema.prisma" ]; then
  echo "🔧 Initializing Prisma..."
  npx prisma init
  
  # Create initial schema
  cat > prisma/schema.prisma << 'EOF'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  posts     Post[]
}

model Post {
  id        String   @id @default(cuid())
  title     String
  content   String?
  published Boolean  @default(false)
  authorId  String
  author    User     @relation(fields: [authorId], references: [id])
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
EOF

  # Create seed file
  mkdir -p prisma
  cat > prisma/seed.ts << 'EOF'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
  console.log('🌱 Starting database seed...')

  const user = await prisma.user.create({
    data: {
      email: 'admin@metronic.com',
      name: 'Admin User',
      posts: {
        create: [
          {
            title: 'Welcome to Metronic',
            content: 'This is your first post in the Metronic dashboard!',
            published: true,
          },
        ],
      },
    },
    include: {
      posts: true,
    },
  })

  console.log('✅ Created user with posts:', user)
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
EOF

  # Add seed script to package.json if not present
  if ! grep -q "db:seed" package.json; then
    echo "📝 Adding database scripts to package.json..."
    npm pkg set scripts.db:generate="prisma generate"
    npm pkg set scripts.db:push="prisma db push"
    npm pkg set scripts.db:migrate="prisma migrate dev"
    npm pkg set scripts.db:seed="tsx prisma/seed.ts"
    npm pkg set scripts.db:studio="prisma studio"
  fi

  # Generate Prisma Client
  npx prisma generate
  
  # Push schema to database
  npx prisma db push
  
  # Run seed
  npm run db:seed
fi

# Create Prisma client singleton if it doesn't exist
if [ ! -f "src/lib/prisma.ts" ]; then
  mkdir -p src/lib
  cat > src/lib/prisma.ts << 'EOF'
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

export const prisma = globalForPrisma.prisma ?? new PrismaClient()

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
EOF
fi

# Create health check API route if it doesn't exist
if [ ! -f "src/app/api/health/route.ts" ]; then
  mkdir -p src/app/api/health
  cat > src/app/api/health/route.ts << 'EOF'
import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  try {
    await prisma.$queryRaw`SELECT 1`
    
    return NextResponse.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      database: 'connected'
    })
  } catch (error) {
    return NextResponse.json(
      {
        status: 'error',
        timestamp: new Date().toISOString(),
        database: 'disconnected',
        error: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 503 }
    )
  }
}
EOF
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "🌐 Your application is ready at:"
echo "   - Metronic App: http://localhost:3000"
echo "   - pgAdmin: http://localhost:5050"
echo "   - API Health: http://localhost:3000/api/health"
echo ""
echo "📊 pgAdmin credentials:"
echo "   - Email: admin@admin.com"
echo "   - Password: admin"
echo ""
echo "🗄️ Database connection (for pgAdmin):"
echo "   - Host: db"
echo "   - Port: 5432"
echo "   - Database: nextjs_db"
echo "   - Username: nextjs_user"
echo "   - Password: nextjs_password"
echo ""
echo "🚀 To start development:"
echo "   npm run dev"
echo ""
echo "📦 Database commands:"
echo "   - npm run db:studio     # Open Prisma Studio"
echo "   - npm run db:migrate    # Run migrations"
echo "   - npm run db:seed       # Seed database"
echo ""