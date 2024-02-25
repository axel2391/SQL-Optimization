--**************************************OPTIMIZADOR DE CONSULTAS MICROSOFT SQL SERVER*****************************
--Elaborado por: Msc. Axel D. Herrera Carcamo                                                            
--Institucion: Alcaldia Municipal Del Distrito Central
-- Pais: Honduras
-- Descripcion: Documento que contiene la guia de las mejores practicas para optimizar las consultas ETL que se 
-- utilizaran para construir los reportes, cubos de datos, consultas especializadas y Procedimientos almacenados
--para jecutar tareas programadas para envios de reportes en excel via correo electronico.
--***************************************************************************************************************

--1. Sustituir la clausula LIKE por la funcion REGEXP_LIKE

--FORMA INCORRECTA
SELECT * 
FROM 
    TABLE1
WHERE 
    lower(Columna1) LIKE '%samsung%' OR
    lower(Columna1) LIKE '%xiaomi%' OR
    lower(Columna1) LIKE '%iphone%' OR
    lower(Columna1) LIKE '%huawei%' ;

--FORMA CORRECTA
SELECT * 
FROM 
    TABLE1
WHERE 
    REGEXP(Lower(columna1), 
    'samsung|xiamoni|iphone|huawei', 'i');

-- 2. Sustituir la clausula CASE/WHEN por la funcion REGEXP_EXTRACT

--FORMA INCORRECTA
SELECT
CASE 
    WHEN concat(' ',Columna1,' ') LIKE '%acer%' THEN 'Acer'
    WHEN concat(' ',Columna1,' ') LIKE '%advance%' THEN 'Advance'
    ELSE  'Alfalink'
END AS Brand
FROM 
    TABLE1;

--FORMA CORRECTA
SELECT
    REGEXP_EXTRACT(Columna1, '(asus|lenovo|hp|acer|advance|alfalink|...)','i')
AS Brand
FROM TABLE1;

--Mejoras:
--Rendimiento: Si la columna Columna1 contiene muchos datos, considera crear un índice en la columna.
--Esto puede mejorar la velocidad de extracción de las marcas.
--Claridad: Puedes agregar comentarios al script para explicar su propósito y la lista de marcas 
--utilizadas.
--Alternativas: Si necesitas extraer todas las marcas coincidentes en lugar de la primera, puedes 
--utilizar expresiones regulares más complejas o técnicas como subconsultas.
--En algunos casos, utilizar tablas de búsqueda o funciones específicas para manejar texto
--(e.g., FREETEXT) podría ser más eficiente o flexible. 

-- 3. Convertir una lista larga con la Clausula IN en una tabla temporal

--FORMA INCORRECTA
SELECT * 
FROM
TABLA1
WHERE
    Columnaid in (123,345,567,892);

--FORMA CORRECTA
SELECT *
FROM
TABLA1 as T1
JOIN (
    SELECT
        Columnaid
    FROM (
        SELECT
            STRING_SPLIT('123,345,567') as bar
    )
    CROSS JOIN
        UNNEST (bar) AS T1(Columnaid)
) AS TABLE2 as T2
ON
    T1.Columnaid = T2.Columnaid;

--NOTA: En este script mejorado:

--1. Se utiliza STRING_SPLIT para dividir la cadena directamente en la cláusula WHERE del JOIN, lo
--que podría ser más eficiente.

-- Adapta el script a tu contexto específico, especialmente si la cadena separada por comas proviene de una fuente 
--externa.
-- Considera probar el script con diferentes datos para asegurarte de que funciona como se espera.

--Mejoras potenciales:

--1. Eficiencia: La consulta actual podría ser menos eficiente si la tabla TABLE1 es grande y la cadena separada por 
--comas contiene muchos valores. En este caso, podrías considerar utilizar una función como STRING_SPLIT para dividir 
--la cadena directamente en la cláusula WHERE del JOIN.
--2. Claridad: El uso de una tabla temporal sin nombre (AS TABLE2) puede dificultar la lectura del código. Considera 
--dar un nombre descriptivo a la tabla temporal para mejorar la claridad del script.
--3. Seguridad: Si la cadena separada por comas proviene de una fuente externa, asegúrate de limpiarla adecuadamente 
--para evitar la inyección de SQL. 

-- 4. Ordena tus clausulas JOIN desde las tablas mas grandes a las tablas mas pequeñas

--FORMA INCORRECTA
SELECT * 
FROM
    SMALLTABLA
JOIN
    LARGESTTABLA
ON SMALLTABLA.ID = LARGESTTABLA.ID;

--FORMA CORRECTA
SELECT 
  LARGETABLA.Nombre, 
  LARGETABLA.Apellido, 
  SMALLTABLA.Telefono
FROM
    LARGETABLA
JOIN
    SMALLTABLA
ON 
    SMALLTABLA.ID = LARGETABLA.ID
WHERE 
    LARGETABLA.Ciudad = 'Madrid';

--Utilizar un índice: Si no existe un índice en la columna ID de la tabla LARGETABLA, se recomienda
--crear uno para mejorar el rendimiento de la consulta.
--Especificar las columnas: En lugar de usar SELECT *, puedes especificar las columnas específicas 
--que necesitas de ambas tablas para mejorar la eficiencia.
--Filtrar los datos: Si solo necesitas un subconjunto de datos, puedes agregar una cláusula WHERE a 
--la sentencia para filtrar los resultados*/

-- 6. Si tienes tablas con fechas en formato string y una de las tablas solo tiene columnas para 
--los valores de DAY, MONTH, YEAR* Usa el siguiente JOIN*/

--FORMA INCORRECTA*/
SELECT *
FROM
    TABLA1 A
JOIN
    TABLA2 B
ON
    A.DATE = CONCAT(B.YEAR,'-', B.MONTH,'-',B.DAY);

--FORMA CORRECTA
SELECT *
FROM
    TABLA1 A
JOIN
    (SELECT
        NAME, CONCAT(B.YEAR,'-', B.MONTH,'-',B.DAY) as DATE
    FROM
        TABLE2 B 
    ) as NEW
ON
    A.DATE = NEW.DATE;

--Rendimiento: Si la tabla TABLE2 es grande, la subconsulta podría afectar negativamente el 
--rendimiento del script. En ese caso, podrías considerar crear una vista materializada de la 
--subconsulta o utilizar un JOIN diferente (por ejemplo, un JOIN utilizando tablas derivadas comunes)

--7. Evita los subquerys en tu clausula WHERE

--FORMA INCORRECTA
SELECT 
    SUM(price)
FROM
    TABLA1 A
WHERE
    itemid in (
        SELECT itemid FROM TABLE2
    );

--FORMA CORRECTA
WITH T2 AS(
    SELECT itemid FROM TABLE2
)

SELECT
    SUM(price) AS TOTAL
FROM
    TABLE1 AS t1
JOIN
    T2
ON
    T1.itemid = T2.itemid;

-- 8. Usa la clausula MAX en lugar de RANK

--FORMA INCORRECTA
SELECT *
FROM (
    SELECT
        userid,
        rank() over (ORDER BY prdate desc) as RANK
    FROM
        TABLE1
)
WHERE RANK = 1

-- FORMA CORRECTA
SELECT
    userid,
    MAX(prdate)
FROM 
    TABLE1
GROUP BY 1
ORDER BY MAX(prdate) DESC;
