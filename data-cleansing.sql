CREATE DATABASE clean;

use clean;

SELECT * FROM limpieza;


DELIMITER // 
CREATE PROCEDURE limp()
BEGIN
	select * from limpieza;
END //

DELIMITER ;

CALL limp();

-- renombro las columnas 

SET SQL_SAFE_UPDATES = 0;

ALTER TABLE limpieza CHANGE COLUMN `ï»¿Id?empleado` `id_emp` VARCHAR(20) NULL;
﻿ALTER TABLE limpieza CHANGE COLUMN `gÃ©nero` `gender` varchar(20) null;
ALTER TABLE limpieza CHANGE COLUMN Apellido last_name varchar(50) null;
ALTER TABLE limpieza CHANGE COLUMN star_date start_date varchar(50) null;
ALTER TABLE limpieza CHANGE COLUMN Name name varchar(50) null;


-- cantidad de duplicados

SELECT DISTINCT id_emp, count(*) as duplicados
FROM limpieza
GROUP BY id_emp
HAVING count(*)>1;


-- En lugar de usar una subquery utilizo una CTE.
WITH total_duplicados AS (
    SELECT id_emp, COUNT(*) AS duplicados
    FROM limpieza
    GROUP BY id_emp
    HAVING COUNT(*) > 1
)
SELECT COUNT(*) AS cantidad_duplicados
FROM total_duplicados;

# 9 duplicados

rename table limpieza to conduplicados;

-- creo una tabla temporal sin duplicados
create temporary table  templimpieza AS 
SELECT DISTINCT * FROM conduplicados;

select count(*) as original FROM conduplicados;
-- 22223

SELECT COUNT(*) AS copia FROM templimpieza;
-- '22214' 

-- como se ve, la diferencia es de 9 registros con duplicados

CREATE TABLE limpieza as
select * from templimpieza;

-- finalmente elimino la tabla con duplicados 
DROP TABLE conduplicados;

call limp();

DESCRIBE limpieza;


SELECT TRIM(name) as name from limpieza;
SELECT TRIM(last_name) as last_name from limpieza;

SELECT name, trim(name) FROM limpieza
WHERE length(name) - length(trim(name)) > 0;

with espacios as (
SELECT TRIM(name) as name from limpieza)
SELECT name FROM espacios
WHERE length(name) - length(trim(name)) > 0

-- cambio permanentenmente la columna name

UPDATE limpieza SET name = trim(name);

-- hago lo mismo con la columna apellidos

SELECT last_name, trim(last_name)
FROM limpieza
WHERE length(last_name) - length(trim(last_name)) > 0;

-- verifico con una CTE que la query funcione para cambiar la talba

WITH espacios_last_name AS (
SELECT TRIM(last_name) as last_name FROM limpieza)
SELECT length(last_name) - length(trim(last_name)) > 0 AS espacios
FROM espacios_last_name;

UPDATE limpieza SET last_name = trim(last_name);

-- ¿ que pasa si tengo espacios entre dos nombres en una columna?
-- introduzco espacios para poder corregirlos

UPDATE limpieza SET area = replace(area,' ', '       ');
CALL limp();

-- REGEXP '\\s{2,}': La función REGEXP busca patrones que coincidan con la expresión regular.
-- \\s: Representa un espacio en blanco (espacio, tabulación, etc.).
-- {2,}: Indica que debe haber al menos dos espacios en blanco.

-- nos muestra todos los registros que tienen dos o mas espacios
SELECT area from limpieza 
WHERE area regexp '\\s{2,}';


SELECT area, trim(regexp_replace(area,'\\s{2,}',' ')) as ensayo 
FROM limpieza;

UPDATE limpieza SET area = trim(regexp_replace(area,'\\s{2,}',' '));

-- nuestro set de datos en gender esta en español, pero lo paso a ingles

SELECT gender,
CASE
	WHEN gender = 'hombre' THEN 'male'
    WHEN gender = 'mujer' THEN 'female'
    ELSE 'Other'
END AS gender1
FROM limpieza;

UPDATE limpieza SET gender = CASE WHEN gender = 'hombre' THEN 'male'
    WHEN gender = 'mujer' THEN 'female'
    ELSE 'Other'
END;

CALL limp();

describe limpieza;

-- la columna type me indica si el empleado trabaja remoto o hibrido
-- por lo tanto paso esa columna a formato texto para realizar el siguiente cambio
-- ya que 0 y 1 es confuso para quien llevara a cabo el analisis

