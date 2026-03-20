# 使用 Debian 12 作为基础镜像
FROM debian:12

# 安装 OpenSSH 服务，并清理缓存
RUN apt-get update && \
    apt-get install -y openssh-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 设置 root 用户的密码为 'root'（仅用于测试环境）
RUN echo 'root:root' | chpasswd

# 生成 SSH 主机密钥（如果没有自动生成）
RUN ssh-keygen -A

# 暴露 SSH 默认端口
EXPOSE 22

# 启动 SSH 服务（前台运行）
CMD ["/usr/sbin/sshd", "-D"]
