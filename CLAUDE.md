# 🛠️ Hermes AI Factory Project Guide

## ⚙️ Environment Constraints
- Node Version: 22 (Debian Bookworm)
- Database: PostgreSQL 16 (Host: postgres-db, Port: 5432, User: postgres, DB: app_prod)
- Headless Browser: Browserless Chrome (Host: chrome-headless, Port: 3000)

## 🎯 Development Rules
- ALWAYS check database connectivity using local native `psql` client before writing migration files.
- NEVER use experimental or unverified external MCP npm packages. Trust native terminal tools.
- Keep commands non-interactive; assume `--yes` for all automated scripts.
