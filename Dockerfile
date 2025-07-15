# 最简单的 Dockerfile
FROM mondedie/flarum:stable

# 设置时区为中国
ENV TZ=Asia/Shanghai

# 安装 netcat
RUN apk add --no-cache netcat-openbsd

# 设置工作目录
WORKDIR /flarum/app

# 暴露端口
EXPOSE 8888

# 直接在 CMD 中写启动逻辑
CMD ["sh", "-c", "\
echo '=== NexusK 论坛启动中 ===' && \
echo '等待数据库连接...' && \
timeout=60 && counter=0 && \
while ! nc -z $DB_HOST 3306 && [ $counter -lt $timeout ]; do \
  echo '数据库未就绪，等待中...' && \
  sleep 2 && \
  counter=$((counter + 1)); \
done && \
if [ $counter -eq $timeout ]; then \
  echo '数据库连接超时！' && exit 1; \
fi && \
echo '数据库连接成功！' && \
if [ ! -f '/flarum/app/config.php' ]; then \
  echo '首次安装 Flarum...' && \
  cat > /flarum/app/config.php << 'EOF'
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
  && php flarum migrate --force && \
  php flarum install --defaults --admin-user=$FLARUM_ADMIN_USER --admin-pass=$FLARUM_ADMIN_PASS --admin-email=$FLARUM_ADMIN_MAIL --title='$FLARUM_TITLE'; \
fi && \
php flarum cache:clear && \
php flarum serve --host=0.0.0.0 --port=8888 \
"]