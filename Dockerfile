# 最终的、所有逻辑内联的 Dockerfile
FROM mondedie/flarum:stable

# 设置时区为中国
ENV TZ=Asia/Shanghai

# 安装 netcat-openbsd，用于在启动时检查数据库连接
RUN apk add --no-cache netcat-openbsd

# 设置工作目录
WORKDIR /flarum/app

# 暴露 Flarum 运行的端口
EXPOSE 8888

# 将所有启动逻辑内联到 CMD 指令中
# 使用 sh -c 将所有命令作为一个长字符串来执行，以避免 Dockerfile 的解析问题
# 使用 printf 代替 heredoc 来创建配置文件，这更加健壮
CMD ["sh", "-c", " \
    set -e && \
    echo '=== NexusK Flarum 正在启动... ===' && \
    echo '正在等待数据库连接...' && \
    timeout=60 && counter=0 && \
    while ! nc -z \"${DB_HOST}\" 3306; do \
        counter=$((counter + 1)); \
        if [ ${counter} -ge ${timeout} ]; then \
            echo '错误：数据库连接超时！'; \
            exit 1; \
        fi; \
        echo '数据库尚未就绪，2秒后重试...'; \
        sleep 2; \
    done && \
    echo '数据库连接成功！' && \
    if [ ! -f '/flarum/app/config.php' ]; then \
        echo '检测到首次运行，正在安装 Flarum...' && \
        printf '<?php return array (\\n  \"debug\" => false,\\n  \"database\" =>\\n  array (\\n    \"driver\" => \"mysql\",\\n    \"host\" => \"%s\",\\n    \"port\" => 3306,\\n    \"database\" => \"%s\",\\n    \"username\" => \"%s\",\\n    \"password\" => \"%s\",\\n    \"charset\" => \"utf8mb4\",\\n    \"collation\" => \"utf8mb4_unicode_ci\",\\n    \"prefix\" => \"flarum_\",\\n    \"strict\" => false,\\n    \"engine\" => \"InnoDB\",\\n    \"prefix_indexes\" => true,\\n  ),\\n  \"url\" => \"%s\",\\n  \"paths\" =>\\n  array (\\n    \"api\" => \"api\",\\n    \"admin\" => \"admin\",\\n  ),\\n);' \"$DB_HOST\" \"$DB_NAME\" \"$DB_USER\" \"$DB_PASS\" \"$FORUM_URL\" > /flarum/app/config.php && \
        echo 'config.php 创建成功。' && \
        php flarum migrate --force && \
        php flarum install --defaults --admin-user=\"${FLARUM_ADMIN_USER}\" --admin-pass=\"${FLARUM_ADMIN_PASS}\" --admin-email=\"${FLARUM_ADMIN_MAIL}\" --title=\"${FLARUM_TITLE}\" && \
        echo 'Flarum 安装完成！'; \
    fi && \
    echo '正在清理缓存...' && \
    php flarum cache:clear && \
    echo '启动 Flarum 服务...' && \
    exec php flarum serve --host=0.0.0.0 --port=8888 \
"]