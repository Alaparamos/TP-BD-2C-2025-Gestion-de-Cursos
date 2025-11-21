---------------------------------------------------------------------------------------------------
-- 1. BORRADO DE OBJETOS (Limpieza inicial)
---------------------------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.schemas WHERE name = 'NORMALIZADOS')
BEGIN
    -- Vistas
    DROP VIEW IF EXISTS [NORMALIZADOS].[Vista_01_Categorias_Turnos_Mas_Solicitados];
    DROP VIEW IF EXISTS [NORMALIZADOS].[Vista_02_Tasa_Rechazo_Inscripciones];
    DROP VIEW IF EXISTS [NORMALIZADOS].[Vista_03_Desempeno_Cursada];
    DROP VIEW IF EXISTS [NORMALIZADOS].[Vista_04_Tiempo_Promedio_Finalizacion];
    DROP VIEW IF EXISTS [NORMALIZADOS].[Vista_05_Promedio_Nota_Finales];
    DROP VIEW IF EXISTS [NORMALIZADOS].[Vista_06_Ausentismo_Finales];
    DROP VIEW IF EXISTS [NORMALIZADOS].[Vista_07_Desvio_Pagos];
    DROP VIEW IF EXISTS [NORMALIZADOS].[Vista_08_Morosidad_Mensual];
    DROP VIEW IF EXISTS [NORMALIZADOS].[Vista_09_Ingresos_Categoria];
    DROP VIEW IF EXISTS [NORMALIZADOS].[Vista_10_Indice_Satisfaccion];

    -- Tablas de Hechos
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_INSCRIPCION];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_EXAMEN_FINAL];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_CURSADA];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_PAGO];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_ENCUESTA];

    -- Tablas de Dimensiones
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_DIM_TIEMPO];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_DIM_ALUMNO];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_DIM_PROFESOR];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_DIM_CURSO];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_DIM_SEDE];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_DIM_MEDIO_PAGO];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_DIM_RANGO_ETARIO];

    -- Procedures
    DROP PROCEDURE IF EXISTS [NORMALIZADOS].[sp_migrar_bi_dimensiones];
    DROP PROCEDURE IF EXISTS [NORMALIZADOS].[sp_migrar_bi_hechos];
    
    -- Funciones
    DROP FUNCTION IF EXISTS [NORMALIZADOS].[fx_obtener_cuatrimestre];
    DROP FUNCTION IF EXISTS [NORMALIZADOS].[fx_obtener_rango_etario];
END
GO

-- Crear Esquema si no existe
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'NORMALIZADOS')
BEGIN
    EXEC('CREATE SCHEMA [NORMALIZADOS]')
END
GO

---------------------------------------------------------------------------------------------------
-- 2. FUNCIONES AUXILIARES
---------------------------------------------------------------------------------------------------

-- Función para calcular cuatrimestre (1 o 2)
CREATE FUNCTION [NORMALIZADOS].[fx_obtener_cuatrimestre](@fecha DATETIME2)
RETURNS INT
AS
BEGIN
    RETURN CASE WHEN MONTH(@fecha) <= 6 THEN 1 ELSE 2 END
END
GO

-- Función para calcular Rango Etario según enunciado
CREATE FUNCTION [NORMALIZADOS].[fx_obtener_rango_etario](@fecha_nacimiento DATETIME2)
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @edad INT = DATEDIFF(YEAR, @fecha_nacimiento, GETDATE());
    DECLARE @rango VARCHAR(50);

    IF @edad < 25 SET @rango = '< 25';
    ELSE IF @edad BETWEEN 25 AND 35 SET @rango = '25 - 35';
    ELSE IF @edad BETWEEN 36 AND 50 SET @rango = '35 - 50'; -- Ajuste para no solapar
    ELSE SET @rango = '> 50';

    RETURN @rango;
END
GO

---------------------------------------------------------------------------------------------------
-- 3. CREACIÓN DE TABLAS DIMENSIONALES
---------------------------------------------------------------------------------------------------

