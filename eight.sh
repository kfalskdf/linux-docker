#!/bin/bash

# 确保必要的命令存在
command -v /usr/local/bin/sing-box >/dev/null 2>&1 || { echo "错误：未找到 sing-box。"; exit 1; }
command -v /usr/local/bin/cloudflared >/dev/null 2>&1 || { echo "错误：未找到 cloudflared。"; exit 1; }
command -v /usr/local/bin/agent >/dev/null 2>&1 || { echo "错误：未找到 agent。"; exit 1; }

# --- Nezha Agent 环境变量处理 ---
NEZHA_SERVER="${nezha_server:-}"
NEZHA_KEY="${nezha_key:-}"
NODE_NAME="${node_name:-cf_tunnel}"  # 节点名称，默认 cf_tunnel

# 提取服务器端口用于 TLS 检测
NEZHA_TLS_PORT=""
if [ -n "$NEZHA_SERVER" ]; then
    if [[ "$NEZHA_SERVER" == *:* ]]; then
        NEZHA_TLS_PORT="${NEZHA_SERVER##*:}"
    fi
fi

# 检测是否启用 TLS
NEZHA_TLS="false"
TLS_PORTS="443 8443 2096 2087 2083 2053"
for port in $TLS_PORTS; do
    if [ "$NEZHA_TLS_PORT" = "$port" ]; then
        NEZHA_TLS="true"
        break
    fi
done

# --- UUID 处理 ---
EFFECTIVE_UUID=""
if [ -n "$uuid" ]; then
    EFFECTIVE_UUID="$uuid"
    echo "--------------------------------------------------"
    echo "检测到用户提供的 UUID: $EFFECTIVE_UUID"
else
    EFFECTIVE_UUID=$(/usr/local/bin/sing-box generate uuid)
    echo "--------------------------------------------------"
    echo "未提供 UUID，已自动生成: $EFFECTIVE_UUID"
fi
echo "--------------------------------------------------"

# --- Nezha Agent v1 运行 ---
if [ -n "$NEZHA_SERVER" ] && [ -n "$NEZHA_KEY" ]; then
    echo "检测到 Nezha Agent 配置，正在启动..."
    
    # 生成 config.yaml 配置文件
    cat > config.yaml <<EOF
client_secret: ${NEZHA_KEY}
debug: false
disable_auto_update: true
disable_command_execute: false
disable_force_update: true
disable_nat: false
disable_send_query: false
gpu: false
insecure_tls: true
ip_report_period: 1800
report_delay: 4
server: ${NEZHA_SERVER}
skip_connection_count: true
skip_procs_count: true
temperature: false
tls: ${NEZHA_TLS}
use_gitee_to_upgrade: false
use_ipv6_country_code: false
uuid: ${EFFECTIVE_UUID}
EOF
    echo "config.yaml 已创建。"
    
    # 运行 agent
    nohup /usr/local/bin/agent -c config.yaml > agent.log 2>&1 &
    AGENT_PID=$!
    sleep 2
    
    # 检查 agent 是否成功启动
    if ps -p $AGENT_PID > /dev/null 2>&1; then
        echo "Nezha Agent 已启动 (PID: $AGENT_PID)"
    else
        echo "警告: Nezha Agent 启动可能失败，请检查 agent.log"
        if [ -f agent.log ]; then
            echo "--- Agent 日志 ---"
            cat agent.log
        fi
    fi
    echo "--------------------------------------------------"
else
    echo "Nezha 环境变量未配置，跳过 Agent 启动。"
    echo "--------------------------------------------------"
fi

