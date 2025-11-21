USE [GD2C2025]
GO

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
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_INSCRIPCION_CURSADA];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_INSCRIPCION_CATEGORIA];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_APROBADOS];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_FINALIZACION_CURSADA];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_EXAMEN_FINAL];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_PAGO];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_ENCUESTA];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_AUSENTISMO_FINAL];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_INGRESOS];

    -- Tablas de Dimensiones
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_DIM_TIEMPO];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_DIM_ETARIO_ALUMNO];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_DIM_ETARIO_PROFESOR];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_DIM_CURSO]; 
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_DIM_TURNO_CURSO];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_DIM_SEDE];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_DIM_MEDIO_PAGO];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_DIM_BLOQUES_SATISFACCION];

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
    ELSE IF @edad BETWEEN 36 AND 50 SET @rango = '35 - 50';
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
    SEDE_ID BIGINT PRIMARY KEY, -- Mismo ID que transaccional
    SEDE_NOMBRE VARCHAR(255)
);

CREATE TABLE [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] (
    ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    CURSO_CATEGORIA VARCHAR(255)
);

CREATE TABLE [NORMALIZADOS].[BI_DIM_TURNO_CURSO] (
    ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    CURSO_TURNO VARCHAR(255)
);

CREATE TABLE [NORMALIZADOS].[BI_DIM_ETARIO_ALUMNO] (
    ID SMALLINT IDENTITY(1,1) PRIMARY KEY,
    ALUMNO_RANGO_ETARIO VARCHAR(50) 
);

CREATE TABLE [NORMALIZADOS].[BI_DIM_ETARIO_PROFESOR] (
    ID SMALLINT IDENTITY(1,1) PRIMARY KEY,
    PROFESOR_RANGO_ETARIO VARCHAR(50) 
);

CREATE TABLE [NORMALIZADOS].[BI_DIM_MEDIO_PAGO] (
    MEDIO_PAGO_ID INT IDENTITY(1,1) PRIMARY KEY,
    MEDIO_PAGO_NOMBRE VARCHAR(255)
);

CREATE TABLE [NORMALIZADOS].[BI_DIM_BLOQUES_SATISFACCION](
    BLOQUE_ID INT IDENTITY(1,1) PRIMARY KEY,
    BLOQUE_DESCRIPCION VARCHAR(50) -- 'Satisfechos', 'Neutrales', 'Insatisfechos'
);

---------------------------------------------------------------------------------------------------
-- 4. CREACIÓN DE TABLAS DE HECHOS
---------------------------------------------------------------------------------------------------

-- HECHO 1: Inscripciones (Cantidad por Tiempo, Sede, Categoria, Turno)
CREATE TABLE [NORMALIZADOS].[BI_HECHOS_INSCRIPCION_CURSADA] (
    TIEMPO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
    SEDE_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_SEDE](SEDE_ID),
    CATEGORIA_CURSO_CODIGO BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO](ID),
    TURNO_CURSO_CODIGO BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TURNO_CURSO](ID),
    CANTIDAD_INSCRIPTOS INT
);

-- HECHO 2: Inscripciones Rechazadas (Rechazo por Tiempo, Sede)
CREATE TABLE [NORMALIZADOS].[BI_HECHOS_INSCRIPCION_CATEGORIA] (
    TIEMPO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
    SEDE_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_SEDE](SEDE_ID),
    CANTIDAD_INSCRIPTOS INT,
    CANTIDAD_RECHAZADOS INT
);

-- HECHO 3: Aprobados/Desaprobados (Por Tiempo Inicio, Sede)
CREATE TABLE [NORMALIZADOS].[BI_HECHOS_APROBADOS] (
    TIEMPO_INICIO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
    SEDE_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_SEDE](SEDE_ID),
    TOTAL_APROBADOS INT,
    TOTAL_DESAPROBADOS INT
);

-- HECHO 4: Finalización de Cursada (Duracion por Tiempo Inicio, Categoria)
CREATE TABLE [NORMALIZADOS].[BI_HECHOS_FINALIZACION_CURSADA] (
    TIEMPO_INICIO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
    CATEGORIA_CURSO_CODIGO BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO](ID),
    TIEMPO_FINALIZACION_MESES INT
);

