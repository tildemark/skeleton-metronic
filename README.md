# Next.js + TypeScript + Postgres Skeleton

A complete, production-ready development environment for Next.js with PostgreSQL, using VS Code DevContainers.

## What's Included

- **Next.js 15** - Latest with App Router
- **TypeScript** - Type-safe development
- **PostgreSQL 16** - Powerful relational database
- **Prisma** - Modern ORM with migrations
- **pgAdmin** - Web-based database management
- **Tailwind CSS** - Utility-first styling
- **Docker DevContainer** - Consistent development environment

## What You Need

- **Docker Desktop** - Download: https://www.docker.com/products/docker-desktop
- **Visual Studio Code** - Download: https://code.visualstudio.com/
- **Dev Containers Extension** - Install from VS Code Extensions panel

## Quick Start

1. **Download/Clone this repository**
   ```bash
   git clone https://github.com/tildemark/skeleton-js.git
   cd skeleton-js
   ```

2. **Open in VS Code**
   ```bash
   code .
   ```

3. **Reopen in Container**
   - VS Code will detect the DevContainer
   - Click "Reopen in Container" when prompted
   - OR press `F1` → type "Dev Containers: Reopen in Container"

4. **Wait for Setup** (2-5 minutes first time)
   - The setup script will automatically:
     - Install all dependencies
     - Set up PostgreSQL database
     - Initialize Prisma
     - Create example schema and seed data
     - Configure Next.js

5. **Start Development**
   ```bash
   npm run dev
   ```

6. **Access Your Application**
   - Next.js App: http://localhost:3000
   - pgAdmin: http://localhost:5050
   - API Health Check: http://localhost:3000/api/health

## After Installation

Your project will have:
- ✅ Next.js 15 with App Router
- ✅ TypeScript configured
- ✅ PostgreSQL database running
- ✅ Prisma ORM with example schema
- ✅ Sample User and Post models
- ✅ Database seeded with example data
- ✅ Tailwind CSS configured
- ✅ API health check endpoint
- ✅ pgAdmin for database management

## Project Structure

```
skeleton-js/
│
├── .devcontainer/              # DevContainer configuration
│   ├── devcontainer.json       # VS Code container settings
│   ├── docker-compose.yml      # Multi-container orchestration
│   ├── Dockerfile              # Node.js image definition
│   └── setup.sh                # Automatic setup script
│
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── api/                # API routes
│   │   │   └── health/
│   │   │       └── route.ts    # Health check endpoint
│   │   ├── layout.tsx          # Root layout
│   │   ├── page.tsx            # Home page
│   │   └── globals.css         # Global styles
│   │
│   ├── components/             # React components
│   │   └── ui/                 # UI components
│   │
│   ├── lib/                    # Utility functions
│   │   └── prisma.ts           # Prisma client singleton
│   │
│   └── types/                  # TypeScript types
│       └── index.ts
│
├── prisma/
│   ├── schema.prisma           # Database schema
│   ├── migrations/             # Database migrations
│   └── seed.ts                 # Database seeder
│
├── public/                     # Static assets
│
├── .env                        # Environment variables (not in Git)
├── .env.example                # Environment template
├── .gitignore
├── next.config.ts              # Next.js configuration
├── tsconfig.json               # TypeScript configuration
├── tailwind.config.ts          # Tailwind CSS config
├── postcss.config.js
├── package.json
└── README.md
```

## Database Management

### Using pgAdmin (Web GUI)

1. Open pgAdmin: http://localhost:5050
2. Login with:
   - Email: `admin@admin.com`
   - Password: `admin`
3. Add a new server:
   - **Name:** NextJS DB
   - **Host:** `db`
   - **Port:** `5432`
   - **Database:** `nextjs_db`
   - **Username:** `nextjs_user`
   - **Password:** `nextjs_password`

### Using Prisma Studio

```bash
npm run db:studio
```

Opens at http://localhost:5555

### Prisma Commands

```bash
# Generate Prisma Client (after schema changes)
npm run db:generate

# Push schema changes to database (development)
npm run db:push

# Create a new migration
npm run db:migrate

# Deploy migrations (production)
npm run db:migrate:deploy

# Seed the database
npm run db:seed

# Open Prisma Studio
npm run db:studio
```

### Command Line Access

```bash
# Connect to PostgreSQL
PGPASSWORD=nextjs_password psql -h db -U nextjs_user -d nextjs_db

# Run a query
PGPASSWORD=nextjs_password psql -h db -U nextjs_user -d nextjs_db -c "SELECT * FROM \"User\";"
```

