# 修正的 Dockerfile
FROM mondedie/flarum:stable

# 设置时区为中国
ENV TZ=Asia/Shanghai

# 安装 netcat 用于数据库连接检测
RUN apk add --no-cache netcat-openbsd

# 创建启动脚本
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 设置工作目录
WORKDIR /flarum/app

# 暴露端口
EXPOSE 8888

# 启动命令
CMD ["/start.sh"]