-- HECHO 5: Exámenes Finales (Notas por Tiempo, Sede, Categoria, Rango Etario Alumno)
CREATE TABLE [NORMALIZADOS].[BI_HECHOS_EXAMEN_FINAL] (
    TIEMPO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
    SEDE_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_SEDE](SEDE_ID),
    CATEGORIA_CURSO_CODIGO BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO](ID),
    ALUMNO_ID SMALLINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_ETARIO_ALUMNO](ID),
    NOTA_FINAL DECIMAL(10,2),
    TOTAL_INSCRIPCIONES_FINAL INT,
    TOTAL_EXAMENES_DADOS INT
);

-- HECHO 6: Ausentismo (Por Tiempo, Sede)
CREATE TABLE [NORMALIZADOS].[BI_HECHOS_AUSENTISMO_FINAL] (
    TIEMPO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
    SEDE_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_SEDE](SEDE_ID),
    TOTAL_INSCRIPCIONES INT,
    TOTAL_AUSENTES INT
);

-- HECHO 7: Pagos (Financiero general por Tiempo)
CREATE TABLE [NORMALIZADOS].[BI_HECHOS_PAGO] (
    TIEMPO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
    IMPORTE_PAGADO DECIMAL(18,2),
    IMPORTE_FACTURADO DECIMAL(18,2), 
    PAGO_EN_TERMINO INT, 
    PAGO_FUERA_TERMINO INT 
);

-- HECHO 8: Ingresos (Detallado por Categoria, Sede)
CREATE TABLE [NORMALIZADOS].[BI_HECHOS_INGRESOS] (
    TIEMPO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
    CATEGORIA_CURSO_CODIGO BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO](ID),
    SEDE_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_SEDE](SEDE_ID),
    TOTAL_INGRESOS DECIMAL(18,2)
);

-- HECHO 9: Encuestas
CREATE TABLE [NORMALIZADOS].[BI_HECHOS_ENCUESTA] (
    TIEMPO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
    SEDE_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_SEDE](SEDE_ID),
    PROFESOR_ID SMALLINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_ETARIO_PROFESOR](ID),
    BLOQUE_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_BLOQUES_SATISFACCION](BLOQUE_ID),
    TOTAL_ENCUESTAS INT
);
GO

---------------------------------------------------------------------------------------------------
-- 5. PROCEDIMIENTOS DE MIGRACIÓN
---------------------------------------------------------------------------------------------------

CREATE PROCEDURE [NORMALIZADOS].[sp_migrar_bi_dimensiones] AS
BEGIN
    -- 1. Dimension TIEMPO
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

    -- 2. Dimension SEDE
    INSERT INTO [NORMALIZADOS].[BI_DIM_SEDE] (SEDE_ID, SEDE_NOMBRE)
    SELECT Sede_ID, Sede_Nombre FROM [NORMALIZADOS].[Sede];

    -- 3. Dimension CATEGORIA
    INSERT INTO [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] (CURSO_CATEGORIA)
    SELECT DISTINCT Categoria_Descripcion FROM [NORMALIZADOS].[Categoria];

    -- 4. Dimension TURNO
    INSERT INTO [NORMALIZADOS].[BI_DIM_TURNO_CURSO] (CURSO_TURNO)
    SELECT DISTINCT Curso_Turno FROM [NORMALIZADOS].[Curso] WHERE Curso_Turno IS NOT NULL;

    -- 5. Dimension RANGO ETARIO ALUMNO 
    INSERT INTO [NORMALIZADOS].[BI_DIM_ETARIO_ALUMNO] (ALUMNO_RANGO_ETARIO)
    VALUES ('< 25'), ('25 - 35'), ('35 - 50'), ('> 50');

    -- 6. Dimension RANGO ETARIO PROFESOR
    INSERT INTO [NORMALIZADOS].[BI_DIM_ETARIO_PROFESOR] (PROFESOR_RANGO_ETARIO)
    VALUES ('< 25'), ('25 - 35'), ('35 - 50'), ('> 50');

    -- 7. Dimension MEDIO PAGO
    INSERT INTO [NORMALIZADOS].[BI_DIM_MEDIO_PAGO] (MEDIO_PAGO_NOMBRE)
    SELECT DISTINCT Pago_MedioPago FROM [NORMALIZADOS].[Pago] WHERE Pago_MedioPago IS NOT NULL;

    -- 8. Dimension BLOQUES SATISFACCION
    INSERT INTO [NORMALIZADOS].[BI_DIM_BLOQUES_SATISFACCION] (BLOQUE_DESCRIPCION)
    VALUES ('Satisfechos'), ('Neutrales'), ('Insatisfechos');