## Creating Your First Feature

### 1. Update the Prisma Schema

Edit `prisma/schema.prisma`:

```prisma
model Product {
  id          String   @id @default(cuid())
  name        String
  description String?
  price       Decimal
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
}
```

### 2. Create Migration

```bash
npm run db:migrate
# Enter migration name: "add_product_model"
```

### 3. Create API Route

Create `src/app/api/products/route.ts`:

```typescript
import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  const products = await prisma.product.findMany()
  return NextResponse.json(products)
}

export async function POST(request: Request) {
  const body = await request.json()
  const product = await prisma.product.create({ data: body })
  return NextResponse.json(product)
}
```

### 4. Create a Page

Create `src/app/products/page.tsx`:

```typescript
export default async function ProductsPage() {
  const res = await fetch('http://localhost:3000/api/products')
  const products = await res.json()
  
  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Products</h1>
      <ul>
        {products.map((product: any) => (
          <li key={product.id}>{product.name}</li>
        ))}
      </ul>
    </div>
  )
}
```

## Environment Variables

The `.env` file is automatically created with:

```env
# Database
DATABASE_URL="postgresql://nextjs_user:nextjs_password@db:5432/nextjs_db"

# Next.js
NEXT_PUBLIC_APP_URL=http://localhost:3000
NODE_ENV=development
```

To add more variables:
1. Add to `.env` file
2. Update `.env.example` (without sensitive values)
3. Restart dev server

## Troubleshooting

### Port Already in Use

If port 3000 is already in use, change it in `.devcontainer/docker-compose.yml`:

```yaml
app:
  ports:
    - "3001:3000"  # Change 3000 to 3001
```

Then rebuild: `F1` → "Dev Containers: Rebuild Container"

### Database Connection Failed

1. Check if PostgreSQL is ready:
   ```bash
   PGPASSWORD=nextjs_password psql -h db -U nextjs_user -d nextjs_db -c '\q'
   ```

2. If error, wait 30 seconds and try again (first time setup)

3. Regenerate Prisma Client:
   ```bash
   npm run db:generate
   ```

### Container Won't Start

1. Check Docker Desktop is running
2. Check Docker logs:
   ```bash
   docker-compose -f .devcontainer/docker-compose.yml logs
   ```
3. Rebuild container:
   - Press `F1`
   - Type "Dev Containers: Rebuild Container"
   - Press Enter

### Permission Denied

If you get permission errors, run inside container:
```bash
sudo chown -R node:node /workspace
```

### Slow Performance (macOS)

The `:cached` volume mount is already configured for better performance on macOS.

## Customization

### Change Database Credentials

Edit `.devcontainer/docker-compose.yml`:

```yaml
db:
  environment:
    POSTGRES_USER: your_user
    POSTGRES_PASSWORD: your_password
    POSTGRES_DB: your_database
```

Update `.env` file to match, then rebuild container.

### Add More VS Code Extensions

Edit `.devcontainer/devcontainer.json`:

```json
"extensions": [
  "dbaeumer.vscode-eslint",
  "your.extension.id"
]
```

### Change Node.js Version

Edit `.devcontainer/Dockerfile`:

```dockerfile
FROM node:18-bullseye  # or node:21-bullseye
```

## Available Scripts

```bash
# Development
npm run dev          # Start Next.js dev server
npm run build        # Build for production
npm run start        # Start production server
npm run lint         # Run ESLint

# Database
npm run db:generate  # Generate Prisma Client
npm run db:push      # Push schema to database
npm run db:migrate   # Create and run migration
npm run db:seed      # Seed database
npm run db:studio    # Open Prisma Studio
```

## Production Deployment

Before deploying to production:

1. **Update environment variables**
   - Change database credentials
   - Set `NODE_ENV=production`
   - Add production database URL

2. **Disable debug mode**
   - Remove pgAdmin service
   - Set proper logging levels

3. **Security checklist**
   - Enable SSL/HTTPS
   - Configure CORS properly
   - Set up proper authentication
   - Enable security headers
   - Configure rate limiting

4. **Run migrations**
   ```bash
   npm run db:migrate:deploy
   ```

## Resources

- **Next.js Documentation:** https://nextjs.org/docs
- **Prisma Documentation:** https://www.prisma.io/docs
- **PostgreSQL Documentation:** https://www.postgresql.org/docs/
- **Tailwind CSS:** https://tailwindcss.com/docs
- **DevContainers:** https://code.visualstudio.com/docs/devcontainers/containers

## License

MIT

---

**Questions?** Open an issue on GitHub!

**Happy Coding!** 🚀