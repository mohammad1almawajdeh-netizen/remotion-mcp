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

# Chromium + Linux libraries + Arabic/Unicode fonts for Remotion
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    ca-certificates \
    fonts-freefont-ttf \
    fonts-noto-core \
    fonts-noto-extra \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2 \
    libatspi2.0-0 \
    libx11-xcb1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy installed dependencies + compiled MCP server
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY package*.json ./

# Chromium used by Remotion
ENV CHROME_EXECUTABLE=/usr/bin/chromium

# MCP HTTP server
ENV MCP_MODE=http
ENV PORT=3000

# Render output directory
RUN mkdir -p /renders
ENV RENDER_OUTPUT_DIR=/renders

EXPOSE 3000

CMD ["node", "dist/index.js"]
