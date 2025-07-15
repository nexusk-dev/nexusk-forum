FROM mondedie/flarum:stable

# 设置时区
ENV TZ=Asia/Shanghai

# 安装netcat检查数据库连接
RUN apk add --no-cache netcat-openbsd

WORKDIR /flarum/app

# 暴露端口
EXPOSE 8888

# 创建启动脚本 - 删除配置文件让Flarum显示安装页面
RUN echo '#!/bin/sh' > /start.sh
RUN echo 'set -e' >> /start.sh
RUN echo 'echo "等待数据库连接..."' >> /start.sh
RUN echo 'while ! nc -z "${DB_HOST}" "${DB_PORT:-3306}"; do' >> /start.sh
RUN echo '    echo "数据库未就绪，等待中..."' >> /start.sh
RUN echo '    sleep 3' >> /start.sh
RUN echo 'done' >> /start.sh
RUN echo 'echo "数据库连接成功！"' >> /start.sh
RUN echo '# 删除配置文件，让Flarum显示安装页面' >> /start.sh
RUN echo 'rm -f /flarum/app/config.php' >> /start.sh
RUN echo 'echo "已删除配置文件，准备显示安装页面"' >> /start.sh
RUN echo 'echo "启动论坛服务..."' >> /start.sh
RUN echo 'cd /flarum/app/public' >> /start.sh
RUN echo 'exec php -S 0.0.0.0:8888 -t .' >> /start.sh

RUN chmod +x /start.sh

CMD ["/start.sh"]