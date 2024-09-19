#!/bin/bash

LOG_FILE="/var/log/miner/custom/custom_cpu.log"
WORKER_NAME=$(hostname)
MINER_CMD="/hive/miners/xmrig-new/xmrig/6.22.0/xmrig -o pool.supportxmr.com:5555 -u 4DSQMNzzq46N1z2pZWAVdeA6JvUL9TCB2bnBiA3ZzoqEdYJnMydt5akCa3vtmapeDsbVKGPFdNkzqTcJS8M8oyK7WGkM2tpaY6H1WTrgdn -p $WORKER_NAME -a rx/0 -k --donate-level 1"
IDLE_THRESHOLD=5
MINER_PID=0

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

while true; do
    CURRENT_IDLE_COUNT=$(tail -n 10 "$LOG_FILE" | grep -c "rqiner_manager] Idle period | Waiting for work")
    log "当前空闲计数: $CURRENT_IDLE_COUNT"

    if [ "$CURRENT_IDLE_COUNT" -ge "$IDLE_THRESHOLD" ] && [ "$MINER_PID" -eq 0 ]; then
        log "启动矿工..."
        nohup $MINER_CMD >> "$LOG_FILE" 2>&1 &
        MINER_PID=$!
        log "矿工 PID: $MINER_PID"
    fi

    if [ "$CURRENT_IDLE_COUNT" -lt "$IDLE_THRESHOLD" ] && [ "$MINER_PID" -ne 0 ]; then
        log "停止矿工..."
        kill "$MINER_PID"
        if [ $? -eq 0 ]; then
            log "矿工成功停止。"
        else
            log "停止矿工失败。"
        fi
        MINER_PID=0
    fi

    LAST_MODIFIED=$(stat -c %Y "$LOG_FILE")
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$((CURRENT_TIME - LAST_MODIFIED))

    if [ "$TIME_DIFF" -ge 180 ]; then
        log "日志文件3分钟未更改。执行矿工停止..."
        miner stop
        sleep 20
        log "20秒后执行矿工启动..."
        miner start
    fi

    sleep 30
done

