#!/usr/bin/env bash
set -euo pipefail

# generate-schema.sh — Generate Prisma/Drizzle schema boilerplate
# Usage: ./generate-schema.sh [prisma|drizzle] [resource...]
# If no resources given, interactive menu shown.

SCHEMA_TYPE="${1:-}"
shift 2>/dev/null || true
GIVEN_RESOURCES=("$@")

RESOURCE_TYPES=(user product order post comment category tag profile invoice subscription team workspace notification payment)

PRISMA_OUT="schema.prisma"
DRIZZLE_OUT="schema.ts"

log()  { echo "[*]" "$@" >&2; }
err()  { echo "[!]" "$@" >&2; exit 1; }
pick() {
  local prompt="$1" outvar="$2"; shift 2
  select chosen in "$@"; do
    [[ -n "$chosen" ]] && break
  done
  printf -v "$outvar" "$chosen"
}

# ── Prisma generators ──────────────────────────────────────────────

prisma_user()      { cat <<'EOF'
model User {
  id             String    @id @default(uuid()) @db.Uuid
  email          String    @unique
  emailVerified  DateTime?
  name           String?
  image          String?
  role           Role      @default(USER)
  passwordHash   String?
  isActive       Boolean   @default(true)
  lastLoginAt    DateTime?
  createdAt      DateTime  @default(now())
  updatedAt      DateTime  @updatedAt

  profile    Profile?
  accounts   Account[]
  sessions   Session[]
  posts      Post[]
  comments   Comment[]
  orders     Order[]
  invoices   Invoice[]
  teams      TeamMember[]

  @@index([email])
  @@index([role, isActive])
  @@map("users")
}
EOF
}

prisma_profile()   { cat <<'EOF'
model Profile {
  id        String   @id @default(uuid()) @db.Uuid
  userId    String   @unique @db.Uuid
  bio       String?
  company   String?
  title     String?
  phone     String?
  location  String?
  website   String?
  avatarUrl String?
  metadata  Json?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@map("profiles")
}
EOF
}

prisma_account()   { cat <<'EOF'
model Account {
  id                String  @id @default(uuid()) @db.Uuid
  userId            String  @db.Uuid
  type              String
  provider          String
  providerAccountId String
  refreshToken      String? @map("refresh_token")
  accessToken       String? @map("access_token")
  expiresAt         Int?    @map("expires_at")
  tokenType         String? @map("token_type")
  scope             String?
  idToken           String? @map("id_token")
  sessionState      String? @map("session_state")

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([provider, providerAccountId])
  @@index([userId])
  @@map("accounts")
}
EOF
}

prisma_session()   { cat <<'EOF'
model Session {
  id           String   @id @default(uuid()) @db.Uuid
  sessionToken String   @unique
  userId       String   @db.Uuid
  expires      DateTime
  user         User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
  @@map("sessions")
}
EOF
}

prisma_product()   { cat <<'EOF'
model Product {
  id          String   @id @default(uuid()) @db.Uuid
  name        String
  slug        String   @unique
  description String?
  sku         String   @unique
  price       Decimal  @db.Decimal(10, 2)
  compareAt   Decimal? @map("compare_at_price") @db.Decimal(10, 2)
  cost        Decimal? @db.Decimal(10, 2)
  currency    String   @default("USD")
  weight      Decimal? @db.Decimal(8, 2)
  width       Decimal? @db.Decimal(8, 2)
  height      Decimal? @db.Decimal(8, 2)
  depth       Decimal? @db.Decimal(8, 2)
  status      String   @default("draft")
  isShippable Boolean  @default(true) @map("is_shippable")
  isDigital   Boolean  @default(false) @map("is_digital")
  tags        String[]
  metadata    Json?
  publishedAt DateTime?
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  categoryId String? @map("category_id") @db.Uuid
  category   Category? @relation(fields: [categoryId], references: [id])

  variants   ProductVariant[]
  orderItems OrderItem[]
  reviews    Review[]

  @@index([slug])
  @@index([status, publishedAt])
  @@index([categoryId])
  @@index([sku])
  @@index([tags], type: Gin)
  @@map("products")
}
EOF
}

prisma_product_variant() { cat <<'EOF'
model ProductVariant {
  id        String   @id @default(uuid()) @db.Uuid
  productId String   @map("product_id") @db.Uuid
  sku       String   @unique
  name      String
  price     Decimal? @db.Decimal(10, 2)
  stock     Int      @default(0)
  options   Json?    // e.g. {"color":"red","size":"M"}
  isActive  Boolean  @default(true)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  product Product @relation(fields: [productId], references: [id], onDelete: Cascade)
  orderItems OrderItem[]

  @@index([productId])
  @@index([sku])
  @@map("product_variants")
}
EOF
}

