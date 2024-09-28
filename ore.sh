#!/bin/bash

LOG_FILE="/var/log/miner/custom/custom_cpu.log"
WORKER_NAME=$(hostname)
MINER_CMD="/hive/miners/custom/OreMinePoolWorker_hiveos/ore-mine-pool-linux worker --route-server-url http://route.oreminepool.top:8080/ --server-url public --worker-wallet-address FSapBfxcadEU6E1a8Hr6F4sJaKZ6V7XV3PMvySksCXBf"
IDLE_THRESHOLD=5
MINER_PID=0

while true; do
    CURRENT_IDLE_COUNT=$(tail -n 10 "$LOG_FILE" | grep -c "rqiner_manager] Idle period | Waiting for work")
    echo "Current idle count: $CURRENT_IDLE_COUNT"

    if [ "$CURRENT_IDLE_COUNT" -ge "$IDLE_THRESHOLD" ] && [ "$MINER_PID" -eq 0 ]; then
        echo "Starting miner..."
        nohup $MINER_CMD >> "$LOG_FILE" 2>&1 &
        MINER_PID=$!
        echo "Miner PID: $MINER_PID"
    fi

    if [ "$CURRENT_IDLE_COUNT" -lt "$IDLE_THRESHOLD" ] && [ "$MINER_PID" -ne 0 ]; then
        echo "Stopping miner..."
        pkill -f "ore-mine-pool-linux"
        sleep 5
        if pgrep -f "ore-mine-pool-linux" > /dev/null; then
            echo "Processes are still running, forcing stop..."
            pkill -9 -f "ore-mine-pool-linux"
        else
            echo "Processes stopped successfully."
        fi
        MINER_PID=0
    fi

    # 检查日志文件的修改时间
    LAST_MODIFIED=$(stat -c %Y "$LOG_FILE")
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$((CURRENT_TIME - LAST_MODIFIED))

    if [ "$TIME_DIFF" -ge 180 ]; then
        echo "Log file has not changed for 3 minutes. Executing miner stop..."
        miner stop
        sleep 20
        echo "Executing miner start after 20 seconds..."
        miner start
    fi

    sleep 30
done
