FROM mondedie/flarum:stable

# 设置时区为中国
ENV TZ=Asia/Shanghai

# 安装 netcat 用于检查数据库连接
RUN apk add --no-cache netcat-openbsd

# 设置工作目录
WORKDIR /flarum/app

# 暴露 Flarum 运行的端口
EXPOSE 8888

# 创建启动脚本
RUN cat > /start.sh << 'EOF'
#!/bin/sh
set -e

# 设置默认端口
DB_PORT=${DB_PORT:-3306}

echo "=== NexusK Flarum 正在启动... ==="
echo "数据库主机: ${DB_HOST}"
echo "数据库端口: ${DB_PORT}"

# 等待数据库连接
echo "正在等待 MySQL 数据库连接..."
timeout=180
counter=0
while ! nc -z "${DB_HOST}" "${DB_PORT}"; do
    counter=$((counter + 1))
    if [ ${counter} -ge ${timeout} ]; then
        echo "错误：数据库连接超时！请检查数据库状态和网络设置。"
        exit 1
    fi
    echo "数据库尚未就绪，5秒后重试..."
    sleep 5
done
echo "数据库连接成功！"

# 检查是否已安装
if [ ! -f "/flarum/app/config.php" ]; then
    echo "检测到首次运行，正在安装 Flarum..."

    # 创建配置文件
    cat > /flarum/app/config.php << CONFIG_EOF
<?php return array (
  'debug' => false,
  'database' =>
  array (
    'driver' => 'mysql',
    'host' => '${DB_HOST}',
    'port' => ${DB_PORT},
    'database' => '${DB_NAME}',
    'username' => '${DB_USER}',
    'password' => '${DB_PASS}',
    'charset' => 'utf8mb4',
    'collation' => 'utf8mb4_unicode_ci',
    'prefix' => 'flarum_',
    'strict' => false,
    'engine' => 'InnoDB',
    'prefix_indexes' => true,
  ),
  'url' => '${FORUM_URL}',
  'paths' =>
  array (
    'api' => 'api',
    'admin' => 'admin',
  ),
);
CONFIG_EOF

    echo "config.php 创建成功。"

    # 运行安装命令
    echo "正在运行 Flarum 安装..."
    php flarum install \
        --defaults \
        --admin-user="${FLARUM_ADMIN_USER}" \
        --admin-pass="${FLARUM_ADMIN_PASS}" \
        --admin-email="${FLARUM_ADMIN_MAIL}" \
        --title="${FLARUM_TITLE}"

    if [ $? -eq 0 ]; then
        echo "Flarum 安装完成！"
    else
        echo "Flarum 安装失败！"
        exit 1
    fi
else
    echo "检测到已有配置文件，跳过安装步骤。"
fi

# 清理缓存
echo "正在清理缓存..."
php flarum cache:clear

# 启动服务
echo "启动 Flarum 服务..."
exec php flarum serve --host=0.0.0.0 --port=8888
EOF

# 设置脚本权限
RUN chmod +x /start.sh

# 使用脚本启动
CMD ["/start.sh"]