END
GO

CREATE OR ALTER PROCEDURE [NORMALIZADOS].[sp_migrar_bi_hechos] AS
BEGIN
    -- ------------------------------------------
    -- MIGRACION HECHO 1: INSCRIPCION CURSADA (Cantidades)
    -- ------------------------------------------
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_INSCRIPCION_CURSADA] 
        (TIEMPO_ID, SEDE_ID, CATEGORIA_CURSO_CODIGO, TURNO_CURSO_CODIGO, CANTIDAD_INSCRIPTOS)
    SELECT 
        t.TIEMPO_ID,
        cur.Sede_ID,
        dim_cat.ID,
        dim_tur.ID,
        COUNT(*)
    FROM [NORMALIZADOS].[Inscripcion] i
    JOIN [NORMALIZADOS].[Curso] cur ON i.Curso_Codigo = cur.Curso_Codigo
    JOIN [NORMALIZADOS].[Categoria] cat ON cur.Categoria_ID = cat.Categoria_ID
    JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(i.Inscripcion_Fecha) = t.ANIO AND MONTH(i.Inscripcion_Fecha) = t.MES
    JOIN [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] dim_cat ON cat.Categoria_Descripcion = dim_cat.CURSO_CATEGORIA
    JOIN [NORMALIZADOS].[BI_DIM_TURNO_CURSO] dim_tur ON cur.Curso_Turno = dim_tur.CURSO_TURNO
    GROUP BY t.TIEMPO_ID, cur.Sede_ID, dim_cat.ID, dim_tur.ID;

    -- ------------------------------------------
    -- MIGRACION HECHO 2: INSCRIPCION CATEGORIA (Rechazos)
    -- ------------------------------------------
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_INSCRIPCION_CATEGORIA] 
        (TIEMPO_ID, SEDE_ID, CANTIDAD_INSCRIPTOS, CANTIDAD_RECHAZADOS)
    SELECT
        t.TIEMPO_ID,
        cur.Sede_ID,
        COUNT(*), 
        SUM(CASE WHEN i.Inscripcion_Estado = 'Rechazada' THEN 1 ELSE 0 END)
    FROM [NORMALIZADOS].[Inscripcion] i
    JOIN [NORMALIZADOS].[Curso] cur ON i.Curso_Codigo = cur.Curso_Codigo
    JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(i.Inscripcion_Fecha) = t.ANIO AND MONTH(i.Inscripcion_Fecha) = t.MES
    GROUP BY t.TIEMPO_ID, cur.Sede_ID;

    -- ------------------------------------------
    -- MIGRACION HECHO 3: APROBADOS (Desempeño Cursada) - CORREGIDO CON CTE
    -- ------------------------------------------
    -- Solución: Primero calculamos el estado de cada cursada individualmente (CTE)
    -- y luego agrupamos en la inserción.
    WITH Estado_Cursadas AS (
        SELECT
            i.Alumno_Legajo,
            i.Curso_Codigo,
            c.Sede_ID,
            c.Curso_FechaInicio,
            -- Cálculo de Nota Minima Parciales (Si es NULL asumimos 0)
            ISNULL((SELECT MIN(exa.Evaluacion_Nota) 
                    FROM [NORMALIZADOS].[Evaluacion_x_Alumno] exa 
                    JOIN [NORMALIZADOS].[Evaluacion_Curso] ec ON exa.Evaluacion_Curso_ID = ec.Evaluacion_Curso_ID
                    JOIN [NORMALIZADOS].[Modulo_x_Curso] mxc ON ec.Modulo_ID = mxc.Modulo_ID
                    WHERE exa.Alumno_Legajo = i.Alumno_Legajo 
                      AND mxc.Curso_Codigo = i.Curso_Codigo), 0) as Min_Nota_Parcial,
            -- Cálculo de Nota Maxima TP (Si es NULL asumimos 0)
            ISNULL((SELECT MAX(tp.Trabajo_Practico_Nota) 
                    FROM [NORMALIZADOS].[Trabajo_Practico] tp 
                    WHERE tp.Alumno_Legajo = i.Alumno_Legajo 
                      AND tp.Curso_Codigo = i.Curso_Codigo), 0) as Max_Nota_TP
        FROM [NORMALIZADOS].[Inscripcion] i
        JOIN [NORMALIZADOS].[Curso] c ON i.Curso_Codigo = c.Curso_Codigo
        WHERE i.Inscripcion_Estado = 'Confirmada'
    )
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_APROBADOS] (TIEMPO_INICIO_ID, SEDE_ID, TOTAL_APROBADOS, TOTAL_DESAPROBADOS)
    SELECT
        t.TIEMPO_ID,
        ec.Sede_ID,
        -- Aprobado: Parciales >= 4 Y TP >= 4
        SUM(CASE WHEN ec.Min_Nota_Parcial >= 4 AND ec.Max_Nota_TP >= 4 THEN 1 ELSE 0 END),
        -- Desaprobado: Parciales < 4 O TP < 4
        SUM(CASE WHEN ec.Min_Nota_Parcial < 4 OR ec.Max_Nota_TP < 4 THEN 1 ELSE 0 END)
    FROM Estado_Cursadas ec
    JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(ec.Curso_FechaInicio) = t.ANIO AND MONTH(ec.Curso_FechaInicio) = t.MES
    GROUP BY t.TIEMPO_ID, ec.Sede_ID;


    -- ------------------------------------------
    -- MIGRACION HECHO 4: FINALIZACION CURSADA
    -- ------------------------------------------
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_FINALIZACION_CURSADA] (TIEMPO_INICIO_ID, CATEGORIA_CURSO_CODIGO, TIEMPO_FINALIZACION_MESES)
    SELECT
        t.TIEMPO_ID,
        dim_cat.ID,
        DATEDIFF(MONTH, c.Curso_FechaInicio, ef.Examen_Final_Fecha)
    FROM [NORMALIZADOS].[Inscripcion] i
    JOIN [NORMALIZADOS].[Curso] c ON i.Curso_Codigo = c.Curso_Codigo
    JOIN [NORMALIZADOS].[Categoria] cat ON c.Categoria_ID = cat.Categoria_ID
    JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(c.Curso_FechaInicio) = t.ANIO AND MONTH(c.Curso_FechaInicio) = t.MES
    JOIN [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] dim_cat ON cat.Categoria_Descripcion = dim_cat.CURSO_CATEGORIA
    INNER JOIN [NORMALIZADOS].[Evaluacion_Final] evf ON evf.Alumno_Legajo = i.Alumno_Legajo
    INNER JOIN [NORMALIZADOS].[Examen_Final] ef ON evf.Examen_Final_ID = ef.Examen_Final_ID AND ef.Curso_Codigo = c.Curso_Codigo
    WHERE i.Inscripcion_Estado = 'Confirmada' AND evf.Evaluacion_Final_Nota >= 4;

    -- ------------------------------------------
    -- MIGRACION HECHO 5: EXAMEN FINAL
    -- ------------------------------------------
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_EXAMEN_FINAL] 
        (TIEMPO_ID, SEDE_ID, CATEGORIA_CURSO_CODIGO, ALUMNO_ID, NOTA_FINAL, TOTAL_INSCRIPCIONES_FINAL, TOTAL_EXAMENES_DADOS)
    SELECT 
        t.TIEMPO_ID,
        c.Sede_ID,
        dim_cat.ID,
        dim_eta.ID, 
        ev.Evaluacion_Final_Nota,
        1, 
        CASE WHEN ev.Evaluacion_Final_Presente = 1 THEN 1 ELSE 0 END 
    FROM [NORMALIZADOS].[Evaluacion_Final] ev
    JOIN [NORMALIZADOS].[Examen_Final] ef ON ev.Examen_Final_ID = ef.Examen_Final_ID
    JOIN [NORMALIZADOS].[Curso] c ON ef.Curso_Codigo = c.Curso_Codigo
    JOIN [NORMALIZADOS].[Categoria] cat ON c.Categoria_ID = cat.Categoria_ID
    JOIN [NORMALIZADOS].[Alumno] alu ON ev.Alumno_Legajo = alu.Alumno_Legajo
    JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(ef.Examen_Final_Fecha) = t.ANIO AND MONTH(ef.Examen_Final_Fecha) = t.MES
    JOIN [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] dim_cat ON cat.Categoria_Descripcion = dim_cat.CURSO_CATEGORIA
    JOIN [NORMALIZADOS].[BI_DIM_ETARIO_ALUMNO] dim_eta 
        ON dim_eta.ALUMNO_RANGO_ETARIO = [NORMALIZADOS].[fx_obtener_rango_etario](alu.Alumno_FechaNacimiento);

    -- ------------------------------------------
    -- MIGRACION HECHO 6: AUSENTISMO 
    -- ------------------------------------------
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_AUSENTISMO_FINAL] (TIEMPO_ID, SEDE_ID, TOTAL_INSCRIPCIONES, TOTAL_AUSENTES)
    SELECT
        t.TIEMPO_ID,
        c.Sede_ID,
        COUNT(*),
        SUM(CASE WHEN ev.Evaluacion_Final_Presente = 0 THEN 1 ELSE 0 END)
    FROM [NORMALIZADOS].[Evaluacion_Final] ev
    JOIN [NORMALIZADOS].[Examen_Final] ef ON ev.Examen_Final_ID = ef.Examen_Final_ID
    JOIN [NORMALIZADOS].[Curso] c ON ef.Curso_Codigo = c.Curso_Codigo
    JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(ef.Examen_Final_Fecha) = t.ANIO AND MONTH(ef.Examen_Final_Fecha) = t.MES
    GROUP BY t.TIEMPO_ID, c.Sede_ID;

    -- ------------------------------------------
    -- MIGRACION HECHO 7: PAGO 
    -- ------------------------------------------
    -- Parte A: Pagos Reales
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_PAGO] (TIEMPO_ID, IMPORTE_PAGADO, IMPORTE_FACTURADO, PAGO_EN_TERMINO, PAGO_FUERA_TERMINO)
    SELECT
        t.TIEMPO_ID,
        p.Pago_Importe,
        0, 
        CASE WHEN p.Pago_Fecha <= f.Factura_FechaVencimiento THEN 1 ELSE 0 END,
        CASE WHEN p.Pago_Fecha > f.Factura_FechaVencimiento THEN 1 ELSE 0 END
    FROM [NORMALIZADOS].[Pago] p
    JOIN [NORMALIZADOS].[Factura] f ON p.Factura_Numero = f.Factura_Numero
    JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(p.Pago_Fecha) = t.ANIO AND MONTH(p.Pago_Fecha) = t.MES;

    -- Parte B: Deudas
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_PAGO] (TIEMPO_ID, IMPORTE_PAGADO, IMPORTE_FACTURADO, PAGO_EN_TERMINO, PAGO_FUERA_TERMINO)
    SELECT 
        t.TIEMPO_ID,
        0,
        f.Factura_Total,
        0, 0
    FROM [NORMALIZADOS].[Factura] f
    JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(f.Factura_FechaEmision) = t.ANIO AND MONTH(f.Factura_FechaEmision) = t.MES
    WHERE NOT EXISTS (SELECT 1 FROM [NORMALIZADOS].[Pago] p WHERE p.Factura_Numero = f.Factura_Numero);

    -- ------------------------------------------
    -- MIGRACION HECHO 8: INGRESOS 
    -- ------------------------------------------
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_INGRESOS] (TIEMPO_ID, CATEGORIA_CURSO_CODIGO, SEDE_ID, TOTAL_INGRESOS)
    SELECT
        t.TIEMPO_ID,
        dim_cat.ID,
        c.Sede_ID,
        SUM(p.Pago_Importe)
    FROM [NORMALIZADOS].[Pago] p
    JOIN [NORMALIZADOS].[Factura] f ON p.Factura_Numero = f.Factura_Numero
    JOIN [NORMALIZADOS].[Detalle_Factura] df ON f.Factura_Numero = df.Factura_Numero
    JOIN [NORMALIZADOS].[Curso] c ON df.Curso_Codigo = c.Curso_Codigo
    JOIN [NORMALIZADOS].[Categoria] cat ON c.Categoria_ID = cat.Categoria_ID
    JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(p.Pago_Fecha) = t.ANIO AND MONTH(p.Pago_Fecha) = t.MES
    JOIN [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] dim_cat ON cat.Categoria_Descripcion = dim_cat.CURSO_CATEGORIA
    GROUP BY t.TIEMPO_ID, dim_cat.ID, c.Sede_ID;

    -- ------------------------------------------
    -- MIGRACION HECHO 9: ENCUESTA (CORREGIDO CON CTE)
    -- ------------------------------------------
    WITH PromediosEncuesta AS (
        SELECT 
            e.Encuesta_ID,
            AVG(de.Encuesta_Nota) as NotaPromedio
        FROM [NORMALIZADOS].[Encuesta] e
        JOIN [NORMALIZADOS].[Detalle_Encuesta] de ON e.Encuesta_ID = de.Encuesta_ID
        GROUP BY e.Encuesta_ID
    )
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_ENCUESTA] (TIEMPO_ID, SEDE_ID, PROFESOR_ID, BLOQUE_ID, TOTAL_ENCUESTAS)
    SELECT
        t.TIEMPO_ID,
        c.Sede_ID,
        dim_prof.ID,
        dim_bloq.BLOQUE_ID,
        COUNT(e.Encuesta_ID)
    FROM [NORMALIZADOS].[Encuesta] e
    JOIN [NORMALIZADOS].[Curso] c ON e.Curso_Codigo = c.Curso_Codigo
    JOIN [NORMALIZADOS].[Profesor] prof ON c.Profesor_ID = prof.Profesor_ID
    JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(e.Encuesta_FechaRegistro) = t.ANIO AND MONTH(e.Encuesta_FechaRegistro) = t.MES
    JOIN [NORMALIZADOS].[BI_DIM_ETARIO_PROFESOR] dim_prof 
        ON dim_prof.PROFESOR_RANGO_ETARIO = [NORMALIZADOS].[fx_obtener_rango_etario](prof.Profesor_FechaNacimiento)
    JOIN PromediosEncuesta pe ON pe.Encuesta_ID = e.Encuesta_ID
    JOIN [NORMALIZADOS].[BI_DIM_BLOQUES_SATISFACCION] dim_bloq ON 
        (pe.NotaPromedio BETWEEN 7 AND 10 AND dim_bloq.BLOQUE_DESCRIPCION = 'Satisfechos') OR
        (pe.NotaPromedio BETWEEN 5 AND 6 AND dim_bloq.BLOQUE_DESCRIPCION = 'Neutrales') OR
        (pe.NotaPromedio BETWEEN 1 AND 4 AND dim_bloq.BLOQUE_DESCRIPCION = 'Insatisfechos')
    GROUP BY t.TIEMPO_ID, c.Sede_ID, dim_prof.ID, dim_bloq.BLOQUE_ID;

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
-- 7. CREACIÓN DE VISTAS (Adaptadas a las nuevas Tablas)
---------------------------------------------------------------------------------------------------

