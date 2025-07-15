# Dockerfile
FROM mondedie/flarum:1.8-stable

# 设置时区为中国
ENV TZ=Asia/Shanghai

# 创建启动脚本
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 暴露端口
EXPOSE 8888

# 启动命令
CMD ["/start.sh"]