CREATE TABLE [NORMALIZADOS].[BI_DIM_TIEMPO] (
    TIEMPO_ID INT IDENTITY(1,1) PRIMARY KEY,
    ANIO INT,
    MES INT,
    CUATRIMESTRE INT
);

CREATE TABLE [NORMALIZADOS].[BI_DIM_SEDE] (
    SEDE_ID BIGINT PRIMARY KEY,
    SEDE_NOMBRE VARCHAR(255)
);

CREATE TABLE [NORMALIZADOS].[BI_DIM_CURSO] (
    CURSO_CODIGO BIGINT PRIMARY KEY,
    CURSO_NOMBRE VARCHAR(255),
    CURSO_CATEGORIA VARCHAR(255),
    CURSO_TURNO VARCHAR(255)
);

CREATE TABLE [NORMALIZADOS].[BI_DIM_ETARIO_ALUMNO] (
    ALUMNO_LEGAJO BIGINT PRIMARY KEY,
    ALUMNO_RANGO_ETARIO VARCHAR(50) -- <25, 25-35, 35-50, >50
);

CREATE TABLE [NORMALIZADOS].[BI_DIM_ETARIO_PROFESOR] (
    PROFESOR_ID BIGINT PRIMARY KEY,
    PROFESOR_RANGO_ETARIO VARCHAR(50) -- 25-35, 35-50, >50
);

CREATE TABLE [NORMALIZADOS].[BI_DIM_MEDIO_PAGO] (
    MEDIO_PAGO_ID INT IDENTITY(1,1) PRIMARY KEY,
    MEDIO_PAGO_NOMBRE VARCHAR(255)
);

---------------------------------------------------------------------------------------------------
-- 4. CREACI�N DE TABLAS DE HECHOS
---------------------------------------------------------------------------------------------------

-- HECHO 1: Inscripciones (Para Vistas 1 y 2)
CREATE TABLE [NORMALIZADOS].[BI_HECHOS_INSCRIPCION] (
    TIEMPO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
    SEDE_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_SEDE](SEDE_ID),
    CURSO_CODIGO BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_CURSO](CURSO_CODIGO),
    CANTIDAD_INSCRIPTOS INT,
    ESTADO_INSCRIPCION VARCHAR(50) -- 'Confirmada', 'Rechazada'
);

-- HECHO 2: Cursadas y Desempeño (Para Vistas 3 y 4)
-- Relaciona el inicio del curso con la aprobación final
CREATE TABLE [NORMALIZADOS].[BI_HECHOS_CURSADA] (
    TIEMPO_INICIO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
    SEDE_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_SEDE](SEDE_ID),
    CURSO_CODIGO BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_CURSO](CURSO_CODIGO),
    CURSADA_APROBADA BIT, -- 1 si aprobó (Notas >=4 y TP), 0 si no
    TIEMPO_FINALIZACION_MESES INT -- Diferencia entre inicio curso y aprobación final
);

-- HECHO 3: Ex�menes Finales (Para Vistas 5 y 6)
CREATE TABLE [NORMALIZADOS].[BI_HECHOS_EXAMEN_FINAL] (
    TIEMPO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
    SEDE_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_SEDE](SEDE_ID),
    CURSO_CODIGO BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_CURSO](CURSO_CODIGO),
    ALUMNO_LEGAJO BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_ETARIO_ALUMNO](ALUMNO_LEGAJO),
    PROFESOR_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_ETARIO_PROFESOR](PROFESOR_ID),
    NOTA_FINAL DECIMAL(5,2),
    ES_AUSENTE BIT, -- 1 Si ausente, 0 si presente
);