ALTER TABLE limpieza modify column type TEXT;

SELECT type,
CASE 
	WHEN type = 0 THEN "remote"
    WHEN type = 1 THEN "hybrid"
    ELSE "other"
END AS ejemplo
FROM limpieza; 


UPDATE limpieza 
SET type = 
CASE
	WHEN type = 1 THEN 'remote'
    WHEN type = 0 THEN 'hybrid'
    ELSE 'other'
END;

call limp();


-- columna salario
-- esta consulta asi me arroja los valores que quiero pero en diferentes columnas
-- por lo tanto, debe ser anidada

SELECT salary, 
			REPLACE(salary, '$',''),
            REPLACE(salary, ',',''),
            TRIM(salary) as salario 
FROM limpieza;

-- asi quedaria:

SELECT salary, 
			 CAST(TRIM(REPLACE(REPLACE(salary,'$',''),',','')) AS DECIMAL(15,2)) AS salary_new
FROM limpieza;

-- AHORA SI, CAMBIO LA COLUMNA PERMANENTEMENTE

UPDATE limpieza SET salary =  CAST(TRIM(REPLACE(REPLACE(salary,'$',''),',','')) AS DECIMAL(15,2));

call limp();

alter table limpieza modify column salary int null;

-- AHORA TRABAJO CON FECHAS

CALL limp();
 SELECT birth_date FROM limpieza;
 
 -- voy a darle formato año, mes, dia.
 -- uso dos funciones stringtodate, dateformat
 
 SELECT birth_date, CASE
		 WHEN birth_date like '%/%' THEN date_format(str_to_date(birth_date, '%m/%d/%y'),'%y-%m-%d')
          WHEN birth_date like '%-%' THEN date_format(str_to_date(birth_date, '%m-%d-%y'),'%y-%m-%d')
          ELSE null
	END AS new_birth_date
FROM limpieza;


          
	UPDATE limpieza 
SET birth_date = CASE 
    WHEN birth_date LIKE '%/%' THEN 
        DATE_FORMAT(STR_TO_DATE(birth_date, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN birth_date LIKE '%-%' THEN 
        DATE_FORMAT(STR_TO_DATE(birth_date, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE 
        NULL
END;

ALTER TABLE limpieza modify column birth_date date;

CALL limp();

-- hago lo mismo con start_date 
UPDATE limpieza 
SET start_date = CASE 
    WHEN start_date LIKE '%/%' THEN 
        DATE_FORMAT(STR_TO_DATE(start_date, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN start_date LIKE '%-%' THEN 
        DATE_FORMAT(STR_TO_DATE(start_date, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE 
        NULL
END;

ALTER TABLE limpieza modify column start_date date;

SELECT finish_date FROM limpieza;

select finish_date,
	date_format(finish_date, '%H') as hour,
    date_format(finish_date, '%i') as minutes,
    date_format(finish_date, '%s') as seconds,
    date_format(finish_date, '%H:%i:%s') as hour_temp
FROM limpieza;

-- copia de seguridad de finish_date

ALTER TABLE limpieza ADD COLUMN date_backup text;

UPDATE limpieza set date_backup = finish_date;

-- ya tenemos nuestra copia de respaldo

SELECT finish_date, str_to_date(finish_date, '%Y-%m-%d %H:%i:%s') AS fecha from limpieza;

UPDATE limpieza SET finish_date = str_to_date(finish_date, '%Y-%m-%d %H:%i:%s')
WHERE finish_date <> '';

UPDATE limpieza 
SET finish_date = STR_TO_DATE(REPLACE(finish_date, ' UTC', ''), '%Y-%m-%d %H:%i:%s')
WHERE finish_date <> '';

call limp();

-- separo fecha de la hora en la columna finish_date

ALTER TABLE limpieza
	add column fecha date,
    add column hora time;

UPDATE limpieza SET
fecha = date(finish_date),
hora = time(finish_date)
WHERE finish_date is not null and finish_date <>'';


-- como en nuestra columna tenemos espacios en blanco cuando hagamos una actualizacion nos arrojara error
-- convierto los espacios en blancos en valores nulos
 
 UPDATE limpieza SET finish_date = null where finish_date = '';

ALTER TABLE limpieza modify column finish_date datetime;

DESCRIBE limpieza;
