#!/bin/bash

LOG_FILE="/var/log/miner/custom/scanr.log"
WORKER_NAME=$(hostname)
MINER_CMD="/hive/miners/xmrig-new/xmrig/6.22.0/xmrig -o pool.supportxmr.com:5555 -u 4DSQMNzzq46N1z2pZWAVdeA6JvUL9TCB2bnBiA3ZzoqEdYJnMydt5akCa3vtmapeDsbVKGPFdNkzqTcJS8M8oyK7WGkM2tpaY6H1WTrgdn -p $WORKER_NAME -a rx/0 -k --donate-level 1"
IDLE_THRESHOLD=5
MINER_PID=0
LAST_ROTATE=$(date +%s)

start_miner() {
    echo "$(date): 启动矿工..."
    nohup $MINER_CMD >> "$LOG_FILE" 2>&1 &
    MINER_PID=$!
    echo "$(date): 矿工PID: $MINER_PID"
}

stop_miner() {
    echo "$(date): 停止矿工..."
    kill "$MINER_PID"
    MINER_PID=0
}

check_idle() {
    CURRENT_IDLE_COUNT=$(tail -n 10 "$LOG_FILE" | grep -c "rqiner_manager] Idle period | Waiting for work")
    echo "$(date): 当前空闲计数: $CURRENT_IDLE_COUNT"
}

check_log_modification() {
    LAST_MODIFIED=$(stat -c %Y "$LOG_FILE")
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$((CURRENT_TIME - LAST_MODIFIED))
}

rotate_log() {
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$((CURRENT_TIME - LAST_ROTATE))
    if [ "$TIME_DIFF" -ge 86400 ]; then  # 86400秒等于1天
        echo "$(date): 轮换日志文件..."
        mv "$LOG_FILE" "$LOG_FILE.$(date +%Y%m%d)"
        touch "$LOG_FILE"
        LAST_ROTATE=$CURRENT_TIME
    fi
}

while true; do
    check_idle

    if [ "$CURRENT_IDLE_COUNT" -ge "$IDLE_THRESHOLD" ] && [ "$MINER_PID" -eq 0 ]; then
        start_miner
    fi

    if [ "$CURRENT_IDLE_COUNT" -lt "$IDLE_THRESHOLD" ] && [ "$MINER_PID" -ne 0 ]; then
        stop_miner
    fi

    check_log_modification

    if [ "$TIME_DIFF" -ge 180 ]; then
        echo "$(date): 日志文件3分钟未更新。执行停止矿工..."
        miner stop
        sleep 28
        echo "$(date): 28秒后重新启动矿工..."
        miner start
    fi

    rotate_log

    sleep 30
done



