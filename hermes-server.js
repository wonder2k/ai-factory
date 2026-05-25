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
