#!/bin/bash
set -e

# Import local variables if running out of a localized debug wrapper
[ -f .env ] && export $(cat .env | grep -v '^#' | xargs)

START_TIME=$(date +%s)
BATON_PASSED=false

# 300 Hours target max execution boundary (1,080,000 Seconds)
MAX_RUN_TIME=${MAX_RUN_TIME:-1080000}
PREFLIGHT_BUFFER=3600 

echo "[INIT] Worker initialized. Max target run ceiling: ${MAX_RUN_TIME}s"

while true; do
    # Read music library directory, randomize execution stack tracks
    find music/ -name "*.mp3" | shuf | while read -r song; do
        
        ELAPSED=$(( $(date +%s) - START_TIME ))
        TIME_LEFT=$(( MAX_RUN_TIME - ELAPSED ))

        echo "[STREAMING] Track: $song | Total Node Uptime: ${ELAPSED}s | Remaining Limit: ${TIME_LEFT}s"

        # Pre-Flight Health Evaluation Validation
        if [ "$TIME_LEFT" -le "$PREFLIGHT_BUFFER" ] && [ "$BATON_PASSED" = false ]; then
            echo "[MONITOR] Time thresholds low. Verifying backup node availability..."
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$NEXT_SERVER_HEALTH" || echo "500")
            
            if [ "$HTTP_CODE" -eq 200 ]; then
                echo "[MONITOR] Backup node verified online."
                TARGET_NODE="$NEXT_SERVER_WAKEUP"
            else
                echo "[WARN] Backup cluster node down. Re-routing handoff traffic to secondary recovery grid."
                TARGET_NODE="https://api.render.com/deploy-hooks/secondary-failover"
            fi
        fi

        # The Baton Pass Action Block
        if [ "$ELAPSED" -ge "$MAX_RUN_TIME" ] && [ "$BATON_PASSED" = false ]; then
            echo "[HANDOFF] Time threshold crossed. Awakening next node sequence..."
            curl -X POST "$TARGET_NODE" -H "Authorization: Bearer $CLOUD_API_TOKEN" || echo "[ERROR] Wakeup ping failed."
            BATON_PASSED=true
        fi

        # Render and push raw compressed video blocks directly to the gateway receiver
        ffmpeg -re -loop 1 -i background.mp4 -i "$song" \
          -c:v libx264 -preset ultrafast -b:v 2000k -maxrate 2000k -bufsize 2000k \
          -pix_fmt yuv420p -g 48 -c:a aac -b:a 128k -ar 44100 -shortest \
          -f flv "rtmp://your-gateway-domain.render.com:8080/live/jazz?password=$PASSWORD"

        # Graceful exit point
        if [ "$BATON_PASSED" = true ] && [ "$ELAPSED" -gt "$MAX_RUN_TIME" ]; then
            echo "[EXIT] Relay completed successfully. Powering off node."
            exit 0
        fi
    done
done