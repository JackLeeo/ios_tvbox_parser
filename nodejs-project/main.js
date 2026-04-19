const bridge = require('flutter-bridge');
const fs = require('fs');
const path = require('path');

const drpyPath = path.join(__dirname, 'drpy2.min.js');
if (fs.existsSync(drpyPath)) {
  require(drpyPath);
}

bridge.on('parse', (msg) => {
  try {
    const { requestId, action, payload } = JSON.parse(msg);
    let result;
    switch (action) {
      case 'home': result = global.drpyHome ? global.drpyHome(payload.rule, payload.page) : { list: [] }; break;
      case 'search': result = global.drpySearch ? global.drpySearch(payload.rule, payload.keyword, payload.page) : { list: [] }; break;
      case 'detail': result = global.drpyDetail ? global.drpyDetail(payload.rule, payload.url) : { list: [] }; break;
      case 'play': result = global.drpyPlay ? global.drpyPlay(payload.rule, payload.flag, payload.id) : { url: '' }; break;
    }
    bridge.send('parse_result', JSON.stringify({ requestId, data: result }));
  } catch (e) {
    bridge.send('parse_error', JSON.stringify({ requestId, error: e.message }));
  }
});
bridge.send('node_ready', 'ok');
