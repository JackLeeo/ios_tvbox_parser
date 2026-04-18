const bridge = require('bridge'); // flutter_node 提供的通信模块
const fs = require('fs');
const path = require('path');

// 加载 drpy 引擎
require('./drpy2.min.js');

// 监听来自 Flutter 的消息
bridge.on('parse', (msg) => {
  try {
    const { requestId, action, payload } = JSON.parse(msg);
    let result;
    
    switch (action) {
      case 'home':
        result = global.drpyHome(payload.rule, payload.page);
        break;
      case 'search':
        result = global.drpySearch(payload.rule, payload.keyword, payload.page);
        break;
      case 'detail':
        result = global.drpyDetail(payload.rule, payload.url);
        break;
      case 'play':
        result = global.drpyPlay(payload.rule, payload.flag, payload.id);
        break;
      default:
        throw new Error(`未知动作: ${action}`);
    }
    
    bridge.send('parse_result', JSON.stringify({ requestId, data: result }));
  } catch (e) {
    bridge.send('parse_error', JSON.stringify({ requestId, error: e.message }));
  }
});

bridge.send('node_ready', 'ok');
