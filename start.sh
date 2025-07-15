#!/bin/bash

echo "=== NexusK 论坛启动中 ==="

# 设置错误处理
set -e

# 等待数据库连接就绪
echo "等待数据库连接..."
timeout=120
counter=0

while ! nc -z $DB_HOST 3306 && [ $counter -lt $timeout ]; do
  echo "数据库未就绪，等待中... ($counter/$timeout 秒)"
  sleep 2
  counter=$((counter + 2))
done

if [ $counter -ge $timeout ]; then
  echo "❌ 数据库连接超时！"
  exit 1
fi

echo "✅ 数据库连接成功！"

# 确保目录存在
mkdir -p /flarum/app/storage/logs
mkdir -p /flarum/app/storage/cache
mkdir -p /flarum/app/storage/sessions

# 设置权限
chown -R www-data:www-data /flarum/app/storage

# 检查是否首次安装
if [ ! -f "/flarum/app/config.php" ]; then
  echo "🚀 首次安装 Flarum..."

  # 创建基础配置文件
  cat > /flarum/app/config.php << EOF
<?php return array (
  'debug' => false,
  'database' => array (
    'driver' => 'mysql',
    'host' => '$DB_HOST',
    'port' => 3306,
    'database' => '$DB_NAME',
    'username' => '$DB_USER',
    'password' => '$DB_PASS',
    'charset' => 'utf8mb4',
    'collation' => 'utf8mb4_unicode_ci',
    'prefix' => 'flarum_',
    'strict' => false,
    'engine' => 'InnoDB',
    'prefix_indexes' => true,
  ),
  'url' => '$FORUM_URL',
  'paths' => array (
    'api' => 'api',
    'admin' => 'admin',
  ),
);
EOF

  # 运行数据库迁移和安装
  echo "📦 初始化数据库..."
  php flarum migrate --force

  echo "👤 创建管理员用户..."
  php flarum admin:create \
    --username="$FLARUM_ADMIN_USER" \
    --password="$FLARUM_ADMIN_PASS" \
    --email="$FLARUM_ADMIN_MAIL"

  # 设置论坛标题
  echo "🎯 设置论坛标题..."
  php flarum config:set forum_title "$FLARUM_TITLE"

  echo "✅ Flarum 安装完成！"
else
  echo "🔄 Flarum 已存在，直接启动..."
fi

# 更新配置文件中的 URL（防止域名变更）
sed -i "s|'url' => '.*'|'url' => '$FORUM_URL'|g" /flarum/app/config.php

# 清理缓存
echo "🧹 清理缓存..."
php flarum cache:clear

# 启动 Flarum
echo "🚀 启动 NexusK 论坛服务..."
exec php flarum serve --host=0.0.0.0 --port=8888