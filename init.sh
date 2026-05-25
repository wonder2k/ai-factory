#!/bin/bash

# ==============================================================================
# 🚀 Hermes AI Factory - Free-Claude-Code 纯正基因种子脚手架 (开箱即用)
# ==============================================================================

set -e

# 确保所有文件精准生成在当前运行脚本的根目录下，绝不多套一层文件夹
BASE_DIR=$(pwd)

echo "===================================================="
echo "🌱 开始释放完全适配 free-claude-code CLI 架构的配置文件..."
echo "📂 当前工作区绝对路径: $BASE_DIR"
echo "===================================================="

# 1. 建立标准的完全体目录结构
mkdir -p "$BASE_DIR/docker"
mkdir -p "$BASE_DIR/.devcontainer"
mkdir -p "$BASE_DIR/llm-integrations"

# 2. 写入 .devcontainer/devcontainer.json
cat << 'EOF' > "$BASE_DIR/.devcontainer/devcontainer.json"
{
    "name": "Hermes AI Factory Workspace",
    "dockerComposeFile": "../docker-compose.yml",
    "service": "hermes-agent-center",
    "workspaceFolder": "/workspace",
    "customizations": {
        "vscode": {
            "extensions": [
                "ms-azuretools.vscode-docker",
                "dbaeumer.vscode-eslint"
            ]
        }
    },
    "remoteUser": "root"
}
EOF

# 3. 写入 docker/Dockerfile.claude (★重点：在这里注入 fcc 一键安装)
cat << 'EOF' > "$BASE_DIR/docker/Dockerfile.claude"
FROM node:22-bookworm

# 安装全套底层构建链、标准 C 库环境、原生 PostgreSQL 客户端以及 nano/curl
RUN apt-get update && apt-get install -y \
    git \
    bash \
    openssh-client \
    build-essential \
    python3 \
    postgresql-client \
    curl \
    nano \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# A. 全局安装官方核心工兵组件
RUN npm install -g @anthropic-ai/claude-code

# B. 🌟 按照你的步骤 1：通过官方脚本一键安装 free-claude-code 体系
RUN curl -fsSL "https://github.com/Alishahryar1/free-claude-code/blob/main/scripts/install.sh?raw=1" | sh

# 固化本地 Git 身份
RUN git config --global user.name "Hermes AI Coder" && \
    git config --global user.email "hermes-agent@internal.ai"

# C. 🌟 按照你的步骤 2、3、4：在运行时进行自动初始化、注入配置并守护运行
# 这样容器一拉起来，fcc-server 就已经在后台跑着了，而且配置全部自动对齐
CMD ["sh", "-c", "\
echo '⚙️  正在执行 fcc-init 初始化...' && \
fcc-init || true && \
mkdir -p ~/.fcc && \
echo '📝 正在自动写入 ~/.fcc/.env 配置文件...' && \
echo \"DEEPSEEK_API_KEY=\\\"${DEEPSEEK_API_KEY}\\\"\" > ~/.fcc/.env && \
echo \"MODEL=\\\"deepseek/deepseek-v4-flash\\\"\" >> ~/.fcc/.env && \
echo \"ANTHROPIC_AUTH_TOKEN=\\\"freecc\\\"\" >> ~/.fcc/.env && \
echo '🚀 正在后台拉起 fcc-server 代理...' && \
fcc-server & \
sleep 2 && \
echo '🎉 Free-Claude-Code 环境就绪，工兵常驻就位！' && \
tail -f /dev/null \
"]
EOF

# 4. 写入 docker-compose.yml (回归纯净的多容器网段，剥离无用的旧 proxy 服务)
cat << 'EOF' > "$BASE_DIR/docker-compose.yml"
version: '3.8'

networks:
  hermes-net:
    name: workspace_hermes-net
    driver: bridge

volumes:
  workspace_postgres_data:
    name: workspace_postgres_data

