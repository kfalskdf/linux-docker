# Linux Docker

基于 Debian 12 slim 的 Docker 镜像，预装 SSH 和网络工具。

## 预装工具

| 工具 | 版本 | 路径 |
|------|------|------|
| cloudflared | latest | `/root/cloudflared` |
| EasyTier | latest | `/root/easytier` |
| gost | v2.12.0 | `/root/gost` |
| shellinabox | apt | 端口 4200 |

## 快速使用

### 运行容器

```bash
docker run -d -p 2222:22 -p 4200:4200 --name linux-docker \
  ghcr.io/kfalskdf/linux-docker:latest
```

### 访问服务

- **SSH**: `ssh kfal@localhost -p 2222` (密码: `Debian2026`)
- **Web 终端**: http://localhost:4200

### 自定义密码

```bash
docker run -d -p 2222:22 -p 4200:4200 --name linux-docker \
  --build-arg DEFAULT_PASSWORD=YourPassword \
  ghcr.io/kfalskdf/linux-docker:latest
```

## 本地构建

```bash
git clone https://github.com/kfalskdf/linux-docker.git
cd linux-docker
docker build -t linux-docker:latest .
```

## 端口说明

| 端口 | 服务 |
|------|------|
| 22 | SSH |
| 4200 | shellinabox Web 终端 |

## 用户信息

- 用户名: `kfal`
- 密码: `Debian2026` (可自定义)
- sudo: 免密