-- HECHO 4: Pagos y Facturaci�n (Para Vistas 7, 8 y 9)
CREATE TABLE [NORMALIZADOS].[BI_HECHOS_PAGO] (
    TIEMPO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
    SEDE_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_SEDE](SEDE_ID),
    CURSO_CODIGO BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_CURSO](CURSO_CODIGO),
    MEDIO_PAGO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_MEDIO_PAGO](MEDIO_PAGO_ID),
    IMPORTE_PAGADO DECIMAL(18,2),
    IMPORTE_ADEUDADO DECIMAL(18,2), -- Importe Facturado no pagado en el mes
    PAGO_EN_TERMINO BIT, -- 1 Si, 0 No (o Pago Tard�o)
    PAGO_FUERA_TERMINO BIT -- 1 Si pag� vencido, 0 Si pag� en t�rmino
);

-- HECHO 5: Encuestas (Para Vista 10)
CREATE TABLE [NORMALIZADOS].[BI_HECHOS_ENCUESTA] (
    TIEMPO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
    SEDE_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_SEDE](SEDE_ID),
    PROFESOR_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_ETARIO_PROFESOR](PROFESOR_ID),
    ES_SATISFECHO INT, -- Nota 7-10
    ES_NEUTRAL INT,    -- Nota 5-6
    ES_INSATISFECHO INT -- Nota 1-4
);
GO

---------------------------------------------------------------------------------------------------
-- 5. PROCEDIMIENTOS DE MIGRACI�N
---------------------------------------------------------------------------------------------------

CREATE PROCEDURE [NORMALIZADOS].[sp_migrar_bi_dimensiones] AS
BEGIN
    -- 1. Migrar Dimension TIEMPO (Generamos fechas desde Inscripciones, Pagos y Examenes)
    --    Estrategia: Unir todas las tablas de fecha, sacar distinct A�o/Mes.
    INSERT INTO [NORMALIZADOS].[BI_DIM_TIEMPO] (ANIO, MES, CUATRIMESTRE)
    SELECT DISTINCT YEAR(Fecha), MONTH(Fecha), [NORMALIZADOS].[fx_obtener_cuatrimestre](Fecha)
    FROM (
        SELECT Inscripcion_Fecha AS Fecha FROM [NORMALIZADOS].[Inscripcion]
        UNION
        SELECT Pago_Fecha FROM [NORMALIZADOS].[Pago]
        UNION
        SELECT Factura_FechaEmision FROM [NORMALIZADOS].[Factura]
        UNION
        SELECT Examen_Final_Fecha FROM [NORMALIZADOS].[Examen_Final]
        UNION
        SELECT Encuesta_FechaRegistro FROM [NORMALIZADOS].[Encuesta]
    ) AS Fechas
    WHERE Fecha IS NOT NULL
    ORDER BY 1, 2;

    -- 2. Migrar Dimension SEDE
    INSERT INTO [NORMALIZADOS].[BI_DIM_SEDE] (SEDE_ID, SEDE_NOMBRE)
    SELECT Sede_ID, Sede_Nombre FROM [NORMALIZADOS].[Sede];

    -- 3. Migrar Dimension CURSO (Incluye Categoria)
    INSERT INTO [NORMALIZADOS].[BI_DIM_CURSO] (CURSO_CODIGO, CURSO_NOMBRE, CURSO_CATEGORIA, CURSO_TURNO)
    SELECT c.Curso_Codigo, c.Curso_Nombre, cat.Categoria_Descripcion, c.Curso_Turno
    FROM [NORMALIZADOS].[Curso] c
    JOIN [NORMALIZADOS].[Categoria] cat ON c.Categoria_ID = cat.Categoria_ID;

    -- 4. Migrar Dimension ALUMNO (Con c�lculo de Rango Etario)
    INSERT INTO [NORMALIZADOS].[BI_DIM_ETARIO_ALUMNO] (ALUMNO_LEGAJO, ALUMNO_RANGO_ETARIO)
    SELECT Alumno_Legajo, [NORMALIZADOS].[fx_obtener_rango_etario](Alumno_FechaNacimiento)
    FROM [NORMALIZADOS].[Alumno];

    -- 5. Migrar Dimension PROFESOR (Con c�lculo de Rango Etario)
    INSERT INTO [NORMALIZADOS].[BI_DIM_ETARIO_PROFESOR] (PROFESOR_ID, PROFESOR_RANGO_ETARIO)
    SELECT Profesor_ID, [NORMALIZADOS].[fx_obtener_rango_etario](Profesor_FechaNacimiento)
    FROM [NORMALIZADOS].[Profesor];

    -- 6. Migrar Dimension MEDIO PAGO
    INSERT INTO [NORMALIZADOS].[BI_DIM_MEDIO_PAGO] (MEDIO_PAGO_NOMBRE)
    SELECT DISTINCT Pago_MedioPago FROM [NORMALIZADOS].[Pago] WHERE Pago_MedioPago IS NOT NULL;