prisma_category()  { cat <<'EOF'
model Category {
  id          String     @id @default(uuid()) @db.Uuid
  name        String
  slug        String     @unique
  description String?
  image       String?
  sortOrder   Int        @default(0) @map("sort_order")
  isActive    Boolean    @default(true)
  parentId    String?    @map("parent_id") @db.Uuid
  parent      Category?  @relation("CategoryTree", fields: [parentId], references: [id])
  children    Category[] @relation("CategoryTree")
  products    Product[]
  createdAt   DateTime   @default(now())
  updatedAt   DateTime   @updatedAt

  @@index([parentId])
  @@index([slug])
  @@index([sortOrder])
  @@map("categories")
}
EOF
}

prisma_order()     { cat <<'EOF'
model Order {
  id             String         @id @default(uuid()) @db.Uuid
  orderNumber    String         @unique
  userId         String         @map("user_id") @db.Uuid
  status         OrderStatus    @default(PENDING)
  currency       String         @default("USD")
  subtotal       Decimal        @db.Decimal(12, 2)
  shippingCost   Decimal        @default(0) @map("shipping_cost") @db.Decimal(12, 2)
  taxAmount      Decimal        @default(0) @map("tax_amount") @db.Decimal(12, 2)
  discountAmount Decimal        @default(0) @map("discount_amount") @db.Decimal(12, 2)
  total          Decimal        @db.Decimal(12, 2)
  notes          String?
  billingAddr    Json?          @map("billing_address")
  shippingAddr   Json?          @map("shipping_address")
  paidAt         DateTime?      @map("paid_at")
  shippedAt      DateTime?      @map("shipped_at")
  deliveredAt    DateTime?      @map("delivered_at")
  cancelledAt    DateTime?      @map("cancelled_at")
  createdAt      DateTime       @default(now())
  updatedAt      DateTime       @updatedAt

  user       User        @relation(fields: [userId], references: [id])
  items      OrderItem[]
  invoices   Invoice[]
  payments   Payment[]

  @@index([userId])
  @@index([status, createdAt])
  @@index([orderNumber])
  @@index([createdAt])
  @@map("orders")
}
EOF
}

prisma_order_item(){ cat <<'EOF'
model OrderItem {
  id              String  @id @default(uuid()) @db.Uuid
  orderId         String  @map("order_id") @db.Uuid
  productId       String  @map("product_id") @db.Uuid
  variantId       String? @map("variant_id") @db.Uuid
  productName     String  @map("product_name")
  sku             String
  quantity        Int
  unitPrice       Decimal @map("unit_price") @db.Decimal(10, 2)
  totalPrice      Decimal @map("total_price") @db.Decimal(12, 2)
  metadata        Json?

  order   Order           @relation(fields: [orderId], references: [id], onDelete: Cascade)
  product Product         @relation(fields: [productId], references: [id])
  variant ProductVariant? @relation(fields: [variantId], references: [id])

  @@index([orderId])
  @@index([productId])
  @@map("order_items")
}
EOF
}

prisma_invoice()   { cat <<'EOF'
model Invoice {
  id             String       @id @default(uuid()) @db.Uuid
  invoiceNumber  String       @unique
  orderId        String       @map("order_id") @db.Uuid
  userId         String       @map("user_id") @db.Uuid
  status         InvoiceStatus @default(DRAFT)
  currency       String       @default("USD")
  amountDue      Decimal      @map("amount_due") @db.Decimal(12, 2)
  amountPaid     Decimal      @default(0) @map("amount_paid") @db.Decimal(12, 2)
  dueAt          DateTime     @map("due_at")
  issuedAt       DateTime?    @map("issued_at")
  paidAt         DateTime?    @map("paid_at")
  pdfUrl         String?      @map("pdf_url")
  metadata       Json?
  createdAt      DateTime     @default(now())
  updatedAt      DateTime     @updatedAt

  order    Order     @relation(fields: [orderId], references: [id])
  user     User      @relation(fields: [userId], references: [id])
  payments Payment[]

  @@index([orderId])
  @@index([userId])
  @@index([status, dueAt])
  @@map("invoices")
}
EOF
}

