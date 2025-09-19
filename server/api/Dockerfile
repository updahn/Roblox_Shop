FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 复制 package.json (如果存在 package-lock.json 也会复制)
COPY package*.json ./

# 安装依赖 (生产环境)
RUN npm install --omit=dev

# 创建非root用户
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodeuser -u 1001

# 复制应用代码
COPY . .

# 创建日志目录
RUN mkdir -p logs && chown -R nodeuser:nodejs logs

# 切换到非root用户
USER nodeuser

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

# 暴露端口
EXPOSE 3001

# 启动应用
CMD ["node", "index.js"]