END
GO

CREATE OR ALTER PROCEDURE [NORMALIZADOS].[sp_migrar_bi_hechos] AS
BEGIN
    -- ------------------------------------------
    -- MIGRACION HECHOS INSCRIPCION
    -- ------------------------------------------
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_INSCRIPCION] (TIEMPO_ID, SEDE_ID, CURSO_CODIGO, CANTIDAD_INSCRIPTOS, ESTADO_INSCRIPCION)
    SELECT 
        t.TIEMPO_ID,
        cur.Sede_ID,
        cur.Curso_Codigo,
        COUNT(*) AS CANTIDAD_INSCRIPTOS,
        i.Inscripcion_Estado
    FROM [NORMALIZADOS].[Inscripcion] i
    JOIN [NORMALIZADOS].[Curso] cur ON i.Curso_Codigo = cur.Curso_Codigo
    INNER JOIN [NORMALIZADOS].[Categoria] ca ON cur.Categoria_ID = ca.Categoria_ID
    JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(i.Inscripcion_Fecha) = t.ANIO AND MONTH(i.Inscripcion_Fecha) = t.MES
    GROUP BY 
        t.TIEMPO_ID,
        cur.Sede_ID,
        cur.Curso_Codigo,
        cur.Curso_Turno,
        ca.Categoria_ID,
        i.Inscripcion_Estado;

SELECT * 
FROM [NORMALIZADOS].[Inscripcion] i
    JOIN [NORMALIZADOS].[Curso] cur ON i.Curso_Codigo = cur.Curso_Codigo
    INNER JOIN [NORMALIZADOS].[Categoria] ca ON cur.Categoria_ID = ca.Categoria_ID
    JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(i.Inscripcion_Fecha) = t.ANIO AND MONTH(i.Inscripcion_Fecha) = t.MES