-- 1. Categorías y turnos más solicitados (Top 3 por año por sede)
CREATE VIEW [NORMALIZADOS].[Vista_01_Categorias_Turnos_Mas_Solicitados] AS
SELECT TOP 3
    t.ANIO,
    s.SEDE_NOMBRE,
    dc.CURSO_CATEGORIA,
    dt.CURSO_TURNO,
    SUM(h.CANTIDAD_INSCRIPTOS) as CANTIDAD_TOTAL
FROM [NORMALIZADOS].[BI_HECHOS_INSCRIPCION_CURSADA] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
JOIN [NORMALIZADOS].[BI_DIM_SEDE] s ON h.SEDE_ID = s.SEDE_ID
JOIN [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] dc ON h.CATEGORIA_CURSO_CODIGO = dc.ID
JOIN [NORMALIZADOS].[BI_DIM_TURNO_CURSO] dt ON h.TURNO_CURSO_CODIGO = dt.ID
GROUP BY t.ANIO, s.SEDE_NOMBRE, dc.CURSO_CATEGORIA, dt.CURSO_TURNO
ORDER BY t.ANIO, s.SEDE_NOMBRE, CANTIDAD_TOTAL DESC;
GO

-- 2. Tasa de rechazo de inscripciones (Por mes por sede)
CREATE VIEW [NORMALIZADOS].[Vista_02_Tasa_Rechazo_Inscripciones] AS
SELECT
    t.ANIO,
    t.MES,
    s.SEDE_NOMBRE,
    (SUM(CAST(h.CANTIDAD_RECHAZADOS AS DECIMAL)) / SUM(h.CANTIDAD_INSCRIPTOS)) * 100 AS PORCENTAJE_RECHAZO
