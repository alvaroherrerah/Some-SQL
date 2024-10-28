
------------------------------------------------------------------
------------------------------------------------------------------

-- Ejercicio 1: 1. Análisis completo de ventas y beneficio por producto
-- Pregunta:
-- Recupera el total de ventas, la suma de unidades vendidas, el beneficio y el beneficio
-- promedio para "Abbot Industries" en el año 2020, agrupando los resultados por la
-- categoría de producto.

-- POR ORDEN

SELECT CATEGORY AS Categoria,                                    -- aunque no se pide, la categoría nos da bastante info
       SUM(TOTAL) AS TOTAL_VENTAS,                  -- nº total de ventas 
       SUM(UNITS_SOLD) AS SUMA_UNIDADES_VENDIDAS,   -- sumamos las unidades vendidas
       PROFIT AS BENEFICIO,                         -- extraemos el beneficio
       ROUND(AVG(PROFIT), 2) AS BENEFICIO_PROMEDIO  -- y el promedio del beneficio redondeado a 2 decimales
FROM SALES                                          -- todo ello desde sales                                    
WHERE ACCOUNT = 'Abbot Industries' AND YEAR = 2020  -- para aquellos casos procedentes de abbot y del año 2020
GROUP BY CATEGORY, PROFIT;                          -- y agrupamos por categoría (y necesariamente con profit)

------------------------------------------------------------------
------------------------------------------------------------------

-- Ejercicio 2

-- Cálculo de pronóstico total y beneficio esperado
-- Pregunta:
-- Calcula el pronóstico total de ventas y el beneficio para todas las cuentas en el primer
-- trimestre de 2020 y el tercer trimestre de 2021, clasificando los resultados por Forecast
-- Category. Además, muestra la oportunidad más antigua y la más reciente dentro de
-- cada categoría.

-- POR ORDEN

SELECT F.CATEGORY AS Categoria,                -- aunque esta no es solicitada aquí nos aporta información 
       SUM(F.FORECAST) AS Pronostico_Ventas,    -- el pronostico total de ventas para ese periodo y todas las cuentas
       SUM(S.PROFIT) AS Beneficio_Categoria,   -- el beneficio por categoría
       MAX(OPPORTUNITY_AGE) AS Oportunidad_Mas_Antigua,  -- la oportunidad más antigua (más días abierta)
       MIN(OPPORTUNITY_AGE) AS Oportunidad_Mas_reciente   -- la oportunidad menos antigua (menos días abierta)
FROM FORECASTS AS F                                    -- dado que necesitamos variables de dos bases de datos hacemos join
INNER JOIN SALES AS S                                  -- y de los elementos presentes en ambas tablas
ON F.ACCOUNT = S.ACCOUNT 
WHERE QUARTER = '2020 Q1' OR QUARTER = '2021 Q3'     -- en el periodo solicitado
GROUP BY F.CATEGORY;                                  -- y agrupado por la categoría

------------------------------------------------------------------
------------------------------------------------------------------

-- Ejercicio 3
-- Comparación de ventas, unidades vendidas y beneficio entre industrias en APAC
-- Pregunta:
-- Realiza un análisis comparativo del rendimiento de ventas por industria y país en las
-- regiones APAC y EMEA. Muestra el ingreso por producto, mantenimiento, partes y
-- soporte, así como el total de ventas, el número de unidades vendidas, el beneficio total,
-- el beneficio promedio y el beneficio máximo. Agrupa los resultados por industria y país,
-- y ordena el resultado por el beneficio promedio.

-- POR ORDEN

SELECT A.INDUSTRY AS Industria,                    -- seleccionamos industria (aunque no es necesario especifico el database)
       A.COUNTRY AS Pais,                          -- lo mismo con el pais
       SUM(S.PRODUCT) AS Ingreso_producto,         -- a partir de aquí comenzamos con las funciones de agregación
       SUM(S.MAINTENANCE) AS Ingreso_mantenimiento, 
       SUM(S.PARTS) AS Ingreso_partes,
       SUM(S.SUPPORT) AS ingreso_soporte,
       SUM(S.TOTAL) AS Total_ventas,
       SUM(S.UNITS_SOLD) AS Total_unidades_vendidas,
       SUM(S.PROFIT) AS Beneficio_total,
       AVG(S.PROFIT) AS Beneficio_Promedio,
       MAX(S.PROFIT) AS Maximo_beneficio           -- una vez hemos calculado lo que nos piden hacemos el join
