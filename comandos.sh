#!/bin/bash
# monitor_system.sh - Script completo de monitoramento de sistema
LOG_FILE="system_metrics_$(date +%Y%m%d_%H%M%S).csv"
SYS_INFO_FILE="system_info_$(date +%Y%m%d_%H%M%S).txt"

# Função para obter informações do sistema
get_system_info() {
    echo "=== INFORMACOES DO SISTEMA ==="
    echo "Data da coleta: $(date)"
    echo "Hostname: $(hostname)"
    echo ""
    
    # Informações do SO
    echo "--- SISTEMA OPERACIONAL ---"
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        echo "Distribuicao: $PRETTY_NAME"
        echo "Versao: $VERSION_ID"
        echo "Kernel: $(uname -r)"
        echo "Arquitetura: $(uname -m)"
    else
        echo "Distribuicao: $(uname -s)"
        echo "Kernel: $(uname -r)"
        echo "Arquitetura: $(uname -m)"
    fi
    echo ""
    
    # Informações da CPU
    echo "--- PROCESSADOR (CPU) ---"
    echo "Modelo: $(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^ *//')"
    echo "Nucleos fisicos: $(grep "physical id" /proc/cpuinfo | sort -u | wc -l)"
    echo "Nucleos totais: $(grep -c "processor" /proc/cpuinfo)"
    echo "Threads por nucleo: $(grep "siblings" /proc/cpuinfo | head -1 | cut -d':' -f2 | tr -d ' ')"
    echo "Frequencia base: $(grep "cpu MHz" /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^ *//') MHz"
    echo "Cache L1: $(grep "cache size" /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^ *//')"
    echo ""
    
    # Informações da Memória
    echo "--- MEMORIA RAM ---"
    TOTAL_RAM_GB=$(free -g | awk 'NR==2{print $2}')
    TOTAL_RAM_MB=$(free -m | awk 'NR==2{print $2}')
    echo "Total: ${TOTAL_RAM_GB} GB (${TOTAL_RAM_MB} MB)"
    echo "Tipo: $(dmidecode -t memory 2>/dev/null | grep "Type:" | head -1 | cut -d':' -f2 | sed 's/^ *//' || echo "N/A")"
    echo "Velocidade: $(dmidecode -t memory 2>/dev/null | grep "Speed:" | head -1 | cut -d':' -f2 | sed 's/^ *//' || echo "N/A")"
    echo ""
    
    # Informações do Disco
    echo "--- ARMAZENAMENTO ---"
    echo "Disco principal: $(lsblk -o MODEL,SIZE -d /dev/sda 2>/dev/null | awk 'NR==2' || lsblk -o MODEL,SIZE -d /dev/nvme0n1 2>/dev/null | awk 'NR==2' || echo "N/A")"
    echo "Tipo: $(lsblk -d -o rota /dev/sda 2>/dev/null | awk 'NR==2' | sed 's/0/SSD/;s/1/HDD/' || echo "N/A")"
    echo "Tamanho total: $(df -h / | awk 'NR==2{print $2}')"
    echo "Sistema arquivos: $(df -T / | awk 'NR==2{print $2}')"
    echo ""
    
    # Informações da GPU
    echo "--- PLACA DE VIDEO (GPU) ---"
    if command -v nvidia-smi &> /dev/null; then
        echo "NVIDIA: $(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)"
        echo "VRAM: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader | head -1)"
    elif command -v lspci &> /dev/null; then
        GPU_INFO=$(lspci | grep -i vga | head -1)
        if [ -n "$GPU_INFO" ]; then
            echo "Modelo: $GPU_INFO"
        else
            echo "Modelo: Integrada/Desconhecida"
        fi
    else
        echo "Modelo: N/A (lspci nao disponivel)"
    fi
    echo ""
    
    # Informações de Rede
    echo "--- REDE ---"
    echo "Interface principal: $(ip route | grep default | awk '{print $5}' | head -1)"
    echo "IP: $(hostname -I | awk '{print $1}')"
    echo ""
    
    # Ambiente Desktop
    echo "--- AMBIENTE DE DESKTOP ---"
    echo "Desktop: $XDG_CURRENT_DESKTOP"
    echo "Sessao: $XDG_SESSION_TYPE"
    echo ""
    
    # Informações do NixOS (se aplicável)
    if [ -f /etc/NIXOS ]; then
        echo "--- NIXOS ESPECIFICO ---"
        echo "Versao NixOS: $(nixos-version)"
        echo "Canais: $(nix-channel --list)"
        echo "Geracao atual: $(nixos-version | cut -d'.' -f4)"
    fi
}

