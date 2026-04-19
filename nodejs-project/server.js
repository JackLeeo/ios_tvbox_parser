const http = require('http');
const fs = require('fs');
const path = require('path');

// 加载 drpy2 引擎
const drpyPath = path.join(__dirname, 'drpy2.min.js');
if (fs.existsSync(drpyPath)) {
  require(drpyPath);
  console.log('drpy2.min.js loaded');
} else {
  console.error('drpy2.min.js not found');
}

// 创建 HTTP 服务器
const server = http.createServer((req, res) => {
  // 设置 CORS 头，允许 Flutter 访问
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // 只处理 POST 请求到 /parse
  if (req.method === 'POST' && req.url === '/parse') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const { action, payload } = JSON.parse(body);
        let result;
        switch (action) {
          case 'home':
            result = global.drpyHome ? global.drpyHome(payload.rule, payload.page) : { list: [] };
            break;
          case 'search':
            result = global.drpySearch ? global.drpySearch(payload.rule, payload.keyword, payload.page) : { list: [] };
            break;
          case 'detail':
            result = global.drpyDetail ? global.drpyDetail(payload.rule, payload.url) : { list: [] };
            break;
          case 'play':
            result = global.drpyPlay ? global.drpyPlay(payload.rule, payload.flag, payload.id) : { url: '' };
            break;
          default:
            throw new Error(`Unknown action: ${action}`);
        }
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ code: 200, data: result }));
      } catch (e) {
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ code: 500, error: e.message }));
      }
    });
  } else {
    res.writeHead(404);
    res.end();
  }
});

const PORT = 8765;
server.listen(PORT, '127.0.0.1', () => {
  console.log(`HTTP server running at http://127.0.0.1:${PORT}`);
});

// 向 Flutter 发送就绪信号（通过标准输出，Flutter 可以读取）
console.log('NODE_READY');