SELECT * FROM [NORMALIZADOS].[Inscripcion]

    -- ------------------------------------------
    -- MIGRACION HECHOS CURSADA
    -- ------------------------------------------
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_CURSADA] (TIEMPO_INICIO_ID, SEDE_ID, CURSO_CODIGO, CURSADA_APROBADA, TIEMPO_FINALIZACION_MESES)
    SELECT
        t.TIEMPO_ID,
        c.Sede_ID,
        c.Curso_Codigo,
        -- Logica de Aprobado:
        CASE WHEN 
            -- 1. Verificamos que la nota M�NIMA de los parciales de este alumno en este curso sea >= 4
            (SELECT MIN(exa.Evaluacion_Nota) 
             FROM [NORMALIZADOS].[Evaluacion_x_Alumno] exa 
             WHERE exa.Alumno_Legajo = i.Alumno_Legajo 
             AND exa.Evaluacion_Curso_ID IN (
                -- AQUI ESTABA EL ERROR: Seleccionamos el ID de la evaluaci�n, usando el alias 'ec'
                SELECT ec.Evaluacion_Curso_ID 
                FROM [NORMALIZADOS].[Evaluacion_Curso] ec 
                JOIN [NORMALIZADOS].[Modulo_x_Curso] mxc ON ec.Modulo_ID = mxc.Modulo_ID 
                WHERE mxc.Curso_Codigo = c.Curso_Codigo
             )
            ) >= 4
            AND 
            -- 2. Verificamos que la nota del TP sea >= 4
            (SELECT MAX(tp.Trabajo_Practico_Nota) 
             FROM [NORMALIZADOS].[Trabajo_Practico] tp 
             WHERE tp.Alumno_Legajo = i.Alumno_Legajo 
             AND tp.Curso_Codigo = c.Curso_Codigo
            ) >= 4
        THEN 1 ELSE 0 END,
        
        -- Tiempo Finalizacion
        DATEDIFF(MONTH, c.Curso_FechaInicio, 
            (SELECT TOP 1 ef.Examen_Final_Fecha FROM [NORMALIZADOS].[Examen_Final] ef 
             JOIN [NORMALIZADOS].[Evaluacion_Final] evf ON ef.Examen_Final_ID = evf.Examen_Final_ID
             WHERE evf.Alumno_Legajo = i.Alumno_Legajo AND ef.Curso_Codigo = c.Curso_Codigo AND evf.Evaluacion_Final_Nota >= 4
             ORDER BY ef.Examen_Final_Fecha DESC)
        )
    FROM [NORMALIZADOS].[Inscripcion] i
    JOIN [NORMALIZADOS].[Curso] c ON i.Curso_Codigo = c.Curso_Codigo
    JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(c.Curso_FechaInicio) = t.ANIO AND MONTH(c.Curso_FechaInicio) = t.MES
    WHERE i.Inscripcion_Estado = 'Confirmada'; 

    -- ------------------------------------------
    -- MIGRACION HECHOS EXAMEN FINAL
    -- ------------------------------------------
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_EXAMEN_FINAL] (TIEMPO_ID, SEDE_ID, CURSO_CODIGO, ALUMNO_LEGAJO, PROFESOR_ID, NOTA_FINAL, ES_AUSENTE)
    SELECT 
        t.TIEMPO_ID,
        c.Sede_ID,
        ef.Curso_Codigo,
        ev.Alumno_Legajo,
        ev.Profesor_ID,
        ev.Evaluacion_Final_Nota,
        CASE WHEN ev.Evaluacion_Final_Presente = 0 THEN 1 ELSE 0 END
    FROM [NORMALIZADOS].[Evaluacion_Final] ev
    JOIN [NORMALIZADOS].[Examen_Final] ef ON ev.Examen_Final_ID = ef.Examen_Final_ID
    JOIN [NORMALIZADOS].[Curso] c ON ef.Curso_Codigo = c.Curso_Codigo
    JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(ef.Examen_Final_Fecha) = t.ANIO AND MONTH(ef.Examen_Final_Fecha) = t.MES;

    -- ------------------------------------------
    -- MIGRACION HECHOS PAGO
    -- ------------------------------------------
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_PAGO] (TIEMPO_ID, SEDE_ID, CURSO_CODIGO, MEDIO_PAGO_ID, IMPORTE_PAGADO, IMPORTE_ADEUDADO, PAGO_EN_TERMINO, PAGO_FUERA_TERMINO)
    SELECT
        t.TIEMPO_ID,
        c.Sede_ID,
        df.Curso_Codigo,
        mp.MEDIO_PAGO_ID,
        p.Pago_Importe,
        0, 
        CASE WHEN p.Pago_Fecha <= f.Factura_FechaVencimiento THEN 1 ELSE 0 END,
        CASE WHEN p.Pago_Fecha > f.Factura_FechaVencimiento THEN 1 ELSE 0 END
    FROM [NORMALIZADOS].[Pago] p
    JOIN [NORMALIZADOS].[Factura] f ON p.Factura_Numero = f.Factura_Numero
    JOIN [NORMALIZADOS].[Detalle_Factura] df ON f.Factura_Numero = df.Factura_Numero
    JOIN [NORMALIZADOS].[Curso] c ON df.Curso_Codigo = c.Curso_Codigo
    JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(p.Pago_Fecha) = t.ANIO AND MONTH(p.Pago_Fecha) = t.MES
    JOIN [NORMALIZADOS].[BI_DIM_MEDIO_PAGO] mp ON p.Pago_MedioPago = mp.MEDIO_PAGO_NOMBRE;

    -- Insertar DEUDAS 
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_PAGO] (TIEMPO_ID, SEDE_ID, CURSO_CODIGO, MEDIO_PAGO_ID, IMPORTE_PAGADO, IMPORTE_ADEUDADO, PAGO_EN_TERMINO, PAGO_FUERA_TERMINO)
    SELECT 
        t.TIEMPO_ID,
        c.Sede_ID,
        df.Curso_Codigo,
        NULL, 
        0,
        df.Detalle_Factura_Importe, 
        0, 
        0
    FROM [NORMALIZADOS].[Factura] f
    JOIN [NORMALIZADOS].[Detalle_Factura] df ON f.Factura_Numero = df.Factura_Numero
    JOIN [NORMALIZADOS].[Curso] c ON df.Curso_Codigo = c.Curso_Codigo
    JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(f.Factura_FechaEmision) = t.ANIO AND MONTH(f.Factura_FechaEmision) = t.MES
    WHERE NOT EXISTS (SELECT 1 FROM [NORMALIZADOS].[Pago] p WHERE p.Factura_Numero = f.Factura_Numero);


    -- ------------------------------------------
    -- MIGRACION HECHOS ENCUESTA
    -- ------------------------------------------
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_ENCUESTA] (TIEMPO_ID, SEDE_ID, PROFESOR_ID, ES_SATISFECHO, ES_NEUTRAL, ES_INSATISFECHO)
    SELECT
        t.TIEMPO_ID,
        c.Sede_ID,
        c.Profesor_ID,
        CASE WHEN AVG(de.Encuesta_Nota) BETWEEN 7 AND 10 THEN 1 ELSE 0 END,
        CASE WHEN AVG(de.Encuesta_Nota) BETWEEN 5 AND 6 THEN 1 ELSE 0 END,
        CASE WHEN AVG(de.Encuesta_Nota) BETWEEN 1 AND 4 THEN 1 ELSE 0 END
    FROM [NORMALIZADOS].[Encuesta] e
    JOIN [NORMALIZADOS].[Detalle_Encuesta] de ON e.Encuesta_ID = de.Encuesta_ID
    JOIN [NORMALIZADOS].[Curso] c ON e.Curso_Codigo = c.Curso_Codigo
    JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(e.Encuesta_FechaRegistro) = t.ANIO AND MONTH(e.Encuesta_FechaRegistro) = t.MES
    GROUP BY t.TIEMPO_ID, c.Sede_ID, c.Profesor_ID, e.Encuesta_ID;

