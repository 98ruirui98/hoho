#!/bin/bash

LOG_FILE="/var/log/miner/custom/custom_cpu.log"
WORKER_CMD="/hive/miners/custom/OreMinePoolWorker_hiveos/ore-mine-pool-linux worker --route-server-url http://route.oreminepool.top:8080/ --server-url public --worker-wallet-address FSapBfxcadEU6E1a8Hr6F4sJaKZ6V7XV3PMvySksCXBf"
CHECK_INTERVAL=30
IDLE_PATTERN="rqiner_manager] Idle period | Waiting for work"
MIN_IDLE_LINES=5
NO_CHANGE_INTERVAL=180
MINER_STOP_CMD="miner stop"
MINER_START_CMD="miner start"
WORKER_RUNNING=false

# 获取文件的初始修改时间
initial_mod_time=$(stat -c %Y "$LOG_FILE")

while true; do
    # 检查日志文件的最后10行
    IDLE_COUNT=$(tail -n 10 "$LOG_FILE" | grep -c "$IDLE_PATTERN")

    if [ "$IDLE_COUNT" -ge "$MIN_IDLE_LINES" ] && [ "$WORKER_RUNNING" = false ]; then
        # 如果最后10行中有5行或更多行包含空闲模式，并且挖矿程序未运行，则执行挖矿程序
        $WORKER_CMD &
        WORKER_RUNNING=true
    elif [ "$IDLE_COUNT" -lt "$MIN_IDLE_LINES" ]; then
        # 如果少于5行包含空闲模式，并且有挖矿程序运行，则杀死所有 ore-mine-pool-linux 进程
        if pgrep -f ore-mine-pool-linux > /dev/null; then
            pkill -f ore-mine-pool-linux
            WORKER_RUNNING=false
        fi
    fi

    # 检查日志文件在过去3分钟内是否有变化
    current_mod_time=$(stat -c %Y "$LOG_FILE")
    if [ "$((current_mod_time - initial_mod_time))" -ge "$NO_CHANGE_INTERVAL" ]; then
        $MINER_STOP_CMD
        sleep 25
        $MINER_START_CMD
        # 更新初始修改时间
        initial_mod_time=$(stat -c %Y "$LOG_FILE")
    fi

    sleep $CHECK_INTERVAL
done
