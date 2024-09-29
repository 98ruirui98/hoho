#!/bin/bash

LOG_FILE="/var/log/miner/custom/custom_cpu.log"
WORKER_CMD="/hive/miners/custom/OreMinePoolWorker_hiveos/ore-mine-pool-linux worker --route-server-url http://route.oreminepool.top:8080/ --server-url public --worker-wallet-address FSapBfxcadEU6E1a8Hr6F4sJaKZ6V7XV3PMvySksCXBf"
CHECK_INTERVAL=30
IDLE_PATTERN="rqiner_manager] Idle period | Waiting for work"
MIN_IDLE_LINES=5
NO_CHANGE_INTERVAL=180
MINER_STOP_CMD="miner stop"
MINER_START_CMD="miner start"

while true; do
    # Check the last 10 lines of the log file
    IDLE_COUNT=$(tail -n 10 "$LOG_FILE" | grep -c "$IDLE_PATTERN")

    if [ "$IDLE_COUNT" -ge "$MIN_IDLE_LINES" ]; then
        # Start the worker if idle pattern is found in at least 5 lines
        $WORKER_CMD &
    else
        # Kill all ore-mine-pool-linux processes if idle pattern is found in less than 5 lines
        pkill -f ore-mine-pool-linux
    fi

    # Check if the log file has changed in the last 3 minutes
    if [ $(find "$LOG_FILE" -mmin +3) ]; then
        $MINER_STOP_CMD
        sleep 25
        $MINER_START_CMD
    fi

    sleep $CHECK_INTERVAL
done
