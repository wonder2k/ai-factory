# 🛠️ Hermes AI Factory - 项目架构指南与部署手册

欢迎来到 **Hermes AI Factory (埃尔梅斯智能软件工厂)**。本项目是一个基于 GitHub Codespaces 云端沙箱构建的、无人值守、大闭环全栈 AI 开发工厂。通过将 Telegram 总控、DeepSeek 白嫖算力代理以及包含 10 大官方神级外挂的 Claude Code 容器紧密糅合，实现随时随地用手机遥控完成工业级全栈代码编写。

---

## 🏗️ 1. 系统架构设计

系统采用**「单体宿主，三位一体」**的去中心化解耦架构，彻底去除了复杂的跨容器多路中转套娃。

 📲 [手机端 Telegram Bot]
           │ (HTTPS 长轮询)
           ▼
┌────────────────── 🐳 claude-dev-env 容器 ──────────────────┐
│                                                            │
│  🧠 [Hermes-Server] ──── (原地单进程调度) ────► [fcc-claude] │
│          ▲                                         │       │
│          │ (Localhost 转发)                        │       │
│          ▼                                         ▼       │
│    [fcc-server 代理后端] ◄───────► [DeepSeek v4 Flash 算力] │
│                                                            │
└────────────────────────────────────────────────────────────┘
│                                             │
▼ (内网桥接)                                   ▼ (内网桥接)
🐳 [postgres-db 数据库]                       🐳 [chrome-headless 浏览器]


* **合体大脑 (`claude-dev-env`)**：既是接收 Telegram 信号的总控台，又是执行底层 `fcc-claude` 编译的特种兵沙箱。由于在同一容器内，彻底根治了 `docker: not found` 隐患。
* **白嫖中转层 (`free-claude-code`)**：在容器内启动本地 `fcc-server` 拦截所有 Anthropic 官方的计费请求，并以完全符合合规和性能约束的方式无缝转换为 DeepSeek v4 Flash 极速推理算力。
* **外部拓扑环境**：容器内桥接了 `postgres-db`（数据读写）与 `chrome-headless`（利用 Playwright 进行网页爬取、截图和 E2E 自动化测试）。

---

## 🛠️ 2. 部署与冷启动办法

### 步骤 1：清空历史积压
在你的 Codespaces 宿主终端，确保将除 `init.sh` 之外的套娃残留清理干净：
```bash
# 强杀所有可能残留的后台幽灵监听
docker rm -f claude-dev-env postgres-db chrome-headless hermes-agent-center 2>/dev/null || true
步骤 2：在宿主机注入生产环境变量
在宿主机环境中直接声明保护密钥（记得替换为你的真实配置）：

Bash
export DEEPSEEK_API_KEY="你的真实DeepSeek-Key"
export TELEGRAM_BOT_TOKEN="你的真实电报Bot-Token"
步骤 3：脚手架释放与一键点火
Bash
chmod +x init.sh && ./init.sh
docker compose up -d --build
🔑 3. 首次手工初始化与 10 大插件激活 (30秒肉身通关)
由于新版 claude-code 对交互式会话有极强的沙箱验证和元数据保护，在容器编译完成后，必须进去进行一次性的人工初始化。

步骤 1：物理切入工兵容器内
Bash
docker exec -it claude-dev-env /bin/bash
步骤 2：对 free-claude-code 框架进行密钥最终核对
在容器提示符 root@xxxx:/workspace# 下运行：

Bash
# 1. 强制重置并生成 fcc 的基础配置文件
fcc-init

# 2. 强行将宿主机的密钥精准灌入它的本地环境
echo "DEEPSEEK_API_KEY=\"${DEEPSEEK_API_KEY}\"" > ~/.fcc/.env
echo "MODEL=\"deepseek/deepseek-v4-flash\"" >> ~/.fcc/.env
echo "ANTHROPIC_AUTH_TOKEN=\"freecc\"" >> ~/.fcc/.env
步骤 3：在前台启动 fcc-claude 并一键收割 10 大核心外挂
在容器内输入命令切入大模型交互区：

Bash
fcc-claude
此时你已经进入了 claude> 的命令等待区。直接复制并回车以下官方指令：

Plaintext
/plugin install claude-code-setup claude-md-management code-review code-simplifier context7 feature-dev frontend-design playwright superpowers security-guidance
交互提示：当它弹出来问你是否同意下载或者跳出确认提示时，一路按 y 并回车同意！

看到控制台全部打出 ✔ Successfully installed 并且出现全绿的插件成功列表表格后，输入 /exit 优雅退出大模型会话。

步骤 4：重启总控大脑，宣告无瑕通车！
完成插件激活后，我们在容器内一键重启总控大脑，让它读取到你刚刚肉身通关生成的最纯净、最具有官方元数据锁的插件环境：

Bash
# 1. 杀死旧的大脑
pkill -f node || true

# 2. 让完全体长轮询监听常驻后台
nohup node /workspace/hermes-server.js > /tmp/hermes.log 2>&1 &

# 3. 优雅退出容器，大功告成！
exit
🧠 4. 严苛执行的 Karpathy AI 编程铁律
本项目在根目录强制锁定了 CLAUDE.md 规范。无论你在 Telegram 发送什么指令，工兵在调用 DeepSeek 进行重构时，都将死死遵守以下四大准则：

先思考后编码 (Think Before Coding)：拒绝假设，遇到困惑或冲突的设计，立刻在汇报中终止并提问。

简洁优先 (Simplicity First)：只解决当下问题。能用 20 行原生代码解决的，严禁引入复杂的第三方过度工程设计。

精准修改 (Precision Modifying)：只触碰为了完成目标所必需的最小文件子集，严禁顺手去美化或改进相邻的、没坏的代码。

目标驱动与验证 (Objective-Driven)：每一行改动必须能完全追溯到用户的 Telegram 原始输入。


---

这一套“**全栈 Docker 化 + 30秒人工对齐插件**”的方案是极客圈和工业界无数次踩坑后的最终归宿。去按这个新流程冷启动跑一次吧，享受属于你的满配、