prisma_payment()   { cat <<'EOF'
model Payment {
  id             String   @id @default(uuid()) @db.Uuid
  invoiceId      String   @map("invoice_id") @db.Uuid
  orderId        String   @map("order_id") @db.Uuid
  amount         Decimal  @db.Decimal(12, 2)
  currency       String   @default("USD")
  method         String   // card, transfer, crypto, etc.
  status         String   @default("pending")
  gatewayId      String?  @map("gateway_id")
  gatewayResponse Json?   @map("gateway_response")
  paidAt         DateTime? @map("paid_at")
  createdAt      DateTime @default(now())

  invoice Invoice @relation(fields: [invoiceId], references: [id])
  order   Order   @relation(fields: [orderId], references: [id])

  @@index([invoiceId])
  @@index([orderId])
  @@index([status])
  @@map("payments")
}
EOF
}

prisma_post()      { cat <<'EOF'
model Post {
  id          String   @id @default(uuid()) @db.Uuid
  title       String
  slug        String   @unique
  excerpt     String?
  content     String   @db.Text
  status      String   @default("draft")
  featured    Boolean  @default(false)
  viewCount   Int      @default(0) @map("view_count")
  publishedAt DateTime? @map("published_at")
  authorId    String   @map("author_id") @db.Uuid
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  author   User       @relation(fields: [authorId], references: [id])
  tags     PostTag[]
  comments Comment[]
  reviews  Review[]

  @@index([slug])
  @@index([authorId])
  @@index([status, publishedAt])
  @@index([featured, publishedAt])
  @@map("posts")
}
EOF
}

prisma_comment()   { cat <<'EOF'
model Comment {
  id        String   @id @default(uuid()) @db.Uuid
  content   String   @db.Text
  authorId  String   @map("author_id") @db.Uuid
  postId    String   @map("post_id") @db.Uuid
  parentId  String?  @map("parent_id") @db.Uuid
  depth     Int      @default(0)
  isEdited  Boolean  @default(false) @map("is_edited")
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  author   User      @relation(fields: [authorId], references: [id])
  post     Post      @relation(fields: [postId], references: [id], onDelete: Cascade)
  parent   Comment?  @relation("CommentThread", fields: [parentId], references: [id])
  children Comment[] @relation("CommentThread")

  @@index([postId, createdAt])
  @@index([authorId])
  @@index([parentId])
  @@map("comments")
}
EOF
}

prisma_review()    { cat <<'EOF'
model Review {
  id        String   @id @default(uuid()) @db.Uuid
  rating    Int
  title     String?
  content   String?  @db.Text
  isVerified Boolean @default(false) @map("is_verified")
  authorId  String   @map("author_id") @db.Uuid
  productId String   @map("product_id") @db.Uuid
  postId    String?  @map("post_id") @db.Uuid
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  author  User     @relation(fields: [authorId], references: [id])
  product Product  @relation(fields: [productId], references: [id], onDelete: Cascade)
  post    Post?    @relation(fields: [postId], references: [id])

  @@unique([authorId, productId])
  @@index([productId, rating])
  @@index([authorId])
  @@map("reviews")
}
EOF
}

prisma_tag()       { cat <<'EOF'
model Tag {
  id        String   @id @default(uuid()) @db.Uuid
  name      String   @unique
  slug      String   @unique
  color     String?  @default("#6366f1")
  posts     PostTag[]
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@map("tags")
}

model PostTag {
  postId String @map("post_id") @db.Uuid
  tagId  String @map("tag_id") @db.Uuid

  post Post @relation(fields: [postId], references: [id], onDelete: Cascade)
  tag  Tag  @relation(fields: [tagId], references: [id], onDelete: Cascade)

  @@id([postId, tagId])
  @@map("post_tags")
}
EOF
}

prisma_team()      { cat <<'EOF'
model Team {
  id          String       @id @default(uuid()) @db.Uuid
  name        String
  slug        String       @unique
  description String?
  avatarUrl   String?      @map("avatar_url")
  ownerId     String       @map("owner_id") @db.Uuid
  isPersonal  Boolean      @default(false) @map("is_personal")
  createdAt   DateTime     @default(now())
  updatedAt   DateTime     @updatedAt

  owner   User         @relation(fields: [ownerId], references: [id])
  members TeamMember[]

  @@index([slug])
  @@index([ownerId])
  @@map("teams")
}

model TeamMember {
  id       String       @id @default(uuid()) @db.Uuid
  teamId   String       @map("team_id") @db.Uuid
  userId   String       @map("user_id") @db.Uuid
  role     TeamRole     @default(MEMBER)
  joinedAt DateTime     @default(now()) @map("joined_at")

  team Team @relation(fields: [teamId], references: [id], onDelete: Cascade)
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([teamId, userId])
  @@index([userId])
  @@map("team_members")
}
EOF
}