FROM [NORMALIZADOS].[BI_HECHOS_INSCRIPCION_CATEGORIA] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
JOIN [NORMALIZADOS].[BI_DIM_SEDE] s ON h.SEDE_ID = s.SEDE_ID
GROUP BY t.ANIO, t.MES, s.SEDE_NOMBRE;
GO

-- 3. Comparación de desempeño de cursada (Aprobación por sede por año)
CREATE VIEW [NORMALIZADOS].[Vista_03_Desempeno_Cursada] AS
SELECT
    t.ANIO,
    s.SEDE_NOMBRE,
    (SUM(CAST(h.TOTAL_APROBADOS AS DECIMAL)) / SUM(h.TOTAL_APROBADOS + h.TOTAL_DESAPROBADOS)) * 100 AS PORCENTAJE_APROBACION
FROM [NORMALIZADOS].[BI_HECHOS_APROBADOS] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_INICIO_ID = t.TIEMPO_ID
JOIN [NORMALIZADOS].[BI_DIM_SEDE] s ON h.SEDE_ID = s.SEDE_ID
GROUP BY t.ANIO, s.SEDE_NOMBRE;
GO

-- 4. Tiempo promedio de finalización de curso (Por categoria, por año)
CREATE VIEW [NORMALIZADOS].[Vista_04_Tiempo_Promedio_Finalizacion] AS
SELECT
    t.ANIO,
    dc.CURSO_CATEGORIA,
    AVG(h.TIEMPO_FINALIZACION_MESES) AS PROMEDIO_MESES_FINALIZACION
