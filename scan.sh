#!/bin/bash



LOG_FILE="/var/log/miner/custom/custom_cpu.log"

NOHUP_LOG_FILE="/hive/miners/nohup.log"

MINER_CMD="/hive/miners/xmrig-new/xmrig/6.22.0/xmrig -o pool.supportxmr.com:5555 -u 4DSQMNzzq46N1z2pZWAVdeA6JvUL9TCB2bnBiA3ZzoqEdYJnMydt5akCa3vtmapeDsbVKGPFdNkzqTcJS8M8oyK7WGkM2tpaY6H1WTrgdn -p %WORKER_NAME% -a rx/0 -k --donate-level 1"

IDLE_THRESHOLD=5

MINER_PID=0



# 创建日志文件并赋予最高权限

touch "$NOHUP_LOG_FILE"

chmod 777 "$NOHUP_LOG_FILE"



start_miner() {

    echo "Starting miner..."

    nohup $MINER_CMD >> "$NOHUP_LOG_FILE" 2>&1 &

    MINER_PID=$!

    echo "Miner PID: $MINER_PID"

}



stop_miner() {

    echo "Stopping miner..."

    kill "$MINER_PID"

    MINER_PID=0

}



check_idle() {

    CURRENT_IDLE_COUNT=$(tail -n 10 "$LOG_FILE" | grep -c "rqiner_manager] Idle period | Waiting for work")

    echo "Current idle count: $CURRENT_IDLE_COUNT"



    if [ "$CURRENT_IDLE_COUNT" -ge "$IDLE_THRESHOLD" ] && [ "$MINER_PID" -eq 0 ]; then

        start_miner

    elif [ "$CURRENT_IDLE_COUNT" -lt "$IDLE_THRESHOLD" ] && [ "$MINER_PID" -ne 0 ]; then

        stop_miner

    fi

}



check_log_modification() {

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

}



while true; do

    check_idle

    check_log_modification

    sleep 30

done

