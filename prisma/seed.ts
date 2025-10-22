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