FROM [NORMALIZADOS].[BI_HECHOS_FINALIZACION_CURSADA] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_INICIO_ID = t.TIEMPO_ID
JOIN [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] dc ON h.CATEGORIA_CURSO_CODIGO = dc.ID
GROUP BY t.ANIO, dc.CURSO_CATEGORIA;
GO

-- 5. Nota promedio de finales (Rango etario alumno, categoria curso, semestre/cuatrimestre)
CREATE VIEW [NORMALIZADOS].[Vista_05_Promedio_Nota_Finales] AS
SELECT
    t.CUATRIMESTRE,
    da.ALUMNO_RANGO_ETARIO,
    dc.CURSO_CATEGORIA,
    AVG(h.NOTA_FINAL) AS PROMEDIO_NOTA
FROM [NORMALIZADOS].[BI_HECHOS_EXAMEN_FINAL] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
JOIN [NORMALIZADOS].[BI_DIM_ETARIO_ALUMNO] da ON h.ALUMNO_ID = da.ID
JOIN [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] dc ON h.CATEGORIA_CURSO_CODIGO = dc.ID
GROUP BY t.CUATRIMESTRE, da.ALUMNO_RANGO_ETARIO, dc.CURSO_CATEGORIA;
GO

-- 6. Tasa de ausentismo finales (Por semestre/cuatrimestre, por sede)
CREATE VIEW [NORMALIZADOS].[Vista_06_Ausentismo_Finales] AS
SELECT
    t.CUATRIMESTRE,
    s.SEDE_NOMBRE,
    (SUM(CAST(h.TOTAL_AUSENTES AS DECIMAL)) / SUM(h.TOTAL_INSCRIPCIONES)) * 100 AS PORCENTAJE_AUSENTISMO