prisma_subscription() { cat <<'EOF'
model Subscription {
  id              String   @id @default(uuid()) @db.Uuid
  userId          String   @map("user_id") @db.Uuid
  plan            String   @default("free")
  status          String   @default("active")
  currentPeriodStart DateTime @map("current_period_start")
  currentPeriodEnd   DateTime @map("current_period_end")
  trialEndsAt     DateTime? @map("trial_ends_at")
  cancelledAt     DateTime? @map("cancelled_at")
  provider        String?  // stripe, paddle, etc.
  providerId      String?  @map("provider_id")
  metadata        Json?
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt

  user User @relation(fields: [userId], references: [id])

  @@index([userId])
  @@index([status, currentPeriodEnd])
  @@index([provider, providerId])
  @@map("subscriptions")
}
EOF
}

prisma_notification() { cat <<'EOF'
model Notification {
  id        String   @id @default(uuid()) @db.Uuid
  userId    String   @map("user_id") @db.Uuid
  type      String
  title     String
  body      String   @db.Text
  data      Json?
  readAt    DateTime? @map("read_at")
  createdAt DateTime @default(now())

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId, readAt, createdAt])
  @@index([createdAt])
  @@map("notifications")
}
EOF
}

# ── Enums (Prisma) ──────────────────────────────────────────────────

PRISMA_ENUMS=$(cat <<'EOF'
enum Role {
  USER
  ADMIN
  MODERATOR
}

enum OrderStatus {
  PENDING
  CONFIRMED
  PROCESSING
  SHIPPED
  DELIVERED
  CANCELLED
  REFUNDED
}

enum InvoiceStatus {
  DRAFT
  SENT
  PAID
  OVERDUE
  CANCELLED
  REFUNDED
}

enum TeamRole {
  OWNER
  ADMIN
  MEMBER
  VIEWER
}
EOF
)

# ── Drizzle generators ──────────────────────────────────────────────