# Função para obter temperatura (compatibilidade multipla)
get_temperature() {
    # Tentar diferentes fontes de temperatura
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
        echo "$(echo "scale=1; $TEMP/1000" | bc)"
    elif [ -f "/sys/class/hwmon/hwmon0/temp1_input" ]; then
        TEMP=$(cat /sys/class/hwmon/hwmon0/temp1_input)
        echo "$(echo "scale=1; $TEMP/1000" | bc)"
    elif command -v sensors &> /dev/null; then
        TEMP=$(sensors | grep -i "core" | head -1 | awk '{print $3}' | sed 's/\+//;s/°C//')
        echo "$TEMP"
    else
        echo "N/A"
    fi
}

# Função para obter uso da GPU
get_gpu_usage() {
    if command -v nvidia-smi &> /dev/null; then
        NVIDIA_GPU_USAGE=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -1)
        echo "$NVIDIA_GPU_USAGE"
    else
        echo "N/A"
    fi
}

# Salvar informações do sistema
get_system_info > "$SYS_INFO_FILE"
echo "Informacoes do sistema salvas em: $SYS_INFO_FILE"

# Cabeçalho do CSV com métricas contínuas
echo "timestamp,ram_used_mb,ram_percent,cpu_percent,disk_used_gb,process_count,temperature,gpu_usage,load_1min,load_5min,load_15min,swap_used_mb" > "$LOG_FILE"

echo "Iniciando monitoramento continuo..."
echo "Arquivo de log: $LOG_FILE"
echo "Pressione Ctrl+C para parar"
echo ""

# Contador de iterações
ITERATION=0

while true; do
    TIMESTAMP=$(date +%Y-%m-%d_%H:%M:%S)
    
    # Memória
    RAM_USED=$(free -m | awk 'NR==2{print $3}')
    RAM_PERCENT=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    SWAP_USED=$(free -m | awk 'NR==3{print $3}')
    
    # CPU
    CPU_PERCENT=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    LOAD_AVG=$(cat /proc/loadavg | awk '{print $1","$2","$3}')
    
    # Disco
    DISK_USED=$(df -m / | awk 'NR==2{print $3}')
    
    # Processos
    PROCESS_COUNT=$(ps aux --no-heading | wc -l)
    
    # Temperatura
    TEMPERATURE=$(get_temperature)
    
    # GPU
    GPU_USAGE=$(get_gpu_usage)
    
    # Escrever no CSV
    echo "$TIMESTAMP,$RAM_USED,$RAM_PERCENT,$CPU_PERCENT,$DISK_USED,$PROCESS_COUNT,$TEMPERATURE,$GPU_USAGE,$LOAD_AVG,$SWAP_USED" >> "$LOG_FILE"
    
    # Exibir status a cada 10 iterações
    if [ $((ITERATION % 10)) -eq 0 ]; then
        echo "[$TIMESTAMP] - RAM: $RAM_PERCENT% | CPU: $CPU_PERCENT% | TEMP: $TEMPERATURE°C | PROCESSOS: $PROCESS_COUNT"
    fi
    
    ITERATION=$((ITERATION + 1))
    sleep 30
done