FROM [NORMALIZADOS].[BI_HECHOS_AUSENTISMO_FINAL] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
JOIN [NORMALIZADOS].[BI_DIM_SEDE] s ON h.SEDE_ID = s.SEDE_ID
GROUP BY t.CUATRIMESTRE, s.SEDE_NOMBRE;
GO

-- 7. Desvío de pagos (Porcentaje pagos fuera de termino por semestre/cuatrimestre)
CREATE VIEW [NORMALIZADOS].[Vista_07_Desvio_Pagos] AS
SELECT
    t.CUATRIMESTRE,
    (SUM(CAST(h.PAGO_FUERA_TERMINO AS DECIMAL)) / COUNT(*)) * 100 AS PORCENTAJE_PAGOS_TARDIOS
FROM [NORMALIZADOS].[BI_HECHOS_PAGO] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
WHERE h.IMPORTE_PAGADO > 0 -- Solo registros de pago real
GROUP BY t.CUATRIMESTRE;
GO

-- 8. Tasa de Morosidad Financiera mensual (Importe Adeudado / Facturacion Esperada)
CREATE VIEW [NORMALIZADOS].[Vista_08_Morosidad_Mensual] AS
SELECT
    t.ANIO,
    t.MES,
    CASE WHEN SUM(h.IMPORTE_PAGADO + h.IMPORTE_FACTURADO) = 0 THEN 0 
    ELSE (SUM(h.IMPORTE_FACTURADO) / SUM(h.IMPORTE_PAGADO + h.IMPORTE_FACTURADO)) * 100 
    END AS TASA_MOROSIDAD
