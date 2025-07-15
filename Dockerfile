FROM mondedie/flarum:stable

# 设置时区
ENV TZ=Asia/Shanghai

# 安装必要工具
RUN apk add --no-cache netcat-openbsd

WORKDIR /flarum/app

# 暴露端口
EXPOSE 8888

# 创建最简单的启动脚本
RUN cat > /start.sh << 'EOF'
#!/bin/sh
set -e

echo "=== 简化启动 NexusK Forum ==="

# 等待数据库
echo "检查数据库连接..."
while ! nc -z "$DB_HOST" "$DB_PORT"; do
    echo "等待数据库..."
    sleep 3
done
echo "数据库连接成功！"

# 删除旧配置，让Flarum重新安装
rm -f /flarum/app/config.php
echo "准备安装页面..."

# 启动服务
echo "启动论坛..."
cd /flarum/app/public
exec php -S 0.0.0.0:8888 -t .
EOF

RUN chmod +x /start.sh

CMD ["/start.sh"]