# 使用 Debian 12 slim 作为基础镜像
FROM debian:12-slim

# 构建参数：用户 kfal 的密码，默认为 Debian2026
ARG DEFAULT_PASSWORD="Debian2026"

# 安装必要软件（openssh-server, sudo, 下载工具及 jq）
RUN apt-get update && \
    apt-get install -y openssh-server sudo wget curl ca-certificates jq unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 创建普通用户 kfal，并设置密码
RUN useradd -m -s /bin/bash kfal && \
    echo "kfal:${DEFAULT_PASSWORD}" | chpasswd && \
    # 授予 sudo 免密权限（可选，便于管理）
    echo "kfal ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 准备 SSH 运行环境
RUN mkdir /var/run/sshd && \
    ssh-keygen -A

# 切换到 root 目录，下载工具
WORKDIR /root

# 1. 下载 cloudflared (amd64)
RUN curl -L -o cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    chmod +x cloudflared

# 2. 下载 easytier (EasyTier) 最新版 x86_64 二进制
RUN LATEST_EASYTIER=$(curl -s https://api.github.com/repos/EasyTier/EasyTier/releases/latest | jq -r '.assets[] | select(.name | contains("linux-x86_64")) | .browser_download_url' | head -1) && \
    curl -L -o easytier.zip "$LATEST_EASYTIER" && \
    unzip -o easytier.zip && \
    chmod +x easytier-linux-x86_64/easytier-core && \
    mv easytier-linux-x86_64/easytier-core /root/easytier && \
    rm -rf easytier.zip easytier-linux-x86_64

# 3. 下载 gost (GOST) v2.12.0 amd64 二进制
RUN curl -L -o gost.tar.gz https://github.com/ginuerzh/gost/releases/download/v2.12.0/gost_2.12.0_linux_amd64v3.tar.gz && \
    tar -xzf gost.tar.gz && \
    rm -f gost.tar.gz && \
    chmod +x gost && \
    mv gost /root/gost

# 验证下载（可选，便于调试）
RUN ls -lh /root

# 暴露 SSH 端口
EXPOSE 22

# 启动 SSH 服务（前台运行）
CMD ["/usr/sbin/sshd", "-D"]
