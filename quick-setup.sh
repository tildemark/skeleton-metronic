#!/bin/bash

set -e

echo "🚀 Setting up DevContainer for Metronic Next.js..."

# Create .devcontainer directory
mkdir -p .devcontainer

# Create devcontainer.json
cat > .devcontainer/devcontainer.json << 'EOF'
{
    "name": "Metronic Next.js + Postgres",
    "dockerComposeFile": "docker-compose.yml",
    "service": "app",
    "workspaceFolder": "/workspace",
    "customizations": {
        "vscode": {
            "extensions": [
                "dbaeumer.vscode-eslint",
                "esbenp.prettier-vscode",
                "bradlc.vscode-tailwindcss",
                "Prisma.prisma",
                "mtxr.sqltools",
                "mtxr.sqltools-driver-pg"
            ],
            "settings": {
                "editor.formatOnSave": true,
                "editor.defaultFormatter": "esbenp.prettier-vscode",
                "editor.codeActionsOnSave": {
                    "source.fixAll.eslint": "explicit"
                },
                "files.eol": "\n"
            }
        }
    },
    "postCreateCommand": "dos2unix .devcontainer/setup.sh && bash .devcontainer/setup.sh",
    "forwardPorts": [3000, 5050, 5432],
    "portsAttributes": {
        "3000": {
            "label": "Next.js App",
            "onAutoForward": "notify"
        },
        "5050": {
            "label": "pgAdmin",
            "onAutoForward": "silent"
        },
        "5432": {
            "label": "PostgreSQL",
            "onAutoForward": "silent"
        }
    }
}
EOF

# Create docker-compose.yml
cat > .devcontainer/docker-compose.yml << 'EOF'
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - ..:/workspace:cached
    command: sleep infinity
    networks:
      - nextjs_network
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://nextjs_user:nextjs_password@db:5432/nextjs_db
      - NODE_ENV=development
    depends_on:
      - db

  db:
    image: postgres:16-alpine
    restart: unless-stopped
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - nextjs_network
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: nextjs_user
      POSTGRES_PASSWORD: nextjs_password
      POSTGRES_DB: nextjs_db

  pgadmin:
    image: dpage/pgadmin4:latest
    restart: unless-stopped
    networks:
      - nextjs_network
    ports:
      - "5050:80"
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@admin.com
      PGADMIN_DEFAULT_PASSWORD: admin
      PGADMIN_CONFIG_SERVER_MODE: 'False'
    volumes:
      - pgadmin-data:/var/lib/pgadmin

networks:
  nextjs_network:
    driver: bridge

volumes:
  postgres-data:
  pgadmin-data:
EOF

# Create Dockerfile
cat > .devcontainer/Dockerfile << 'EOF'
FROM node:20-bullseye

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    postgresql-client \
    dos2unix \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Install global npm packages
RUN npm install -g npm@latest pnpm

# Expose ports
EXPOSE 3000

# Keep container running
CMD ["sleep", "infinity"]
EOF

# Create setup.sh
cat > .devcontainer/setup.sh << 'EOF'
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
  cat > .env << 'ENVEOF'
# Database
DATABASE_URL="postgresql://nextjs_user:nextjs_password@db:5432/nextjs_db"

# Next.js
NEXT_PUBLIC_APP_URL=http://localhost:3000
NODE_ENV=development

# Metronic Theme
NEXT_PUBLIC_THEME_MODE=light
ENVEOF
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
  cat > prisma/schema.prisma << 'PRISMAEOF'
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
PRISMAEOF

  # Create seed file
  mkdir -p prisma
  cat > prisma/seed.ts << 'SEEDEOF'
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
SEEDEOF

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
# Try src/lib first, fallback to lib
if [ -d "src" ]; then
  LIB_DIR="src/lib"
else
  LIB_DIR="lib"
fi

if [ ! -f "$LIB_DIR/prisma.ts" ]; then
  mkdir -p "$LIB_DIR"
  cat > "$LIB_DIR/prisma.ts" << 'LIBEOF'
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

