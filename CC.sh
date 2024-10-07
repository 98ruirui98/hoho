#!/bin/bash

# 定义日志文件路径
LOG_FILE="/var/log/miner/custom/custom.log"

# 定义监控时间间隔为1分钟（60秒）
CHECK_INTERVAL=60

# 定义矿工停止和启动命令
STOP_COMMAND="miner stop"
START_COMMAND="miner start"

# 获取当前时间戳（自1970-01-01 00:00:00 UTC以来的秒数）
LAST_MODIFIED=$(stat -c %Y "$LOG_FILE")

while true; do
  # 当前时间戳
  CURRENT_TIME=$(date +%s)
  
  # 检查日志文件的最后修改时间
  NEW_MODIFIED=$(stat -c %Y "$LOG_FILE")
  
  # 如果文件在CHECK_INTERVAL时间内没有变化
  if [ "$NEW_MODIFIED" -eq "$LAST_MODIFIED" ]; then
    echo "日志文件在$CHECK_INTERVAL秒内没有变化，执行矿工重启操作..."
    
    # 停止矿工
    $STOP_COMMAND
    echo "矿工已停止，等待20秒..."
    
    # 等待20秒
    sleep 20
    
    # 启动矿工
    $START_COMMAND
    echo "矿工已重新启动。"
  else
    # 更新最后修改时间
    LAST_MODIFIED=$NEW_MODIFIED
  fi
  
  # 每隔CHECK_INTERVAL秒检查一次
  sleep $CHECK_INTERVAL
done