FROM ACCOUNTS AS A
INNER JOIN SALES AS S                              -- de nuevo INNER para mantener los casos comunes a ambos
ON A.ACCOUNT = S.ACCOUNT
WHERE REGION = 'APAC' OR REGION = 'EMEA'           -- con la condición que se nos pide (con or pq solo estan en una)
GROUP BY A.INDUSTRY, A.COUNTRY                     -- agrupamos por industria y pais (lo añadí en select para más info)
ORDER BY Beneficio_Promedio DESC;                  -- y ordeno por el promedio (aunque no especifica, descendiente)

------------------------------------------------------------------
------------------------------------------------------------------

-- Ejercicio 4

-- Subconsulta para analizar el beneficio por tipo de empresa
-- Pregunta:
-- Utiliza una subconsulta en la cláusula WHERE para recuperar las cuentas cuyo
-- pronóstico total en 2020 sea superior a $500,000, agrupando los resultados por tipo de industria. Incluye el desglose de ventas por Product ($), Maintenance ($), Parts ($) y
-- Support ($), y muestra las unidades vendidas y el beneficio. Además, clasifica el
-- beneficio como "Alto" o "Normal" en función de si supera los $1.000.000.

-- POR ORDEN

SELECT INDUSTRY AS Industria,                         -- aquí simplemente sacamos nuestras variables
       SUM(S_1.PRODUCT) AS Ventas_producto,           -- y las funciones agregadas
       SUM(S_1.SUPPORT) AS Ventas_soporte, 
       SUM(S_1.MAINTENANCE) AS Ventas_mantenimiento, 
       SUM(S_1.PARTS) AS Ventas_partes, 
       SUM(S_1.UNITS_SOLD) AS unidades_vendidas, 
       SUM(S_1.PROFIT) AS Beneficio,
       CASE 
        WHEN SUM(S_1.PROFIT) > 1000000 THEN 'Alto'    -- utilizamos un case para catalogar nuestro beneficio
        ELSE 'Normal'
       END AS Clasificacion_beneficio                 -- y generamos la nueva variable
FROM ACCOUNTS AS A
FULL JOIN SALES AS S_1
ON A.ACCOUNT = S_1.ACCOUNT
WHERE A.ACCOUNT IN (-- EN TERCER LUGAR <- utilizamos aquellas cuentas que se encuentren en aquellas que cumplen la condición
                    SELECT ACCOUNT FROM (  -- EN SEGUNDO LUGAR <-
                        SELECT  F.ACCOUNT,                  -- EMPEZANDO POR AQUÍ <- 
                                SUM(F.FORECAST) AS SUMA 
                        FROM FORECASTS AS F                  -- extraemos las cuentas y su pronostico total 
                        INNER JOIN SALES AS S
                        ON F.ACCOUNT = S.ACCOUNT
                        WHERE F.YEAR = 2022                 -- para 2022
                        GROUP BY F.ACCOUNT
                        )
                    WHERE SUMA > 500000)   -- extraemos aquellas cuentas donde su SUMA cumpla la condicion
GROUP BY INDUSTRY;    -- y por ultimo, agrupamos por industria

------------------------------------------------------------------
------------------------------------------------------------------

-- Ejercicio 5

-- Función de ventana para acumulación de beneficio por industria
-- Pregunta:
-- Muestra la distribución de cuentas por industria, junto con el beneficio total por
-- trimestre, el beneficio acumulado por trimestre dentro de cada industria, el beneficio
-- global por industria, y el pronóstico total acumulado para cada industria. Además,
-- incluye las oportunidades más recientes y más antiguas para cada industria y trimestre.
-- Utiliza una subconsulta en el FROM para calcular el beneficio total, el forecast y las
-- oportunidades por industria y trimestre. Emplea funciones de ventana para calcular el
-- beneficio acumulado, el beneficio global y el pronóstico acumulado por industria.
-- Finalmente, ordena el resultado por industria y trimestre.

-- POR ORDEN

SELECT  A.ACCOUNT AS Cuenta,     -- EN PRIMER LUGAR: vamos a extraer variables a través de funciones ventana
        A.INDUSTRY AS Industria,
        SUM(S.PROFIT) OVER (PARTITION BY S.QUARTER_OF_YEAR) AS Beneficio_Total_T,
        SUM(S.PROFIT) OVER (PARTITION BY A.INDUSTRY ORDER BY S.QUARTER_OF_YEAR) AS Beneficio_Acumulado_T,
        SUM(S.PROFIT) OVER (PARTITION BY A.INDUSTRY) AS Beneficio_Global_I,
        SUM(F.FORECAST) OVER (PARTITION BY A.INDUSTRY) AS Pronostico_Acumulado_I,
        Beneficio_total,         -- EN SEGUNDO LUGAR: seleccionamos las variables pertenecientes a la subquerry del FROM
        Pronostico_total,
        Oportunidad_M_A,
        Oportunidad_M_R
