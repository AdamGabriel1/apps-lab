#!/bin/bash

LOG_FILE="system_metrics_$(date +%Y%m%d_%H%M%S).csv"

# Cabeçalho do CSV
echo "timestamp,ram_used_mb,ram_percent,cpu_percent,disk_used_gb,process_count,temperature" > $LOG_FILE

while true; do
    TIMESTAMP=$(date +%Y-%m-%d_%H:%M:%S)
    RAM_USED=$(free -m | awk 'NR==2{print $3}')
    RAM_PERCENT=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    CPU_PERCENT=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    DISK_USED=$(df -m / | awk 'NR==2{print $3}')
    PROCESS_COUNT=$(ps aux --no-heading | wc -l)
    TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print $1/1000}' || echo "N/A")
    
    echo "$TIMESTAMP,$RAM_USED,$RAM_PERCENT,$CPU_PERCENT,$DISK_USED,$PROCESS_COUNT,$TEMP" >> $LOG_FILE
    sleep 30
done
