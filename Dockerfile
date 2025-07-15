FROM mondedie/flarum:stable

# 设置时区为中国
ENV TZ=Asia/Shanghai

# 安装 netcat 用于检查数据库连接
RUN apk add --no-cache netcat-openbsd

# 设置工作目录
WORKDIR /flarum/app

# 暴露 Flarum 运行的端口
EXPOSE 8888

# 将所有启动逻辑内联到一行 CMD 指令中，这是解决解析器错误的最终尝试
CMD ["sh", "-c", "set -e && DB_PORT=${DB_PORT:-3306} && echo '=== NexusK Flarum 正在启动... ===' && echo \"数据库主机: ${DB_HOST}\" && echo \"数据库端口: ${DB_PORT}\" && echo '正在等待 MySQL 数据库连接...' && timeout=180 && counter=0 && while ! nc -z \"${DB_HOST}\" \"${DB_PORT}\"; do counter=$((counter + 1)); if [ ${counter} -ge ${timeout} ]; then echo '错误：数据库连接超时！请检查数据库状态和网络设置。'; exit 1; fi; echo '数据库尚未就绪，5秒后重试...'; sleep 5; done && echo '数据库连接成功！' && if [ ! -f '/flarum/app/config.php' ]; then echo '检测到首次运行，正在安装 Flarum...' && printf '<?php return array (\\n  \"debug\" => false,\\n  \"database\" =>\\n  array (\\n    \"driver\" => \"mysql\",\\n    \"host\" => \"%s\",\\n    \"port\" => %d,\\n    \"database\" => \"%s\",\\n    \"username\" => \"%s\",\\n    \"password\" => \"%s\",\\n    \"charset\" => \"utf8mb4\",\\n    \"collation\" => \"utf8mb4_unicode_ci\",\\n    \"prefix\" => \"flarum_\",\\n    \"strict\" => false,\\n    \"engine\" => \"InnoDB\",\\n    \"prefix_indexes\" => true,\\n  ),\\n  \"url\" => \"%s\",\\n  \"paths\" =>\\n  array (\\n    \"api\" => \"api\",\\n    \"admin\" => \"admin\",\\n  ),\\n);' \"$DB_HOST\" $DB_PORT \"$DB_NAME\" \"$DB_USER\" \"$DB_PASS\" \"$FORUM_URL\" > /flarum/app/config.php && echo 'config.php 创建成功。' && php flarum install --defaults --admin-user=\"${FLARUM_ADMIN_USER}\" --admin-pass=\"${FLARUM_ADMIN_PASS}\" --admin-email=\"${FLARUM_ADMIN_MAIL}\" --title=\"${FLARUM_TITLE}\" && echo 'Flarum 安装完成！'; fi && echo '正在清理缓存...' && php flarum cache:clear && echo '启动 Flarum 服务...' && exec php flarum serve --host=0.0.0.0 --port=8888"]