END
GO

---------------------------------------------------------------------------------------------------
-- 6. EJECUCIÓN DE MIGRACIÓN
---------------------------------------------------------------------------------------------------
BEGIN TRANSACTION
    EXEC [NORMALIZADOS].[sp_migrar_bi_dimensiones];
    EXEC [NORMALIZADOS].[sp_migrar_bi_hechos];
COMMIT TRANSACTION
GO

---------------------------------------------------------------------------------------------------
-- 7. CREACIÓN DE VISTAS
---------------------------------------------------------------------------------------------------

-- 1. Categor�as y turnos m�s solicitados (Top 3 por a�o por sede)
CREATE VIEW [NORMALIZADOS].[Vista_01_Categorias_Turnos_Mas_Solicitados] AS
SELECT TOP 3
    t.ANIO,
    s.SEDE_NOMBRE,
    c.CURSO_CATEGORIA,
    c.CURSO_TURNO,
    COUNT(*) as CANTIDAD_INSCRIPTOS
FROM [NORMALIZADOS].[BI_HECHOS_INSCRIPCION] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
JOIN [NORMALIZADOS].[BI_DIM_SEDE] s ON h.SEDE_ID = s.SEDE_ID
JOIN [NORMALIZADOS].[BI_DIM_CURSO] c ON h.CURSO_CODIGO = c.CURSO_CODIGO
GROUP BY t.ANIO, s.SEDE_NOMBRE, c.CURSO_CATEGORIA, c.CURSO_TURNO
ORDER BY t.ANIO, s.SEDE_NOMBRE, COUNT(*) DESC;
GO

