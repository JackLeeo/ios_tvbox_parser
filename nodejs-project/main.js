const bridge = require('flutter-bridge'); // 注意：node_flutter 使用 'flutter-bridge'
const fs = require('fs');
const path = require('path');

const drpyPath = path.join(__dirname, 'drpy2.min.js');
if (fs.existsSync(drpyPath)) {
  require(drpyPath);
  console.log('drpy2.min.js loaded');
} else {
  console.error('drpy2.min.js not found');
}

bridge.on('parse', (msg) => {
  try {
    const { requestId, action, payload } = typeof msg === 'string' ? JSON.parse(msg) : msg;
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
    
    bridge.send('parse_result', JSON.stringify({ requestId, data: result }));
  } catch (e) {
    bridge.send('parse_error', JSON.stringify({ requestId, error: e.message }));
  }
});

bridge.send('node_ready', 'ok');