export const prisma = globalForPrisma.prisma ?? new PrismaClient()

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
LIBEOF
fi

# Create health check API route if it doesn't exist
# Try src/app first (standard Next.js), fallback to app
if [ -d "src/app" ]; then
  API_DIR="src/app/api/health"
elif [ -d "app" ]; then
  API_DIR="app/api/health"
else
  # Create src/app structure if neither exists
  API_DIR="src/app/api/health"
fi

if [ ! -f "$API_DIR/route.ts" ]; then
  mkdir -p "$API_DIR"
  cat > "$API_DIR/route.ts" << 'ROUTEEOF'
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
ROUTEEOF
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
EOF

# Create .gitattributes
cat > .gitattributes << 'EOF'
# Set default behavior to automatically normalize line endings
* text=auto

# Force bash scripts to always use LF
*.sh text eol=lf

# Force batch scripts to always use CRLF  
*.bat text eol=crlf
*.cmd text eol=crlf

# Binary files
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.pdf binary
EOF

# Update .gitignore to include Prisma
if [ -f ".gitignore" ]; then
  if ! grep -q "prisma/migrations" .gitignore; then
    echo "" >> .gitignore
    echo "# Prisma" >> .gitignore
    echo "prisma/migrations/**/migration.sql" >> .gitignore
  fi
fi

# Create .env.example if it doesn't exist
if [ ! -f ".env.example" ]; then
  cat > .env.example << 'EOF'
# Database
DATABASE_URL="postgresql://USER:PASSWORD@HOST:PORT/DATABASE"

# Next.js
NEXT_PUBLIC_APP_URL=http://localhost:3000
NODE_ENV=development

# Metronic Theme
NEXT_PUBLIC_THEME_MODE=light
EOF
fi

# Create README.md (backup existing if present)
if [ -f "README.md" ]; then
  mv README.md README.metronic.backup.md
  echo "📄 Backed up existing README.md to README.metronic.backup.md"
fi

echo "📝 Creating README.md..."
curl -s https://raw.githubusercontent.com/tildemark/skeleton-metronic/main/README.md > README.md 2>/dev/null || cat > README.md << 'READMEEOF'
# Skeleton Metronic

A production-ready Next.js starter template with Metronic theme, PostgreSQL database, and DevContainer support.

## 🚀 Quick Start

1. Open in VS Code
2. Press `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"
3. Wait for setup to complete
4. Run `npm run dev`
5. Open http://localhost:3000

## 📦 What's Included

- Next.js 15 + TypeScript
- Metronic Premium Theme
- PostgreSQL Database
- Prisma ORM
- DevContainer Setup
- pgAdmin Database UI

## 🔧 Configuration

See `.env` file for configuration options.

Database accessible at:
- Host: `db` (in container) or `localhost` (host)
- Port: 5432
- Database: `nextjs_db`
- User: `nextjs_user`
- Password: `nextjs_password`

pgAdmin available at http://localhost:5050
- Email: admin@admin.com
- Password: admin

## 📚 Available Commands

```bash
npm run dev          # Start development
npm run build        # Build for production
npm run db:studio    # Open Prisma Studio
npm run db:migrate   # Run migrations
npm run db:seed      # Seed database
```

## 📖 Full Documentation

For complete documentation, visit: https://github.com/tildemark/skeleton-metronic

---

Made with ❤️ by [tildemark](https://github.com/tildemark)
READMEEOF

echo ""
echo "✅ DevContainer setup complete!"
echo ""
echo "📁 Created files:"
echo "   - .devcontainer/devcontainer.json"
echo "   - .devcontainer/docker-compose.yml"
echo "   - .devcontainer/Dockerfile"
echo "   - .devcontainer/setup.sh"
echo "   - .gitattributes"
echo ""
echo "🚀 Next steps:"
echo "   1. Open this folder in VS Code"
echo "   2. Press Ctrl+Shift+P (or Cmd+Shift+P on Mac)"
echo "   3. Select 'Dev Containers: Reopen in Container'"
echo "   4. Wait for setup to complete"
echo "   5. Run 'npm run dev'"
echo ""