FROM [NORMALIZADOS].[BI_HECHOS_PAGO] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
GROUP BY t.ANIO, t.MES;
GO

-- 9. Ingresos por categoría de cursos (Top 3 por sede, por año)
CREATE VIEW [NORMALIZADOS].[Vista_09_Ingresos_Categoria] AS
SELECT TOP 3 WITH TIES
    t.ANIO,
    s.SEDE_NOMBRE,
    dc.CURSO_CATEGORIA,
    SUM(h.TOTAL_INGRESOS) AS TOTAL_INGRESOS
FROM [NORMALIZADOS].[BI_HECHOS_INGRESOS] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
JOIN [NORMALIZADOS].[BI_DIM_SEDE] s ON h.SEDE_ID = s.SEDE_ID
JOIN [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] dc ON h.CATEGORIA_CURSO_CODIGO = dc.ID
GROUP BY t.ANIO, s.SEDE_NOMBRE, dc.CURSO_CATEGORIA
ORDER BY t.ANIO, s.SEDE_NOMBRE, TOTAL_INGRESOS DESC;
GO

-- 10. Índice de satisfacción (Por rango etario profesor y sede)
CREATE VIEW [NORMALIZADOS].[Vista_10_Indice_Satisfaccion] AS
SELECT
    s.SEDE_NOMBRE,
    dp.PROFESOR_RANGO_ETARIO,
    ((
      (SUM(CASE WHEN db.BLOQUE_DESCRIPCION = 'Satisfechos' THEN h.TOTAL_ENCUESTAS ELSE 0 END) * 1.0 / SUM(h.TOTAL_ENCUESTAS)) 
      - 
      (SUM(CASE WHEN db.BLOQUE_DESCRIPCION = 'Insatisfechos' THEN h.TOTAL_ENCUESTAS ELSE 0 END) * 1.0 / SUM(h.TOTAL_ENCUESTAS))
     ) * 100 + 100) / 2 AS INDICE_SATISFACCION
FROM [NORMALIZADOS].[BI_HECHOS_ENCUESTA] h
JOIN [NORMALIZADOS].[BI_DIM_SEDE] s ON h.SEDE_ID = s.SEDE_ID
JOIN [NORMALIZADOS].[BI_DIM_ETARIO_PROFESOR] dp ON h.PROFESOR_ID = dp.ID
JOIN [NORMALIZADOS].[BI_DIM_BLOQUES_SATISFACCION] db ON h.BLOQUE_ID = db.BLOQUE_ID
GROUP BY s.SEDE_NOMBRE, dp.PROFESOR_RANGO_ETARIO;
GO



---------------------------   
--ver  views
SELECT * FROM [NORMALIZADOS].[Vista_01_Categorias_Turnos_Mas_Solicitados];
SELECT * FROM [NORMALIZADOS].[Vista_02_Tasa_Rechazo_Inscripciones];
SELECT * FROM [NORMALIZADOS].[Vista_03_Desempeno_Cursada];
SELECT * FROM [NORMALIZADOS].[Vista_04_Tiempo_Promedio_Finalizacion];
SELECT * FROM [NORMALIZADOS].[Vista_05_Promedio_Nota_Finales];
SELECT * FROM [NORMALIZADOS].[Vista_06_Ausentismo_Finales];
SELECT * FROM [NORMALIZADOS].[Vista_07_Desvio_Pagos];
SELECT * FROM [NORMALIZADOS].[Vista_08_Morosidad_Mensual];
SELECT * FROM [NORMALIZADOS].[Vista_09_Ingresos_Categoria];
SELECT * FROM [NORMALIZADOS].[Vista_10_Indice_Satisfaccion];