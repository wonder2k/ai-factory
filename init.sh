#!/bin/bash

# ==============================================================================
# 🚀 Hermes AI Factory - 纯净环境版脚手架 (Docker 全栈 + 宿主自适应解耦)
# ==============================================================================

set -e

# 确保所有文件精准生成在当前运行脚本的根目录下，绝对不会多套一层文件夹
BASE_DIR=$(pwd)

echo "===================================================="
echo "🌱 开始从零释放【半自动满配版】AI Factory 全套核心配置文件..."
echo "📂 当前工作区绝对路径: $BASE_DIR"
echo "===================================================="

# 1. 建立标准的完全体目录结构
mkdir -p "$BASE_DIR/docker"
mkdir -p "$BASE_DIR/.devcontainer"

# 2. 写入 .devcontainer/devcontainer.json
cat << 'EOF' > "$BASE_DIR/.devcontainer/devcontainer.json"
{
    "name": "Hermes AI Factory Workspace",
    "dockerComposeFile": "../docker-compose.yml",
    "service": "claude-dev-env",
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

# 3. 写入 docker/Dockerfile.claude (只做干净的环境准备和软链接打通)
cat << 'EOF' > "$BASE_DIR/docker/Dockerfile.claude"
FROM node:22-bookworm

# 安装全套底层构建链、原生 PostgreSQL 客户端以及基础设施工具
RUN apt-get update && apt-get install -y \
    git \
    bash \
    openssh-client \
    build-essential \
    python3 \
    postgresql-client \
    curl \
    nano \
    procps \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# A. 全局安装官方核心工兵组件
RUN npm install -g @anthropic-ai/claude-code

# B. 通过官方脚本一键安装 free-claude-code 体系
RUN curl -fsSL "https://github.com/Alishahryar1/free-claude-code/blob/main/scripts/install.sh?raw=1" | sh

# C. 物理级打通 fcc 核心二进制文件的系统全局环境变量路径
RUN ln -s /root/.local/bin/fcc-server /usr/local/bin/fcc-server && \
    ln -s /root/.local/bin/fcc-claude /usr/local/bin/fcc-claude && \
    ln -s /root/.local/bin/fcc-init /usr/local/bin/fcc-init

# 固化本地 Git 身份
RUN git config --global user.name "Hermes AI Coder" && \
    git config --global user.email "hermes-agent@internal.ai"

# D. 容器启动：只做 fcc 代理后台拉起和 Telegram 轮询大脑起飞，不干扰用户的插件沙箱
CMD ["sh", "-c", "\
echo '⚙️  1. 执行 fcc-init 基础检测...' && \
fcc-init || true && \
echo '🚀 2. 正在常驻守护拉起 fcc-server 代理...' && \
nohup fcc-server > /tmp/fcc.log 2>&1 & \
sleep 2 && \
echo '🧠 3. 原地唤醒 Telegram 总控大脑，全面进入长轮询监听...' && \
node /workspace/hermes-server.js \
"]
EOF

# 4. 写入 docker-compose.yml
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
      - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
    restart: always
EOF

# 5. 写入 hermes-server.js
cat << 'EOF' > "$BASE_DIR/hermes-server.js"
const { exec } = require('child_process');
const https = require('https');

const TOKEN = process.env.TELEGRAM_BOT_TOKEN;
if (!TOKEN) {
    console.error("❌ Error: TELEGRAM_BOT_TOKEN is missing in environment!");
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
                            const chatId = update.message.chat.id || update.message.chat_id || update.message.from.id;
                            const userPrompt = update.message.text;

                            console.log(`📩 收到电报指令: ${userPrompt}`);
                            sendMessage(chatId, `🚀 Hermes 收到指令，正在唤醒工兵执行，请稍候...`);

                            const safePrompt = userPrompt.replace(/"/g, '\\"');
                            
                            setTimeout(() => {
                                exec(`fcc-claude "${safePrompt} --yes"`, (err, stdout, stderr) => {
                                    const output = stdout || stderr || "执行完毕，无控制台输出。";
                                    sendMessage(chatId, `✅ **Claude 执行战果汇报：**\n\n${output}`);
                                });
                            }, 50);
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

console.log("🚀 Hermes 总控大脑已点火，正在丝滑监听 Telegram 消息...");
pollUpdates();
EOF

# 6. 写入 CLAUDE.md
echo "📝 正在生成富有 Karpathy 铁律约束的 CLAUDE.md ..."
echo "# 🛠️ Hermes AI Factory Project Guide & Rules" > "$BASE_DIR/CLAUDE.md"
echo "" >> "$BASE_DIR/CLAUDE.md"
echo "## ⚙️ Environment Constraints" >> "$BASE_DIR/CLAUDE.md"
echo "- Node Version: 22 (Debian Bookworm)" >> "$BASE_DIR/CLAUDE.md"
echo "- Database: PostgreSQL 16 (Host: postgres-db, Port: 5432, User: postgres, DB: app_prod)" >> "$BASE_DIR/CLAUDE.md"
echo "- Headless Browser: Browserless Chrome (Host: chrome-headless, Port: 3000)" >> "$BASE_DIR/CLAUDE.md"
echo "- Proxy CLI Wrapper: free-claude-code (fcc-server, fcc-claude) forwarding to DeepSeek Flash" >> "$BASE_DIR/CLAUDE.md"
echo "" >> "$BASE_DIR/CLAUDE.md"
echo "## 🧠 Karpathy AI Programming Principles (Strictly Enforced)" >> "$BASE_DIR/CLAUDE.md"
echo "" >> "$BASE_DIR/CLAUDE.md"
echo "### 1. 先思考后编码 (Think Before Coding)" >> "$BASE_DIR/CLAUDE.md"
echo "- **不要假设**：有任何不确定的业务逻辑或系统设计，先停下来提问澄清，禁止盲目盲盒式编写。" >> "$BASE_DIR/CLAUDE.md"
echo "- **呈现权衡**：在修改前，如果存在多种技术选型，必须在终端/日志中显式陈述每种方法的利弊和隐私影响。" >> "$>> "$BASE_DIR/CLAUDE.md"
echo "- **遇到困惑立即停止**：如果发现上下文或已有代码逻辑不明，停止执行，并报告不清楚的地方。" >> "$BASE_DIR/CLAUDE.md"
echo "" >> "$BASE_DIR/CLAUDE.md"
echo "### 2. 简洁优先 (Simplicity First)" >> "$BASE_DIR/CLAUDE.md"
echo "- **只解决当下问题**：严禁添加任何“未来可能用到”的未请求功能、配置项、或可扩展性抽象。" >> "$BASE_DIR/CLAUDE.md"
echo "- **杜绝过度工程**：如果一段逻辑能用最简单的 20 行原生代码讲清楚，严禁引入复杂的第三方类库或大型设计模式。如果代码写得复杂了，立刻重写简化。" >> "$BASE_DIR/CLAUDE.md"
echo "" >> "$BASE_DIR/CLAUDE.md"
echo "### 3. 精准修改 (Precision Modifying)" >> "$BASE_DIR/CLAUDE.md"
echo "- **只碰必须碰的文件**：改动范围必须维持在实现目标所需的最小子集，严禁顺手去“改进、美化或重构”相邻的、没坏的旧代码。" >> "$BASE_DIR/CLAUDE.md"
echo "- **匹配现有风格**：编写的代码风格必须与当前文件已有编码风格保持 100% 绝对一致，哪怕你有更喜欢的写法。" >> "$BASE_DIR/CLAUDE.md"
echo "- **孤儿代码清理**：只清理因本次修改而直接导致失效的无效 import、变量或函数，严禁删除预先存在的死代码（除非被明确要求）。" >> "$BASE_DIR/CLAUDE.md"
echo "" >> "$BASE_DIR/CLAUDE.md"
echo "### 4. 目标驱动与验证 (Objective-Driven & Testable)" >> "$BASE_DIR/CLAUDE.md"
echo "- **可直接追踪**：每一行修改都必须能直接追溯到用户的原始请求目的。" >> "$BASE_DIR/CLAUDE.md"
echo "- **优先非交互式确认**：在脚本自动化流转中，命令默认追加 \`--yes\`，确保每一步的改动具有明确的可预测性和闭环验证。" >> "$BASE_DIR/CLAUDE.md"

echo "===================================================="
echo "🎉 环境级脚手架生成完毕！接下来请查看项目 README.md 引导完成 30 秒手工对齐。"
echo "===================================================="
