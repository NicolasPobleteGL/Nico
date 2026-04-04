#!/bin/bash

# Configuración: carpeta a vigilar
TARGET_DIR="$HOME/Nico"
BRANCH="main"

echo "🔍 Runner activado: Vigilando cambios internos en $TARGET_DIR..."

# Usamos inotifywait para detectar cuando un archivo se MODIFICA por dentro (-e modify)
# Excluimos .git y archivos temporales de Obsidian para no saturar GitHub
inotifywait -m -r -e modify,create,delete "$TARGET_DIR" --exclude "\.git/|\.obsidian/workspace\.json" |
    while read -r path action file; do
        
        # Ignorar archivos basura de sistema o temporales
        if [[ "$file" == *~ ]] || [[ "$file" == *.swp ]] || [[ "$file" == "4913" ]]; then
            continue
        fi

        echo "📝 Cambio detectado en: $file"
        
        # Esperar 2 segundos por si estás guardando varios archivos a la vez
        sleep 2
        
        cd "$TARGET_DIR" || exit
        
        # Git añade los cambios internos automáticamente
        git add .
        
        # Intentar hacer commit y subir
        if git commit -m "Auto-sync: $file actualizado [$(date +'%H:%M')]"; then
            git push origin $BRANCH
            echo "🚀 ¡Sincronizado con GitHub!"
        else
            echo "ℹ️ Cambio menor detectado, no requiere push."
        fi
        echo "------------------------------------------"
    done