services:
  postgres-db:
    image: postgres:16-alpine
    container_name: postgres-db
    networks:
      - hermes-net
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=SecurePass_2026
      - POSTGRES_DB=app_prod
    ports:
      - "5432:5432"
    volumes:
      - workspace_postgres_data:/var/lib/postgresql/data
    restart: always

  chrome-headless:
    image: browserless/chrome:1.60-chrome-stable
    container_name: chrome-headless
    networks:
      - hermes-net
    ports:
      - "3000:3000"
    environment:
      - MAX_CONCURRENT_SESSIONS=10
    restart: always

  claude-dev-env:
    build:
      context: .
      dockerfile: docker/Dockerfile.claude
    container_name: claude-dev-env
    networks:
      - hermes-net
    volumes:
      - .:/workspace
    environment:
      - DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}
    restart: always

  hermes-agent-center:
    image: node:22-bookworm
    container_name: hermes-agent-center
    networks:
      - hermes-net
    volumes:
      - .:/workspace
    working_dir: /workspace
    environment:
      - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
      - DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}
    command: tail -f /dev/null
    restart: always
EOF

# 5. 写入 hermes-server.js (★重点：总控大脑的执行命令无缝进化为 fcc-claude)
cat << 'EOF' > "$BASE_DIR/hermes-server.js"
const { exec } = require('child_process');
const https = require('https');

const TOKEN = process.env.TELEGRAM_BOT_TOKEN;
if (!TOKEN) {
    console.error("❌ Error: TELEGRAM_BOT_TOKEN is missing!");
    process.exit(1);
}

let lastUpdateId = 0;

function sendMessage(chatId, text) {
    const data = JSON.stringify({ chat_id: chatId, text: text.substring(0, 4000) });
    const req = https.request(`https://api.telegram.org/bot${TOKEN}/sendMessage`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
    });
    req.on('error', (e) => console.error('发送消息失败:', e));
    req.write(data);
    req.end();
}

function pollUpdates() {
    https.get(`https://api.telegram.org/bot${TOKEN}/getUpdates?offset=${lastUpdateId + 1}&timeout=30`, (res) => {
        let body = '';
        res.on('data', chunk => body += chunk);
        res.on('end', () => {
            try {
                const data = JSON.parse(body);
                if (data.ok && data.result.length > 0) {
                    for (const update of data.result) {
                        lastUpdateId = update.update_id;
                        if (update.message && update.message.text) {
                            const chatId = update.message.chat_id;
                            const userPrompt = update.message.text;

                            console.log(`📩 收到电报指令: ${userPrompt}`);
                            sendMessage(chatId, `🚀 Hermes 收到指令，正在唤醒 Claude 工兵执行，请稍候...`);

                            const safePrompt = userPrompt.replace(/"/g, '\\"');
                            // 🌟 核心进化：这里不再调用纯 claude，而是直接轰入搭载了 FCC 代理的包裹命令 fcc-claude！
                            exec(`docker exec -i claude-dev-env fcc-claude "${safePrompt} --yes"`, (err, stdout, stderr) => {
                                const output = stdout || stderr || "执行完毕，无控制台输出。";
                                sendMessage(chatId, `✅ **Claude 执行战果汇报：**\n\n${output}`);
                            });
                        }
                    }
                }
            } catch (e) { console.error("解析错误:", e); }
            pollUpdates();
        });
    }).on('error', (err) => {
        console.error("轮询网络错误，5秒后重试...", err.message);
        setTimeout(pollUpdates, 5000);
    });
}

console.log("🚀 Hermes 总控大脑已点火，正在监听 Telegram 消息...");
pollUpdates();
EOF

# 6. 写入 CLAUDE.md
cat << 'EOF' > "$BASE_DIR/CLAUDE.md"
# 🛠️ Hermes AI Factory Project Guide

## ⚙️ Environment Constraints
- Node Version: 22 (Debian Bookworm)
- Database: PostgreSQL 16 (Host: postgres-db, Port: 5432, User: postgres, DB: app_prod)
- Headless Browser: Browserless Chrome (Host: chrome-headless, Port: 3000)
- Proxy CLI Wrapper: free-claude-code (fcc-server, fcc-claude) forwarding to DeepSeek Flash

## 🎯 Development Rules
- ALWAYS use `fcc-claude` for running development agent queries.
- ALWAYS check database connectivity using local native `psql` client before writing migration files.
- Keep commands non-interactive; assume `--yes` for all automated scripts.
EOF

echo "===================================================="
echo "🎉 适配 free-claude-code CLI 工具链的满配完全体脚手架已在当前目录下释放！"
echo "👉 接下来请直接在 Codespaces 中运行: docker compose up -d --build"
echo "===================================================="