drizzle_user() { cat <<'EOF'
import { pgTable, uuid, varchar, timestamp, boolean, jsonb, index } from "drizzle-orm/pg-core";
import { createInsertSchema, createSelectSchema } from "drizzle-zod";
import { relations } from "drizzle-orm";

export const users = pgTable("users", {
  id: uuid("id").defaultRandom().primaryKey(),
  email: varchar("email", { length: 255 }).notNull().unique(),
  emailVerified: timestamp("email_verified"),
  name: varchar("name", { length: 255 }),
  image: varchar("image", { length: 1024 }),
  role: varchar("role", { length: 20 }).notNull().default("USER"),
  passwordHash: varchar("password_hash", { length: 255 }),
  isActive: boolean("is_active").notNull().default(true),
  lastLoginAt: timestamp("last_login_at"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow().$onUpdate(() => new Date()),
}, (table) => ({
  emailIdx: index("idx_users_email").on(table.email),
  roleIdx: index("idx_users_role_active").on(table.role, table.isActive),
}));

export const usersRelations = relations(users, ({ one, many }) => ({
  // profiles: one(profiles),
  // posts: many(posts),
}));

export const insertUserSchema = createInsertSchema(users);
export const selectUserSchema = createSelectSchema(users);
export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
EOF
}

drizzle_product() { cat <<'EOF'
import { pgTable, uuid, varchar, text, numeric, boolean, timestamp, jsonb, index, uniqueIndex } from "drizzle-orm/pg-core";
import { createInsertSchema, createSelectSchema } from "drizzle-zod";
import { relations } from "drizzle-orm";

export const products = pgTable("products", {
  id: uuid("id").defaultRandom().primaryKey(),
  name: varchar("name", { length: 255 }).notNull(),
  slug: varchar("slug", { length: 255 }).notNull().unique(),
  description: text("description"),
  sku: varchar("sku", { length: 100 }).notNull().unique(),
  price: numeric("price", { precision: 10, scale: 2 }).notNull(),
  compareAt: numeric("compare_at_price", { precision: 10, scale: 2 }),
  cost: numeric("cost", { precision: 10, scale: 2 }),
  currency: varchar("currency", { length: 3 }).notNull().default("USD"),
  status: varchar("status", { length: 20 }).notNull().default("draft"),
  isShippable: boolean("is_shippable").notNull().default(true),
  isDigital: boolean("is_digital").notNull().default(false),
  tags: varchar("tags", { length: 50 }).array().notNull().default([]),
  metadata: jsonb("metadata"),
  categoryId: uuid("category_id"),
  publishedAt: timestamp("published_at"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow().$onUpdate(() => new Date()),
}, (table) => ({
  slugIdx: uniqueIndex("idx_products_slug").on(table.slug),
  skuIdx: uniqueIndex("idx_products_sku").on(table.sku),
  statusIdx: index("idx_products_status_published").on(table.status, table.publishedAt),
  categoryIdx: index("idx_products_category").on(table.categoryId),
  tagsIdx: index("idx_products_tags").on(table.tags),
}));

export const productsRelations = relations(products, ({ one, many }) => ({
  category: one(categories, { fields: [products.categoryId], references: [categories.id] }),
  // variants: many(productVariants),
}));

export const insertProductSchema = createInsertSchema(products);
export const selectProductSchema = createSelectSchema(products);
export type Product = typeof products.$inferSelect;
export type NewProduct = typeof products.$inferInsert;
EOF
}

drizzle_order() { cat <<'EOF'
import { pgTable, uuid, varchar, numeric, timestamp, jsonb, index, uniqueIndex } from "drizzle-orm/pg-core";
import { createInsertSchema, createSelectSchema } from "drizzle-zod";
import { relations } from "drizzle-orm";

export const orders = pgTable("orders", {
  id: uuid("id").defaultRandom().primaryKey(),
  orderNumber: varchar("order_number", { length: 50 }).notNull().unique(),
  userId: uuid("user_id").notNull(),
  status: varchar("status", { length: 20 }).notNull().default("PENDING"),
  currency: varchar("currency", { length: 3 }).notNull().default("USD"),
  subtotal: numeric("subtotal", { precision: 12, scale: 2 }).notNull(),
  shippingCost: numeric("shipping_cost", { precision: 12, scale: 2 }).notNull().default("0"),
  taxAmount: numeric("tax_amount", { precision: 12, scale: 2 }).notNull().default("0"),
  discountAmount: numeric("discount_amount", { precision: 12, scale: 2 }).notNull().default("0"),
  total: numeric("total", { precision: 12, scale: 2 }).notNull(),
  notes: text("notes"),
  billingAddress: jsonb("billing_address"),
  shippingAddress: jsonb("shipping_address"),
  paidAt: timestamp("paid_at"),
  shippedAt: timestamp("shipped_at"),
  deliveredAt: timestamp("delivered_at"),
  cancelledAt: timestamp("cancelled_at"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow().$onUpdate(() => new Date()),
}, (table) => ({
  userIdx: index("idx_orders_user").on(table.userId),
  statusIdx: index("idx_orders_status_created").on(table.status, table.createdAt),
  numberIdx: uniqueIndex("idx_orders_number").on(table.orderNumber),
  createdIdx: index("idx_orders_created").on(table.createdAt),
}));

export const ordersRelations = relations(orders, ({ one, many }) => ({
  user: one(users, { fields: [orders.userId], references: [users.id] }),
}));

export type Order = typeof orders.$inferSelect;
export type NewOrder = typeof orders.$inferInsert;
EOF
}

# ── Schema Assemblers ───────────────────────────────────────────────

build_prisma() {
  local out="${1:-$PRISMA_OUT}"
  local resources=("${@:2}")

  log "Generating Prisma schema → $out"

  # Header
  cat <<'HEADER' > "$out"
// ═══════════════════════════════════════════════════════════════════
// Prisma Schema — Generated by db-sculptor/generate-schema.sh
// ═══════════════════════════════════════════════════════════════════

generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["fullTextSearch", "postgresqlExtensions"]
}

datasource db {
  provider   = "postgresql"
  url        = env("DATABASE_URL")
  extensions = [pgcrypto, citext, uuid_ossp, pg_trgm]
}

// ── Enums ──────────────────────────────────────────────────────────

HEADER

  echo "$PRISMA_ENUMS" >> "$out"
  echo "" >> "$out"
  echo "// ── Models ──────────────────────────────────────────────────────────" >> "$out"
  echo "" >> "$out"

  for r in "${resources[@]}"; do
    case "$r" in
      user)         prisma_user >> "$out"; echo "" >> "$out" ;;
      profile)      prisma_profile >> "$out"; echo "" >> "$out" ;;
      account)      prisma_account >> "$out"; echo "" >> "$out" ;;
      session)      prisma_session >> "$out"; echo "" >> "$out" ;;
      product)      prisma_product >> "$out"; echo "" >> "$out" ;;
      variant)      prisma_product_variant >> "$out"; echo "" >> "$out" ;;
      category)     prisma_category >> "$out"; echo "" >> "$out" ;;
      order)        prisma_order >> "$out"; echo "" >> "$out" ;;
      orderitem)    prisma_order_item >> "$out"; echo "" >> "$out" ;;
      invoice)      prisma_invoice >> "$out"; echo "" >> "$out" ;;
      payment)      prisma_payment >> "$out"; echo "" >> "$out" ;;
      post)         prisma_post >> "$out"; echo "" >> "$out" ;;
      comment)      prisma_comment >> "$out"; echo "" >> "$out" ;;
      review)       prisma_review >> "$out"; echo "" >> "$out" ;;
      tag)          prisma_tag >> "$out"; echo "" >> "$out" ;;
      team)         prisma_team >> "$out"; echo "" >> "$out" ;;
      subscription) prisma_subscription >> "$out"; echo "" >> "$out" ;;
      notification) prisma_notification >> "$out"; echo "" >> "$out" ;;
    esac
  done

  log "Done → $out ($(wc -l < "$out") lines)"
}

