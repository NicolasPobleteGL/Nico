#!/bin/bash

# Configuración
TARGET_DIR="$HOME/Nico"
BRANCH="main"
WAIT_TIME=120  # ⏱️ 2 minutos (120 segundos) de calma antes del push

echo "🕵️ Runner inteligente (2 min de espera) activo en $TARGET_DIR"

# Monitorizamos cambios reales en archivos
inotifywait -m -r -e modify,create,delete "$TARGET_DIR" --exclude "\.git/|\.obsidian/workspace\.json" |
    while read -r path action file; do
        
        # Ignorar basura de sistema o temporales
        [[ "$file" == *~ || "$file" == *.swp || "$file" == "4913" ]] && continue

        echo "📝 Cambio detectado en: $file. Reiniciando espera de 2 minutos..."

        # Matamos cualquier espera previa para reiniciar el cronómetro
        if [ -f /tmp/git_sync_pid ]; then
            pkill -P $(cat /tmp/git_sync_pid) 2>/dev/null
            kill $(cat /tmp/git_sync_pid) 2>/dev/null
        fi

        # Proceso de fondo: espera los 120s y luego sube
        (
            sleep $WAIT_TIME
            cd "$TARGET_DIR" || exit
            
            git add .
            # Solo hacemos push si hay algo nuevo que commitear
            if git commit -m "Auto-sync: Avances acumulados [$(date +'%H:%M')]"; then
                git push origin $BRANCH
                echo "🚀 [$(date +'%H:%M')] ¡Sincronización de 2 minutos completada!"
            fi
            rm /tmp/git_sync_pid
        ) & 
        
        # Guardamos el PID para controlarlo
        echo $! > /tmp/git_sync_pid
    done