FROM ACCOUNTS AS A                -- hacemos todos los join necesarios entre nuestras tres bases de datos
INNER JOIN SALES AS S 
ON A.ACCOUNT = S.ACCOUNT
INNER JOIN FORECASTS AS F 
ON A.ACCOUNT = F.ACCOUNT
INNER JOIN (                      -- pero tambien con nuestra subquerry del DROM
    SELECT  A.INDUSTRY AS Industria,
            S.QUARTER_OF_YEAR AS Trimestre,
            SUM(S.PROFIT) AS Beneficio_total,     -- calculamos las variables agregadas
            SUM(FORECAST) AS Pronostico_total,
            MAX(F.OPPORTUNITY_AGE) AS Oportunidad_M_A,
            MIN(F.OPPORTUNITY_AGE) AS Oportunidad_M_R
    FROM FORECASTS AS F    -- haciendo de nuevo join entre nuestras tres variables
    INNER JOIN SALES AS S 
    ON F.ACCOUNT = S.ACCOUNT
    INNER JOIN ACCOUNTS AS A 
    ON F.ACCOUNT = A.ACCOUNT
    GROUP BY A.INDUSTRY, S.QUARTER_OF_YEAR     -- y por último agrupamos por industria y trimestre
) AS T 
ON A.INDUSTRY = T.Industria       -- terminamos el último join con la subquerry del from
ORDER BY A.INDUSTRY, S.QUARTER_OF_YEAR;    -- y ordenamos por industria y trimestre


------------------------------------------------------------------
------------------------------------------------------------------

-- Caso Práctico: Análsis Libre

-- Hipótesis sobre el crecimiento por región:
-- Primera query para saber crecimiento anual:

SELECT A.REGION,                  -- queremos ver los ingresos, beneficio de las regiones en dichos años
       S.YEAR AS Anno,
       SUM(S.TOTAL) AS Ingreso_Total,
       SUM(S.PROFIT) AS Beneficio_Total
FROM SALES AS S
INNER JOIN ACCOUNTS AS A          -- hacemos un join 
ON A.ACCOUNT = S.ACCOUNT
WHERE Anno = 2020 OR Anno = 2021  -- y establecemos la condicion
GROUP BY A.REGION, Anno;       -- agrupamos por región y año

-- Segunda query para comparar ingresos por catgoría:

SELECT A.REGION AS Region,          -- en este caso queremos ver ingresos de manera específica entre regiones
       SUM(S.PROFIT) AS Beneficio,
       SUM(F.FORECAST) AS Pronostico_VENTAS,
       SUM(S.MAINTENANCE) AS Ingreso_Mantenimiento,
       SUM(S.PARTS) AS Ingreso_Partes,
       SUM(S.PRODUCT) AS Ingreso_Producto,
       SUM(S.SUPPORT) AS Ingreso_Soporte,
       SUM(S.TOTAL) AS Total_Ingreso,
       SUM(S.UNITS_SOLD) AS Total_Unidades_Vendidas
FROM ACCOUNTS AS A
INNER JOIN SALES AS S
ON S.ACCOUNT = A.ACCOUNT          -- de nuevo hacemos un join
INNER JOIN FORECASTS AS F
ON F.ACCOUNT = A.ACCOUNT
WHERE S.YEAR = 2020 OR S.YEAR = 2021  -- con la condición
GROUP BY Region
ORDER BY Total_Ingreso DESC;         -- y agrupamos

-- Terecera query para explorar la mejor región:

SELECT A.REGION AS Region, -- en este caso queremos ver ingresos de manera específica entre regiones
       A.INDUSTRY AS Industria, 
       SUM(S.PROFIT) AS Beneficio, 
       SUM(F.FORECAST) AS Pronostico_VENTAS,
       SUM(S.TOTAL) AS Total_Ingreso
FROM ACCOUNTS AS A
INNER JOIN SALES AS S
ON S.ACCOUNT = A.ACCOUNT   -- de nuevo hacemos un join
INNER JOIN FORECASTS AS F
ON F.ACCOUNT = A.ACCOUNT
WHERE (S.YEAR = 2020 OR S.YEAR = 2021) AND Region = 'EMEA'    -- con la condición
GROUP BY Region, Industria
ORDER BY Total_Ingreso DESC;   -- y agrupamos












