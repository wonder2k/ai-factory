#!/bin/bash

# ==============================================================================
# 🚀 Hermes AI Factory - DeepSeek 代理完全体种子脚手架 (开箱即用)
# ==============================================================================

set -e

# 确保所有文件精准生成在当前运行脚本的根目录下，绝对不会多套一层文件夹
BASE_DIR=$(pwd)

echo "===================================================="
echo "🌱 开始释放包含 free-claude-code 代理的全套配置文件..."
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

# 3. 写入 docker/Dockerfile.claude (工兵容器：指向本地代理)
cat << 'EOF' > "$BASE_DIR/docker/Dockerfile.claude"
FROM node:22-bookworm

# 安装全套底层构建链、标准 C 库环境以及原生 PostgreSQL 客户端
RUN apt-get update && apt-get install -y \
    git \
    bash \
    openssh-client \
    build-essential \
    python3 \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# 全局安装官方核心工兵组件
RUN npm install -g @anthropic-ai/claude-code

# 固化本地 Git 身份，防止 Agent 提交代码时弹窗中断
RUN git config --global user.name "Hermes AI Coder" && \
    git config --global user.email "hermes-agent@internal.ai"

# 动态点火：运行时强行写入本地代理的配置文件，选择用 Console 方式（API 模式）欺骗 CLI
CMD ["sh", "-c", "\
mkdir -p ~/.claude && \
echo '{\"mcpServers\":{}}' > ~/.claude/settings.json && \
echo '🚀 AI Sandbox full-pack scaffolding initialization completed!' && \
tail -f /dev/null \
"]
EOF

# 4. 写入 docker-compose.yml (★重点：加入 claude-proxy 服务)
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

  # 🌟 新增：free-claude-code 独立中转服务
  claude-proxy:
    image: node:22-alpine
    container_name: claude-proxy
    networks:
      - hermes-net
    ports:
      - "8081:8081"
    environment:
      - DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}
      - PORT=8081
    # 容器启动时自动拉取 free-claude-code 并作为独立后端常驻运行
    command: sh -c "git clone https://github.com/madawei2699/free-claude-code.git /proxy && cd /proxy && npm install && node server.js"
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
      # 🌟 核心：强行截断官方请求，把 Base URL 重定向到容器内部的自建代理上
      - ANTHROPIC_BASE_URL=http://claude-proxy:8081/v1
      # 这里的 Key 会通过代理传递给 DeepSeek 认证
      - ANTHROPIC_API_KEY=${DEEPSEEK_API_KEY}
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

# 5. 写入 hermes-server.js
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
                            exec(`docker exec -i claude-dev-env claude "${safePrompt} --yes"`, (err, stdout, stderr) => {
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
- LLM Gateway: Local free-claude-code proxy forwarding to DeepSeek

## 🎯 Development Rules
- ALWAYS check database connectivity using local native `psql` client before writing migration files.
- NEVER use experimental or unverified external MCP npm packages. Trust native terminal tools.
- Keep commands non-interactive; assume `--yes` for all automated scripts.
EOF

echo "===================================================="
echo "🎉 包含 free-claude-code 代理的满配完全体脚手架资产已成功在当前目录下释放！"
echo "👉 接下来请直接在 Codespaces 中运行: docker compose up -d --build"
echo "===================================================="