-- 2. Tasa de rechazo de inscripciones (Por mes por sede)
CREATE VIEW [NORMALIZADOS].[Vista_02_Tasa_Rechazo_Inscripciones] AS
SELECT
    t.ANIO,
    t.MES,
    s.SEDE_NOMBRE,
    (SUM(CASE WHEN h.ESTADO_INSCRIPCION = 'Rechazada' THEN 1.0 ELSE 0.0 END) / COUNT(*)) * 100 AS PORCENTAJE_RECHAZO
FROM [NORMALIZADOS].[BI_HECHOS_INSCRIPCION] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
JOIN [NORMALIZADOS].[BI_DIM_SEDE] s ON h.SEDE_ID = s.SEDE_ID
GROUP BY t.ANIO, t.MES, s.SEDE_NOMBRE;
GO

-- 3. Comparación de desempeño de cursada (Aprobación por sede por año)
CREATE VIEW [NORMALIZADOS].[Vista_03_Desempeno_Cursada] AS
SELECT
    t.ANIO,
    s.SEDE_NOMBRE,
    (SUM(CAST(h.CURSADA_APROBADA AS DECIMAL)) / COUNT(*)) * 100 AS PORCENTAJE_APROBACION
FROM [NORMALIZADOS].[BI_HECHOS_CURSADA] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_INICIO_ID = t.TIEMPO_ID
JOIN [NORMALIZADOS].[BI_DIM_SEDE] s ON h.SEDE_ID = s.SEDE_ID
GROUP BY t.ANIO, s.SEDE_NOMBRE;
GO

-- 4. Tiempo promedio de finalización de curso (Por categoria, por a�o)
CREATE VIEW [NORMALIZADOS].[Vista_04_Tiempo_Promedio_Finalizacion] AS
SELECT
    t.ANIO,
    c.CURSO_CATEGORIA,
    AVG(h.TIEMPO_FINALIZACION_MESES) AS PROMEDIO_MESES_FINALIZACION
FROM [NORMALIZADOS].[BI_HECHOS_CURSADA] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_INICIO_ID = t.TIEMPO_ID
JOIN [NORMALIZADOS].[BI_DIM_CURSO] c ON h.CURSO_CODIGO = c.CURSO_CODIGO
WHERE h.TIEMPO_FINALIZACION_MESES IS NOT NULL -- Solo los que terminaron
GROUP BY t.ANIO, c.CURSO_CATEGORIA;
GO

-- 5. Nota promedio de finales (Rango etario alumno, categoria curso, semestre/cuatrimestre)
CREATE VIEW [NORMALIZADOS].[Vista_05_Promedio_Nota_Finales] AS
SELECT
    t.CUATRIMESTRE,
    a.ALUMNO_RANGO_ETARIO,
    c.CURSO_CATEGORIA,
    AVG(h.NOTA_FINAL) AS PROMEDIO_NOTA
FROM [NORMALIZADOS].[BI_HECHOS_EXAMEN_FINAL] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
JOIN [NORMALIZADOS].[BI_DIM_ETARIO_ALUMNO] a ON h.ALUMNO_LEGAJO = a.ALUMNO_LEGAJO
JOIN [NORMALIZADOS].[BI_DIM_CURSO] c ON h.CURSO_CODIGO = c.CURSO_CODIGO
WHERE h.NOTA_FINAL IS NOT NULL
GROUP BY t.CUATRIMESTRE, a.ALUMNO_RANGO_ETARIO, c.CURSO_CATEGORIA;
GO

-- 6. Tasa de ausentismo finales (Por semestre/cuatrimestre, por sede)
CREATE VIEW [NORMALIZADOS].[Vista_06_Ausentismo_Finales] AS
SELECT
    t.CUATRIMESTRE,
    s.SEDE_NOMBRE,
    (SUM(CAST(h.ES_AUSENTE AS DECIMAL)) / COUNT(*)) * 100 AS PORCENTAJE_AUSENTISMO