build_drizzle() {
  local out="${1:-$DRIZZLE_OUT}"
  local resources=("${@:2}")

  log "Generating Drizzle schema → $out"

  {
    echo "// ═══════════════════════════════════════════════════════════════════"
    echo "// Drizzle Schema — Generated by db-sculptor/generate-schema.sh"
    echo "// ═══════════════════════════════════════════════════════════════════"
    echo ""
    echo "import { pgTable, uuid, varchar, timestamp, boolean, text, numeric, jsonb, index, uniqueIndex } from \"drizzle-orm/pg-core\";"
    echo "import { createInsertSchema, createSelectSchema } from \"drizzle-zod\";"
    echo "import { relations } from \"drizzle-orm\";"
    echo ""
  } > "$out"

  for r in "${resources[@]}"; do
    case "$r" in
      user)    drizzle_user >> "$out"; echo "" >> "$out" ;;
      product) drizzle_product >> "$out"; echo "" >> "$out" ;;
      order)   drizzle_order >> "$out"; echo "" >> "$out" ;;
      *)       log "No Drizzle template for '${r}', skipping" ;;
    esac
  done

  log "Done → $out ($(wc -l < "$out") lines)"
}

# ── Interactive Menu ────────────────────────────────────────────────

interactive() {
  echo "Available resource types (space-separated numbers, or 'all'):"
  echo ""
  for i in "${!RESOURCE_TYPES[@]}"; do
    printf "  %2d) %s\n" $((i+1)) "${RESOURCE_TYPES[$i]}"
  done
  echo ""
  read -rp "Select resources (e.g. '1 2 3' or 'all'): " selection

  if [[ "$selection" == "all" ]]; then
    SELECTED=("${RESOURCE_TYPES[@]}")
  else
    SELECTED=()
    for num in $selection; do
      idx=$((num - 1))
      if [[ $idx -ge 0 && $idx -lt ${#RESOURCE_TYPES[@]} ]]; then
        SELECTED+=("${RESOURCE_TYPES[$idx]}")
      fi
    done
  fi

  if [[ ${#SELECTED[@]} -eq 0 ]]; then
    err "No valid resources selected."
  fi

  echo ""
  pick "Prisma or Drizzle?" stype "prisma" "drizzle"
  SCHEMA_TYPE="$stype"
}

# ── Main ────────────────────────────────────────────────────────────

main() {
  if [[ -z "$SCHEMA_TYPE" ]]; then
    interactive
  fi

  local resources=()
  if [[ ${#GIVEN_RESOURCES[@]} -gt 0 ]]; then
    for r in "${GIVEN_RESOURCES[@]}"; do
      local lc="${r,,}"
      resources+=("$lc")
    done
  else
    resources=("${SELECTED[@]}")
  fi

  case "$SCHEMA_TYPE" in
    prisma|Prisma|PRISMA)
      build_prisma "$PRISMA_OUT" "${resources[@]}"
      ;;
    drizzle|Drizzle|DRIZZLE)
      build_drizzle "$DRIZZLE_OUT" "${resources[@]}"
      ;;
    *)
      err "Unknown schema type: $SCHEMA_TYPE. Use 'prisma' or 'drizzle'."
      ;;
  esac
}

main
