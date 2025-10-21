#!/bin/bash

set -e

echo "🚀 Starting Next.js DevContainer setup..."

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
until PGPASSWORD=nextjs_password psql -h db -U nextjs_user -d nextjs_db -c '\q' 2>/dev/null; do
  echo "   PostgreSQL is unavailable - sleeping"
  sleep 2
done
echo "✅ PostgreSQL is ready!"

# Install dependencies if package.json exists
if [ -f "package.json" ]; then
  echo "📦 Installing npm dependencies..."
  npm install
else
  echo "📦 Initializing Next.js project..."
  
  # Create package.json
  cat > package.json << 'EOF'
{
  "name": "nextjs-skeleton",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "db:generate": "prisma generate",
    "db:push": "prisma db push",
    "db:migrate": "prisma migrate dev",
    "db:migrate:deploy": "prisma migrate deploy",
    "db:seed": "tsx prisma/seed.ts",
    "db:studio": "prisma studio"
  },
  "dependencies": {
    "@prisma/client": "^5.22.0",
    "next": "^15.0.3",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "@types/node": "^20",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "autoprefixer": "^10.4.20",
    "eslint": "^8",
    "eslint-config-next": "^15.0.3",
    "postcss": "^8",
    "prisma": "^5.22.0",
    "tailwindcss": "^3.4.1",
    "tsx": "^4.19.1",
    "typescript": "^5"
  }
}
EOF

  npm install
fi

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
  echo "📝 Creating .env file..."
  cat > .env << 'EOF'
# Database
DATABASE_URL="postgresql://nextjs_user:nextjs_password@db:5432/nextjs_db"

# Next.js
NEXT_PUBLIC_APP_URL=http://localhost:3000
NODE_ENV=development
EOF
fi

# Create .env.example if it doesn't exist
if [ ! -f ".env.example" ]; then
  cat > .env.example << 'EOF'
# Database
DATABASE_URL="postgresql://USER:PASSWORD@HOST:PORT/DATABASE"

# Next.js
NEXT_PUBLIC_APP_URL=http://localhost:3000
NODE_ENV=development
EOF
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
      email: 'user@example.com',
      name: 'Test User',
      posts: {
        create: [
          {
            title: 'First Post',
            content: 'This is my first post!',
            published: true,
          },
          {
            title: 'Draft Post',
            content: 'This is a draft post.',
            published: false,
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

  # Generate Prisma Client
  npx prisma generate
  
  # Push schema to database
  npx prisma db push
  
  # Run seed
  npm run db:seed
fi

# Create Next.js config files if they don't exist
if [ ! -f "next.config.ts" ]; then
  cat > next.config.ts << 'EOF'
import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  /* config options here */
}

export default nextConfig
EOF
fi

if [ ! -f "tsconfig.json" ]; then
  cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF
fi

# Create Tailwind config
if [ ! -f "tailwind.config.ts" ]; then
  cat > tailwind.config.ts << 'EOF'
import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
};
export default config;
EOF
fi

if [ ! -f "postcss.config.js" ]; then
  cat > postcss.config.js << 'EOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF
fi

# Create src directory structure
mkdir -p src/app/api/health
mkdir -p src/components/ui
mkdir -p src/lib
mkdir -p src/types

# Create Prisma client singleton
if [ ! -f "src/lib/prisma.ts" ]; then
  cat > src/lib/prisma.ts << 'EOF'
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

export const prisma = globalForPrisma.prisma ?? new PrismaClient()

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
EOF
fi

# Create health check API route
if [ ! -f "src/app/api/health/route.ts" ]; then
  cat > src/app/api/health/route.ts << 'EOF'
import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  try {
    // Check database connection
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

# Create root layout
if [ ! -f "src/app/layout.tsx" ]; then
  cat > src/app/layout.tsx << 'EOF'
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Next.js Skeleton",
  description: "Next.js + TypeScript + Postgres DevContainer",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
EOF
fi

# Create home page
if [ ! -f "src/app/page.tsx" ]; then
  cat > src/app/page.tsx << 'EOF'
export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <div className="text-center">
        <h1 className="text-4xl font-bold mb-4">
          🚀 Next.js Skeleton
        </h1>
        <p className="text-lg text-gray-600 mb-8">
          Next.js + TypeScript + Postgres + Prisma
        </p>
        <div className="flex gap-4 justify-center">
          <a
            href="/api/health"
            target="_blank"
            className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            Check API Health
          </a>
          <a
            href="http://localhost:5050"
            target="_blank"
            className="px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700"
          >
            Open pgAdmin
          </a>
        </div>
      </div>
    </main>
  );
}
EOF
fi

# Create globals.css
if [ ! -f "src/app/globals.css" ]; then
  cat > src/app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF
fi

# Create .gitignore
if [ ! -f ".gitignore" ]; then
  cat > .gitignore << 'EOF'
# Dependencies
node_modules
.pnp
.pnp.js

# Testing
coverage

# Next.js
.next/
out/
build
dist

# Production
.vercel

# Misc
.DS_Store
*.pem

# Debug
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Local env files
.env
.env*.local

# TypeScript
*.tsbuildinfo
next-env.d.ts

# Prisma
prisma/migrations/**/migration.sql
EOF
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📍 Your application is ready at:"
echo "   - Next.js App: http://localhost:3000"
echo "   - pgAdmin: http://localhost:5050"
echo "   - API Health: http://localhost:3000/api/health"
echo ""
echo "📊 pgAdmin credentials:"
echo "   - Email: admin@admin.com"
echo "   - Password: admin"
echo ""
echo "🗄️  Database connection (for pgAdmin):"
echo "   - Host: db"
echo "   - Port: 5432"
echo "   - Database: nextjs_db"
echo "   - Username: nextjs_user"
echo "   - Password: nextjs_password"
echo ""
echo "🚀 To start development:"
echo "   npm run dev"
echo ""
echo "📦 Useful commands:"
echo "   - npm run db:studio     # Open Prisma Studio"
echo "   - npm run db:migrate    # Run migrations"
echo "   - npm run db:seed       # Seed database"
echo ""