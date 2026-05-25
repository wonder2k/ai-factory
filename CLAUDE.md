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
- **杜绝过度工程**：如果一段逻辑能用最简单的 20 行原生代码讲清楚，严禁引入复杂的第三方类库或大型设计模式。如果代码写得复杂了，立刻重写简化。

### 3. 精准修改 (Precision Modifying)
- **只碰必须碰的文件**：改动范围必须维持在实现目标所需的最小子集，严禁顺手去“改进、美化或重构”相邻的、没坏的旧代码。
- **匹配现有风格**：编写的代码风格必须与当前文件已有编码风格保持 100% 绝对一致，哪怕你有更喜欢的写法。
- **孤儿代码清理**：只清理因本次修改而直接导致失效的无效 import、变量或函数，严禁删除预先存在的死代码（除非被明确要求）。

### 4. 目标驱动与验证 (Objective-Driven & Testable)
- **可直接追踪**：每一行修改都必须能直接追溯到用户的原始请求目的。
- **优先非交互式确认**：在脚本自动化流转中，命令默认追加 `--yes`，确保每一步的改动具有明确的可预测性和闭环验证。
