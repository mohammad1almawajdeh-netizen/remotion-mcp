# ── Build stage ────────────────────────────────────────────────────
FROM node:20-slim AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src/ ./src/
RUN npm run build

# ── Production stage ───────────────────────────────────────────────
FROM node:20-slim AS production

# Install Chromium and fonts required for Remotion rendering
RUN apt-get update && apt-get install -y \
    chromium \
    fonts-freefont-ttf \
    fonts-noto-core \
    fonts-noto-extra \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy dependencies and compiled server
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY package*.json ./

# Chromium executable
ENV CHROME_EXECUTABLE=/usr/bin/chromium

# MCP HTTP server
ENV MCP_MODE=http
ENV PORT=3000

# Remotion render output
RUN mkdir -p /renders
ENV RENDER_OUTPUT_DIR=/renders

EXPOSE 3000

CMD ["node", "dist/index.js"]
