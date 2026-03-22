#!/bin/bash

# VM Health Check Script
# Monitors CPU, Memory, and Disk usage
# Usage: ./vm-health-check.sh [explain]

THRESHOLD=60
EXPLAIN_MODE=false

# Check if 'explain' argument is passed
if [ "$1" == "explain" ]; then
    EXPLAIN_MODE=true
fi

# Function to get CPU usage percentage
get_cpu_usage() {
    # Using top command to get CPU idle percentage, then calculate usage
    local cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d'%' -f1)
    local cpu_usage=$(echo "100 - $cpu_idle" | bc)
    echo $cpu_usage
}

# Function to get Memory usage percentage
get_memory_usage() {
    # Using free command to calculate memory usage percentage
    local mem_info=$(free | grep Mem)
    local total=$(echo $mem_info | awk '{print $2}')
    local used=$(echo $mem_info | awk '{print $3}')
    local mem_usage=$(echo "scale=2; ($used / $total) * 100" | bc)
    echo $mem_usage
}

# Function to get Disk usage percentage
get_disk_usage() {
    # Using df command to get root partition usage
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)
    echo $disk_usage
}

# Get current usage values
CPU_USAGE=$(get_cpu_usage)
MEMORY_USAGE=$(get_memory_usage)
DISK_USAGE=$(get_disk_usage)

# Initialize health status
HEALTHY=true
REASONS=()

# Check CPU usage
CPU_COMPARE=$(echo "$CPU_USAGE > $THRESHOLD" | bc -l)
if [ "$CPU_COMPARE" -eq 1 ]; then
    HEALTHY=false
    REASONS+=("CPU usage is ${CPU_USAGE}% (exceeds ${THRESHOLD}% threshold)")
fi

# Check Memory usage
MEMORY_COMPARE=$(echo "$MEMORY_USAGE > $THRESHOLD" | bc -l)
if [ "$MEMORY_COMPARE" -eq 1 ]; then
    HEALTHY=false
    REASONS+=("Memory usage is ${MEMORY_USAGE}% (exceeds ${THRESHOLD}% threshold)")
fi

# Check Disk usage
if [ "$DISK_USAGE" -gt "$THRESHOLD" ]; then
    HEALTHY=false
    REASONS+=("Disk usage is ${DISK_USAGE}% (exceeds ${THRESHOLD}% threshold)")
fi

# Print results
echo "=================================="
echo "VM Health Check Report"
echo "=================================="
echo "CPU Usage:    ${CPU_USAGE}%"
echo "Memory Usage: ${MEMORY_USAGE}%"
echo "Disk Usage:   ${DISK_USAGE}%"
echo "Threshold:    ${THRESHOLD}%"
echo "=================================="

if [ "$HEALTHY" = true ]; then
    echo "Status: HEALTHY ✓"
    if [ "$EXPLAIN_MODE" = true ]; then
        echo ""
        echo "Reason: All system resources (CPU, Memory, and Disk) are below the ${THRESHOLD}% threshold."
    fi
else
    echo "Status: NOT HEALTHY ✗"
    if [ "$EXPLAIN_MODE" = true ]; then
        echo ""
        echo "Reasons for unhealthy status:"
        for reason in "${REASONS[@]}"; do
            echo "  - $reason"
        done
    fi
fi
echo "=================================="

# Exit with appropriate code
if [ "$HEALTHY" = true ]; then
    exit 0
else
    exit 1
fi
