# 🛠️ Hermes AI Factory Project Guide & Rules

## ⚙️ Environment Constraints
- Node Version: 22 (Debian Bookworm)
- Database: PostgreSQL 16 (Host: postgres-db, Port: 5432, User: postgres, DB: app_prod)
- Headless Browser: Browserless Chrome (Host: chrome-headless, Port: 3000)
- Proxy CLI Wrapper: free-claude-code (fcc-server, fcc-claude) forwarding to DeepSeek Flash

## 🧠 Karpathy AI Programming Principles (Strictly Enforced)

### 1. 先思考后编码 (Think Before Coding)
- **不要假设**：有任何不确定的业务逻辑或系统设计，先停下来提问澄清，禁止盲目盲盒式编写。
- **呈现权衡**：在修改前，如果存在多种技术选型，必须在终端/日志中显式陈述每种方法的利弊和隐私影响。
- **遇到困惑立即停止**：如果发现上下文或已有代码逻辑不明，停止执行，并报告不清楚的地方。

### 2. 简洁优先 (Simplicity First)
- **只解决当下问题**：严禁添加任何“未来可能用到”的未请求功能、配置项、或可扩展性抽象。
- **杜绝过度工程**：如果一段逻辑能用最简单的 20 行原生代码讲清楚，严禁引入复杂的第方三类库或大型设计模式。如果代码写得复杂了，立刻
