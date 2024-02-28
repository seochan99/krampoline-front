# Build stage
FROM krmp-d2hub-idock.9rum.cc/goorm/node:18 AS base

# Install dependencies only when needed
FROM base AS deps
WORKDIR /usr/src/app

# Install dependencies based on the preferred package manager
COPY swiping-jeju-frontend/package*.json ./
RUN npm ci



# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /usr/src/app
COPY --from=deps /usr/src/app/node_modules ./node_modules
COPY swiping-jeju-frontend/ .
RUN npm run build


FROM base AS runner
WORKDIR /usr/src/app

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Set the correct permission for prerender cache
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder /usr/src/app/public ./public
COPY --from=builder --chown=nextjs:nodejs /usr/src/app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /usr/src/app/.next/static ./.next/static


USER nextjs

EXPOSE 3000

ENV PORT 3000
# set hostname to localhost
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]