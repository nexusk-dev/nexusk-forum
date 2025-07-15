# start.sh
#!/bin/bash

echo "=== Flarum 论坛启动中 ==="

# 等待数据库连接就绪
echo "等待数据库连接..."
timeout=60
counter=0

while ! nc -z $DB_HOST 3306 && [ $counter -lt $timeout ]; do
  echo "数据库未就绪，等待中... ($counter/$timeout)"
  sleep 2
  counter=$((counter + 1))
done

if [ $counter -eq $timeout ]; then
  echo "数据库连接超时！"
  exit 1
fi

echo "数据库连接成功！"

# 检查是否首次安装
if [ ! -f "/flarum/app/config.php" ]; then
  echo "首次安装 Flarum..."

  # 创建配置文件
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

  # 运行数据库迁移
  echo "初始化数据库..."
  php flarum migrate --force

  # 创建管理员用户
  echo "创建管理员用户..."
  php flarum install \
    --defaults \
    --admin-user="$FLARUM_ADMIN_USER" \
    --admin-pass="$FLARUM_ADMIN_PASS" \
    --admin-email="$FLARUM_ADMIN_MAIL" \
    --title="$FLARUM_TITLE"

  echo "Flarum 安装完成！"
else
  echo "Flarum 已安装，直接启动..."
fi

# 清理缓存
echo "清理缓存..."
php flarum cache:clear

# 启动 Flarum
echo "启动 Flarum 服务..."
php flarum serve --host=0.0.0.0 --port=8888