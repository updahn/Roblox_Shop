const http = require('http');

const options = {
  host: '127.0.0.1',
  port: process.env.API_SERVER_PORT || 3001,
  path: '/health',
  timeout: 2000,
};

const request = http.request(options, (res) => {
  console.log(`健康检查状态码: ${res.statusCode}`);
  if (res.statusCode === 200) {
    process.exit(0);
  } else {
    process.exit(1);
  }
});

request.on('error', (err) => {
  console.log(`健康检查错误: ${err.message}`);
  process.exit(1);
});

request.end();
