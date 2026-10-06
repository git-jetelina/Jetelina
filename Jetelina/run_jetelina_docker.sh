#!/bin/bash

# ==============================================================================
# Jetelina Docker Management Script (World Public Edition)
# ==============================================================================

CONTAINER_NAME="jetelina-run"
IMAGE_NAME="ghcr.io/git-jetelina/jetelina:latest"

SCRIPT_NAME=$(basename "$0")
EXEC_CMD="./$SCRIPT_NAME"

show_usage() {
    echo "Usage (Please provide one of the following arguments):"
    echo "  ${EXEC_CMD} start   : Start Jetelina container"
    echo "  ${EXEC_CMD} stop    : Stop and remove the running container"
    echo "  ${EXEC_CMD} restart : Restart the container"
    echo "  ${EXEC_CMD} logs    : View application logs in real-time"
    exit 1
}

ACTION="$1"
[ -z "$ACTION" ] && show_usage

case "$ACTION" in
    start)
        echo "Initializing Jetelina container..."
        docker rm -f ${CONTAINER_NAME} 2>/dev/null
        docker volume create jetelina_data >/dev/null
        
        docker run -d \
          --network=host \
          -v jetelina_data:/app/Jetelina/app/resources/config \
          --name ${CONTAINER_NAME} \
          ${IMAGE_NAME}
          
        echo "Jetelina container has been successfully launched!"
        echo "Access the app at: http://localhost:8000/jetelina/"
        ;;
    stop)
        docker rm -f ${CONTAINER_NAME} 2>/dev/null && echo "Container stopped and removed." || echo "No container found."
        ;;
    restart)
        docker restart ${CONTAINER_NAME} && echo "Container restarted."
        ;;
    logs)
        docker logs -f ${CONTAINER_NAME}
        ;;
    *)
        show_usage
        ;;
esac
