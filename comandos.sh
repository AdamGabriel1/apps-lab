#!/bin/bash
# analyze_metrics.sh - Analisar os dados coletados

if [ $# -eq 0 ]; then
    echo "Uso: $0 <arquivo_csv>"
    echo "Exemplo: $0 system_metrics_20241201_143022.csv"
    exit 1
fi

CSV_FILE="$1"

if [ ! -f "$CSV_FILE" ]; then
    echo "Arquivo não encontrado: $CSV_FILE"
    exit 1
fi

echo "=== ANALISE DE METRICAS ==="
echo "Arquivo: $CSV_FILE"
echo ""

# Estatísticas básicas
echo "--- ESTATISTICAS GERAIS ---"
echo "Total de amostras: $(wc -l < "$CSV_FILE" | awk '{print $1-1}')"
echo "Periodo de coleta: $(head -2 "$CSV_FILE" | tail -1 | cut -d',' -f1) até $(tail -1 "$CSV_FILE" | cut -d',' -f1)"
echo ""

# Métricas de RAM
echo "--- MEMORIA RAM ---"
awk -F',' 'NR>1 {print $3}' "$CSV_FILE" | sort -n | awk '
NR==1 {min=$1}
END {max=$1; count=NR}
{sum+=$1}
END {
    avg=sum/count;
    print "Uso medio: " avg "%";
    print "Minimo: " min "%";
    print "Maximo: " max "%";
}'

echo ""

# Métricas de CPU
echo "--- PROCESSADOR ---"
awk -F',' 'NR>1 {print $4}' "$CSV_FILE" | sort -n | awk '
NR==1 {min=$1}
END {max=$1; count=NR}
{sum+=$1}
END {
    avg=sum/count;
    print "Uso medio: " avg "%";
    print "Minimo: " min "%";
    print "Maximo: " max "%";
}'

echo ""

# Processos
echo "--- PROCESSOS ---"
awk -F',' 'NR>1 {print $6}' "$CSV_FILE" | sort -n | awk '
NR==1 {min=$1}
END {max=$1; count=NR}
{sum+=$1}
END {
    avg=sum/count;
    print "Media de processos: " avg;
    print "Minimo: " min;
    print "Maximo: " max;
}'

echo ""
echo "Para análise gráfica, use:"
echo "  python3 -c \"import pandas as pd; import matplotlib.pyplot as plt; df=pd.read_csv('$CSV_FILE'); df.plot(); plt.show()\""
