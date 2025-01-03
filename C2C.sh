#!/bin/bash

url="http://qubic1.hk.apool.io:8001/api/qubic/epoch_challenge"
CHECK_INTERVAL=5  # 检查间隔时间（秒）
WORKER_NAME=$(hostname)
MINER_CMD="/hive/miners/custom/tnn-miner/tnn-miner --spectre  --daemon-address spr.tw-pool.com --port 14001 --worker-name $WORKER_NAME --wallet spectre:qzs5m5u9fl2nss64tnrtzftdyql9qnpjfqu96x2c9gfxxz8nlfrpqx3j4pvhw --threads 24"

while true; do
    res_url=$(curl -s -w "\nhttp_code:%{http_code}\n" "$url")
    res_code=$(echo "$res_url" | grep -o 'http_code:[0-9]*' | sed 's/http_code:\([0-9]*\)/\1/')
    [ "$res_code" != "200" ] && echo "failed to get idle status" && sleep $CHECK_INTERVAL && continue

    mining_time=$(echo "$res_url" | grep -o '"timestamp":[0-9]*' | sed 's/.*"timestamp":\([0-9]*\).*/\1/')
    mining_seed=$(echo "$res_url" | grep -o '"mining_seed":"[^"]*"' | sed 's/.*"mining_seed":"\([^"]*\)".*/\1/')
    mining_status=$([ "$mining_seed" == "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=" ] && echo "IDLE" || echo "BUSY")
    echo "$mining_status now, from $(date -d @$mining_time "+%Y-%m-%d %H:%M:%S")"

    if [ "$mining_status" == "IDLE" ]; then
        if ! pgrep -f xmrig > /dev/null; then
            echo "Starting XMRIG..."
            nohup $MINER_CMD >> /var/log/miner/custom/custom_cpu.log 2>&1 &
        else
            echo "XMRIG is already running."
        fi
    elif [ "$mining_status" == "BUSY" ]; then
        echo "Stopping XMRIG..."
        pkill -f xmrig
    fi

    sleep $CHECK_INTERVAL
done
