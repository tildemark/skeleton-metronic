# Skeleton Metronic

A production-ready Next.js starter template with Metronic theme, PostgreSQL database, and DevContainer support.

## 🚀 Features

- ⚡ **Next.js 15** - React framework with App Router
- 🎨 **Metronic Theme** - Premium admin dashboard theme from ThemeForest
- 💾 **PostgreSQL** - Robust relational database
- 🔷 **Prisma ORM** - Type-safe database client
- 🐳 **DevContainer** - Consistent development environment
- 🎯 **TypeScript** - Full type safety
- 🎨 **Tailwind CSS** - Utility-first CSS framework
- 📊 **pgAdmin** - Database management interface

## 📋 Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [VS Code](https://code.visualstudio.com/)
- [Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- Valid Metronic license from ThemeForest

## 🛠️ Quick Start

### Option 1: Automated Setup (Recommended)

1. **Clone or download this repository**

   ```bash
   git clone https://github.com/tildemark/skeleton-metronic.git
   cd skeleton-metronic
   ```

2. **Run the setup script** (if not already run)

   ```bash
   bash quick-setup.sh
   ```

3. **Open in DevContainer**
   - Open folder in VS Code
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
   - Select: **"Dev Containers: Reopen in Container"**
   - Wait for container to build (3-5 minutes first time)

4. **Start development**

   ```bash
   npm run dev
   ```

5. **Access your application**
   - **App**: http://localhost:3000
   - **pgAdmin**: http://localhost:5050
   - **API Health**: http://localhost:3000/api/health

### Option 2: Manual Setup

If you're starting from a fresh Metronic download:

1. **Extract Metronic Next.js template** to a new folder
2. **Copy DevContainer files** from this repo:
   - `.devcontainer/` folder
   - `.gitattributes` file
3. **Follow steps 3-5** from Option 1 above

## 📁 Project Structure

```
skeleton-metronic/
├── .devcontainer/          # DevContainer configuration
│   ├── devcontainer.json   # VS Code DevContainer settings
│   ├── docker-compose.yml  # Docker services (app, db, pgadmin)
│   ├── Dockerfile          # Container image definition
│   └── setup.sh            # Automated setup script
├── prisma/                 # Database schema & migrations
│   ├── schema.prisma       # Database models
│   └── seed.ts             # Database seeding
├── src/                    # Source code (or app/ depending on Metronic version)
│   ├── app/                # Next.js App Router
│   │   ├── api/           # API routes
│   │   │   └── health/    # Health check endpoint
│   │   ├── layout.tsx     # Root layout
│   │   └── page.tsx       # Homepage
│   ├── components/         # React components
│   ├── lib/               # Utilities
│   │   └── prisma.ts      # Prisma client singleton
│   └── ...                # Other Metronic folders
├── public/                 # Static assets
├── .env                    # Environment variables (not in git)
├── .env.example            # Environment template
├── .gitattributes         # Git line ending configuration
├── .gitignore             # Git ignore rules
├── package.json           # Dependencies and scripts
├── tsconfig.json          # TypeScript configuration
└── README.md              # This file
```

## 🔧 Configuration

### Environment Variables

The `.env` file is automatically created during setup:

```env
# Database
DATABASE_URL="postgresql://nextjs_user:nextjs_password@db:5432/nextjs_db"

# Next.js
NEXT_PUBLIC_APP_URL=http://localhost:3000
NODE_ENV=development

# Metronic Theme
NEXT_PUBLIC_THEME_MODE=light
```

### Database Credentials

**PostgreSQL:**

- Host: `db` (internal) or `localhost` (external)
- Port: `5432`
- Database: `nextjs_db`
- Username: `nextjs_user`
- Password: `nextjs_password`

**pgAdmin:**

- URL: http://localhost:5050
- Email: `admin@admin.com`
- Password: `admin`

To connect pgAdmin to PostgreSQL:

1. Open http://localhost:5050
2. Login with credentials above
3. Right-click "Servers" → Register → Server
4. General tab: Name = `NextJS DB`
5. Connection tab:
   - Host: `db`
   - Port: `5432`
   - Database: `nextjs_db`
   - Username: `nextjs_user`
   - Password: `nextjs_password`

## 📦 Available Scripts

### Development

```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run start        # Start production server
npm run lint         # Run ESLint
```

### Database

```bash
npm run db:studio    # Open Prisma Studio (database GUI)
npm run db:push      # Push schema changes to database
npm run db:migrate   # Create and run migrations
npm run db:seed      # Seed database with initial data
npm run db:generate  # Generate Prisma Client
```

## 🗄️ Database Management

### Prisma Studio

Visual database editor:

```bash
npm run db:studio
```

Opens at http://localhost:5555

### pgAdmin

Full-featured PostgreSQL management:

1. Open http://localhost:5050
2. Login with credentials from Configuration section
3. Register server using connection details above

### Command Line

Direct PostgreSQL access:

```bash
# Inside DevContainer
psql postgresql://nextjs_user:nextjs_password@db:5432/nextjs_db
```

## 🎨 Customization

### Adding Database Models

1. **Edit `prisma/schema.prisma`**

   ```prisma
   model YourModel {
     id        String   @id @default(cuid())
     name      String
     createdAt DateTime @default(now())
   }
   ```

2. **Push changes to database**

   ```bash
   npm run db:push
   ```

3. **Generate Prisma Client**
   ```bash
   npm run db:generate
   ```

### Using Prisma in Your Code

```typescript
import { prisma } from '@/lib/prisma';

// In API routes or Server Components
const users = await prisma.user.findMany();
```

### Creating API Routes

Create files in `src/app/api/` (or `app/api/`):

```typescript
// src/app/api/users/route.ts
import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export async function GET() {
  const users = await prisma.user.findMany();
  return NextResponse.json(users);
}

export async function POST(request: Request) {
  const body = await request.json();
  const user = await prisma.user.create({ data: body });
  return NextResponse.json(user);
}
```

## 🐛 Troubleshooting

### Line Ending Issues

**Error:** `$'\r': command not found`

**Solution:**

1. Open `setup.sh` in VS Code
2. Click "CRLF" in bottom-right corner
3. Select "LF"
4. Save file
5. Rebuild container

### Port Already in Use

**Error:** Port 3000/5432/5050 already in use

**Solution:**

```bash
# Find and kill process (Windows)
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Or change port in docker-compose.yml
```

### Database Connection Failed

**Solution:**

```bash
# Check if containers are running
docker ps

# Restart containers
docker-compose -f .devcontainer/docker-compose.yml restart

# Check logs
docker logs <container-name>
```

### Cannot Find Module '@/lib/prisma'

**Solution:**

1. Ensure Prisma Client is generated: `npm run db:generate`
2. Check `tsconfig.json` has correct path mapping:
   ```json
   {
     "compilerOptions": {
       "paths": {
         "@/*": ["./src/*"] // or ["./*"] depending on structure
       }
     }
   }
   ```

### DevContainer Build Fails

**Solution:**

```bash
# Clean Docker cache
docker system prune -a

# Rebuild without cache
# In VS Code: Ctrl+Shift+P → "Dev Containers: Rebuild Container Without Cache"
```

## 🔒 Security Notes

⚠️ **Important for Production:**

1. **Change default credentials** in `docker-compose.yml` and `.env`
2. **Never commit `.env`** to version control (already in `.gitignore`)
3. **Use strong passwords** for database and pgAdmin
4. **Enable authentication** for your application
5. **Review Metronic security** best practices in their documentation

## 📚 Resources

- [Metronic Documentation](https://docs.keenthemes.com/metronic-nextjs)
- [Next.js Documentation](https://nextjs.org/docs)
- [Prisma Documentation](https://www.prisma.io/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [DevContainers Documentation](https://containers.dev/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit changes: `git commit -am 'Add feature'`
4. Push to branch: `git push origin feature-name`
5. Submit a pull request

## 📝 License

This starter template is based on:

- **Metronic** - Requires valid license from ThemeForest
- **Next.js** - MIT License
- **Prisma** - Apache 2.0 License

Please ensure you have proper licenses for all components.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/tildemark/skeleton-metronic/issues)
- **Metronic Support**: [Metronic Support Portal](https://devs.keenthemes.com/)
- **Discussions**: [GitHub Discussions](https://github.com/tildemark/skeleton-metronic/discussions)

## ✨ What's Next?

After setup, consider adding:

- [ ] Authentication (NextAuth.js recommended)
- [ ] Authorization & role-based access control
- [ ] API middleware for logging/validation
- [ ] Error handling & monitoring (Sentry)
- [ ] Testing setup (Jest, Playwright)
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Production deployment (Vercel, Railway)
- [ ] Email service integration
- [ ] File upload handling
- [ ] Caching strategy (Redis)

---

Made with ❤️ by [tildemark](https://github.com/tildemark)
