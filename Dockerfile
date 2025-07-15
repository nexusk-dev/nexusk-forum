FROM mondedie/flarum:stable

# 设置时区
ENV TZ=Asia/Shanghai

# 安装netcat检查数据库连接
RUN apk add --no-cache netcat-openbsd

WORKDIR /flarum/app

# 暴露端口（Render会自动绑定到环境变量PORT）
EXPOSE 8888

# 创建简单的启动脚本
RUN cat > /start.sh << 'EOF'
#!/bin/sh
set -e

# 等待数据库连接
echo "等待数据库连接..."
while ! nc -z "${DB_HOST}" "${DB_PORT:-3306}"; do
    echo "数据库未就绪，等待中..."
    sleep 3
done
echo "数据库连接成功！"

# 创建配置文件
if [ ! -f "/flarum/app/config.php" ]; then
    echo "创建配置文件..."
    cat > /flarum/app/config.php << PHPEOF
<?php return [
    'debug' => false,
    'database' => [
        'driver' => 'mysql',
        'host' => '${DB_HOST}',
        'port' => ${DB_PORT:-3306},
        'database' => '${DB_NAME}',
        'username' => '${DB_USER}',
        'password' => '${DB_PASS}',
        'charset' => 'utf8mb4',
        'collation' => 'utf8mb4_unicode_ci',
        'prefix' => 'flarum_',
        'strict' => false,
        'engine' => 'InnoDB',
        'prefix_indexes' => true,
    ],
    'url' => '${FORUM_URL}',
    'paths' => [
        'api' => 'api',
        'admin' => 'admin',
    ],
];
PHPEOF
    echo "配置文件创建完成"
fi

# 清理缓存
echo "清理缓存..."
php flarum cache:clear

# 启动服务
echo "启动论坛服务..."
cd /flarum/app/public
exec php -S 0.0.0.0:8888 -t .
EOF

RUN chmod +x /start.sh

CMD ["/start.sh"]