FROM [NORMALIZADOS].[BI_HECHOS_EXAMEN_FINAL] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
JOIN [NORMALIZADOS].[BI_DIM_SEDE] s ON h.SEDE_ID = s.SEDE_ID
GROUP BY t.CUATRIMESTRE, s.SEDE_NOMBRE;
GO

-- 7. Desv�o de pagos (Porcentaje pagos fuera de termino por semestre/cuatrimestre)
CREATE VIEW [NORMALIZADOS].[Vista_07_Desvio_Pagos] AS
SELECT
    t.CUATRIMESTRE,
    (SUM(CAST(h.PAGO_FUERA_TERMINO AS DECIMAL)) / COUNT(*)) * 100 AS PORCENTAJE_PAGOS_TARDIOS
FROM [NORMALIZADOS].[BI_HECHOS_PAGO] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
WHERE h.IMPORTE_PAGADO > 0 -- Solo miramos registros de pago, no de deuda
GROUP BY t.CUATRIMESTRE;
GO

-- 8. Tasa de Morosidad Financiera mensual (Importe Adeudado / Facturacion Esperada)
-- Facturacion Esperada = Pagado + Adeudado
CREATE VIEW [NORMALIZADOS].[Vista_08_Morosidad_Mensual] AS
SELECT
    t.ANIO,
    t.MES,
    CASE WHEN SUM(h.IMPORTE_PAGADO + h.IMPORTE_ADEUDADO) = 0 THEN 0 
    ELSE (SUM(h.IMPORTE_ADEUDADO) / SUM(h.IMPORTE_PAGADO + h.IMPORTE_ADEUDADO)) * 100 
    END AS TASA_MOROSIDAD
FROM [NORMALIZADOS].[BI_HECHOS_PAGO] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
GROUP BY t.ANIO, t.MES;
GO

-- 9. Ingresos por categor�a de cursos (Top 3 por sede, por a�o)
CREATE VIEW [NORMALIZADOS].[Vista_09_Ingresos_Categoria] AS
SELECT TOP 3 WITH TIES
    t.ANIO,
    s.SEDE_NOMBRE,
    c.CURSO_CATEGORIA,
    SUM(h.IMPORTE_PAGADO) AS TOTAL_INGRESOS
FROM [NORMALIZADOS].[BI_HECHOS_PAGO] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
JOIN [NORMALIZADOS].[BI_DIM_SEDE] s ON h.SEDE_ID = s.SEDE_ID
JOIN [NORMALIZADOS].[BI_DIM_CURSO] c ON h.CURSO_CODIGO = c.CURSO_CODIGO
GROUP BY t.ANIO, s.SEDE_NOMBRE, c.CURSO_CATEGORIA
ORDER BY t.ANIO, s.SEDE_NOMBRE, TOTAL_INGRESOS DESC;
GO

-- 10. Índice de satisfacción (Por rango etario profesor y sede)
-- Formula: ((%Sat - %Insat) + 100) / 2
CREATE VIEW [NORMALIZADOS].[Vista_10_Indice_Satisfaccion] AS
SELECT
    s.SEDE_NOMBRE,
    p.PROFESOR_RANGO_ETARIO,
    ((
      (SUM(CAST(h.ES_SATISFECHO AS DECIMAL)) / COUNT(*)) -- % Satisfechos (0.x)
      - 
      (SUM(CAST(h.ES_INSATISFECHO AS DECIMAL)) / COUNT(*)) -- % Insatisfechos (0.x)
     ) * 100 + 100) / 2 AS INDICE_SATISFACCION
FROM [NORMALIZADOS].[BI_HECHOS_ENCUESTA] h
JOIN [NORMALIZADOS].[BI_DIM_SEDE] s ON h.SEDE_ID = s.SEDE_ID
JOIN [NORMALIZADOS].[BI_DIM_ETARIO_PROFESOR] p ON h.PROFESOR_ID = p.PROFESOR_ID
GROUP BY s.SEDE_NOMBRE, p.PROFESOR_RANGO_ETARIO;
GO