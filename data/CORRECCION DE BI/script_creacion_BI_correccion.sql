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
    -- DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_INSCRIPCION_CURSADA];
    -- DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_INSCRIPCION_CATEGORIA];
    -- DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_APROBADOS];
    -- DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_FINALIZACION_CURSADA];
    -- DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_EXAMEN_FINAL];
    -- DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_AUSENTISMO_FINAL];
    -- DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_PAGO];
    -- DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_INGRESOS];
    -- DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_ENCUESTA];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_INSCRIPCION];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_EXAMEN_FINAL];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_CURSO];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_PAGO];
    DROP TABLE IF EXISTS [NORMALIZADOS].[BI_HECHOS_ENCUESTA];

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
    DROP PROCEDURE IF EXISTS [NORMALIZADOS].[sp_migrar_bi_hechos_inscripcion];
    
    -- Funciones
    DROP FUNCTION IF EXISTS [NORMALIZADOS].[fx_obtener_semestre];
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

-- Función para calcular semestre (1 o 2)
CREATE FUNCTION [NORMALIZADOS].[fx_obtener_semestre](@fecha DATETIME2)
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

CREATE OR ALTER FUNCTION [NORMALIZADOS].[fx_obtener_bloque_satisfaccion](@nota BIGINT)
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @bloque VARCHAR(50);

    IF @nota BETWEEN 7 AND 10
        SET @bloque = 'Satisfechos';
    ELSE IF @nota BETWEEN 5 AND 6
        SET @bloque = 'Neutrales';
    ELSE
        -- Asumimos que cualquier otra nota (1-4) es Insatisfechos
        SET @bloque = 'Insatisfechos';

    RETURN @bloque;
END
GO

---------------------------------------------------------------------------------------------------
-- 3. CREACIÓN DE TABLAS DIMENSIONALES
---------------------------------------------------------------------------------------------------

CREATE TABLE [NORMALIZADOS].[BI_DIM_TIEMPO] (
    TIEMPO_ID INT IDENTITY(1,1) PRIMARY KEY,
    ANIO INT,
    MES INT,
    SEMESTRE INT
        CHECK(SEMESTRE IN (1,2))
);

CREATE TABLE [NORMALIZADOS].[BI_DIM_SEDE] (
    SEDE_ID BIGINT PRIMARY KEY, -- Mismo ID que transaccional
    SEDE_NOMBRE VARCHAR(255)
);

CREATE TABLE [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] (
    ID BIGINT PRIMARY KEY, -- Mismo ID que transaccional
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
    BLOQUE_DESCRIPCION VARCHAR(50)
        CHECK (BLOQUE_DESCRIPCION IN ('Satisfechos','Neutrales','Insatisfechos'))
);

---------------------------------------------------------------------------------------------------
-- 4. CREACIÓN DE TABLAS DE HECHOS
---------------------------------------------------------------------------------------------------

-- HECHO 1: Inscripciones (Cantidad por Tiempo, Sede, Categoria, Turno) con Rechazos
CREATE TABLE [NORMALIZADOS].[BI_HECHOS_INSCRIPCION] (
    TIEMPO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
    SEDE_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_SEDE](SEDE_ID),
    CATEGORIA_CURSO_CODIGO BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO](ID),
    TURNO_CURSO_CODIGO BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TURNO_CURSO](ID),
    CANTIDAD_INSCRIPTOS INT,
    CANTIDAD_RECHAZADOS INT,
    CONSTRAINT PK_BI_HECHOS_INSCRIPCION PRIMARY KEY (
        TIEMPO_ID, 
        SEDE_ID, 
        CATEGORIA_CURSO_CODIGO, 
        TURNO_CURSO_CODIGO
	)
);

-- HECHO 2: Aprobados/Desaprobados y Finalización de Cursada
CREATE TABLE [NORMALIZADOS].[BI_HECHOS_CURSO] (
    TIEMPO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
    SEDE_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_SEDE](SEDE_ID),
    CATEGORIA_CURSO_CODIGO BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO](ID),
    CANTIDAD_APROBADOS INT,
    CANTIDAD_DESAPROBADOS INT,
    SUMATORIA_TIEMPO_FINALIZACION INT, -- Para sacar promedio luego (Suma / Cantidad)
    CANTIDAD_CASOS_FINALIZACION INT,    -- Para el denominador del promedio
    CONSTRAINT PK_BI_HECHOS_CURSO PRIMARY KEY (
        TIEMPO_ID, 
        SEDE_ID, 
        CATEGORIA_CURSO_CODIGO
    )
);

-- HECHO 3: Exámenes Finales (Promedio de Notas por Tiempo, Sede, Categoria, Rango Etario Alumno)
CREATE TABLE [NORMALIZADOS].[BI_HECHOS_EXAMEN_FINAL] (
    TIEMPO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
    SEDE_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_SEDE](SEDE_ID),
    CATEGORIA_CURSO_CODIGO BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO](ID),
    ALUMNO_RANGO_ETARIO_ID SMALLINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_ETARIO_ALUMNO](ID),
    
    -- Métricas para Nota Promedio
    SUMA_NOTAS_FINAL DECIMAL(10,2),
    CANTIDAD_EXAMENES_CON_NOTA INT,
    
    -- Métricas para Ausentismo
    CANTIDAD_TOTAL_INSCRIPTOS INT,
    CANTIDAD_TOTAL_AUSENTES INT,

	CONSTRAINT PK_BI_HECHOS_EXAMEN_FINAL PRIMARY KEY (
        TIEMPO_ID, 
        SEDE_ID, 
        CATEGORIA_CURSO_CODIGO,
		ALUMNO_RANGO_ETARIO_ID
    )
);
GO

-- -- HECHO 7: Pagos (Financiero general por Tiempo)
-- CREATE TABLE [NORMALIZADOS].[BI_HECHOS_PAGO] (
--     TIEMPO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
--     IMPORTE_PAGADO DECIMAL(18,2),
--     IMPORTE_FACTURADO DECIMAL(18,2), 
--     PAGO_EN_TERMINO INT, 
--     PAGO_FUERA_TERMINO INT 
-- );

-- -- HECHO 8: Ingresos (Detallado por Categoria, Sede)
-- CREATE TABLE [NORMALIZADOS].[BI_HECHOS_INGRESOS] (
--     TIEMPO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
--     CATEGORIA_CURSO_CODIGO BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO](ID),
--     SEDE_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_SEDE](SEDE_ID),
--     TOTAL_INGRESOS DECIMAL(18,2)
-- );

--se unifican ambos hechos en uno solo


-- HECHO 4: Pagos (Financiero por Tiempo, Sede, Categoria, Medio de Pago)
CREATE TABLE [NORMALIZADOS].[BI_HECHOS_PAGO] (
    TIEMPO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
    SEDE_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_SEDE](SEDE_ID),
    CATEGORIA_CURSO_CODIGO BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO](ID),
    MEDIO_PAGO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_MEDIO_PAGO](MEDIO_PAGO_ID),
    
    -- Métricas Financieras
    IMPORTE_PAGADO DECIMAL(18,2),
    IMPORTE_FACTURADO DECIMAL(18,2),
    
    -- Métricas de Desempeño de Pago
    CANTIDAD_PAGOS_EN_TERMINO INT,
    CANTIDAD_PAGOS_FUERA_TERMINO INT,

	CONSTRAINT PK_BI_HECHOS_PAGO PRIMARY KEY (
        TIEMPO_ID, 
        SEDE_ID, 
        CATEGORIA_CURSO_CODIGO,
		MEDIO_PAGO_ID
    )
);
GO

-- HECHO 5: ENCUESTA (Índice de Satisfacción)
CREATE TABLE [NORMALIZADOS].[BI_HECHOS_ENCUESTA] (
    TIEMPO_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_TIEMPO](TIEMPO_ID),
    SEDE_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_SEDE](SEDE_ID),
    PROFESOR_RANGO_ETARIO_ID SMALLINT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_ETARIO_PROFESOR](ID),
    BLOQUE_SATISFACCION_ID INT FOREIGN KEY REFERENCES [NORMALIZADOS].[BI_DIM_BLOQUES_SATISFACCION](BLOQUE_ID),
    
    -- Métricas
    CANTIDAD_ENCUESTAS INT,

	CONSTRAINT PK_BI_HECHOS_ENCUESTA PRIMARY KEY (
        TIEMPO_ID, 
        SEDE_ID, 
        PROFESOR_RANGO_ETARIO_ID,
		BLOQUE_SATISFACCION_ID
    )
);
GO




---------------------------------------------------------------------------------------------------
-- 5. PROCEDIMIENTOS DE MIGRACIÓN
---------------------------------------------------------------------------------------------------

CREATE PROCEDURE [NORMALIZADOS].[sp_migrar_bi_dimensiones] AS
BEGIN
    -- 1. Dimension TIEMPO
    INSERT INTO [NORMALIZADOS].[BI_DIM_TIEMPO] (ANIO, MES, SEMESTRE)
    SELECT DISTINCT YEAR(Fecha), MONTH(Fecha), [NORMALIZADOS].[fx_obtener_semestre](Fecha)
    FROM (
        SELECT DISTINCT Inscripcion_Fecha AS Fecha FROM [NORMALIZADOS].[Inscripcion]
        UNION
        SELECT DISTINCT Pago_Fecha FROM [NORMALIZADOS].[Pago]
        UNION
        SELECT DISTINCT Factura_FechaEmision FROM [NORMALIZADOS].[Factura]
        UNION
        SELECT DISTINCT Examen_Final_Fecha FROM [NORMALIZADOS].[Examen_Final]
        UNION
        SELECT DISTINCT Encuesta_FechaRegistro FROM [NORMALIZADOS].[Encuesta]
    ) AS Fechas
    WHERE Fecha IS NOT NULL
    ORDER BY 1, 2;

    -- 2. Dimension SEDE
    INSERT INTO [NORMALIZADOS].[BI_DIM_SEDE] (SEDE_ID, SEDE_NOMBRE)
    SELECT Sede_ID, Sede_Nombre FROM [NORMALIZADOS].[Sede];

    -- 3. Dimension CATEGORIA
    INSERT INTO [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] (ID, CURSO_CATEGORIA)
    SELECT Categoria_ID, Categoria_Descripcion FROM [NORMALIZADOS].[Categoria];

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
    -- Primero insertamos el valor por defecto para evitar errores de FK
    SET IDENTITY_INSERT [NORMALIZADOS].[BI_DIM_MEDIO_PAGO] ON;
    INSERT INTO [NORMALIZADOS].[BI_DIM_MEDIO_PAGO] (MEDIO_PAGO_ID, MEDIO_PAGO_NOMBRE) 
    VALUES (-1, 'Pendiente de Pago / No Informado');
    SET IDENTITY_INSERT [NORMALIZADOS].[BI_DIM_MEDIO_PAGO] OFF;
    
    INSERT INTO [NORMALIZADOS].[BI_DIM_MEDIO_PAGO] (MEDIO_PAGO_NOMBRE)
    SELECT DISTINCT Pago_MedioPago FROM [NORMALIZADOS].[Pago] WHERE Pago_MedioPago IS NOT NULL;

    -- 8. Dimension BLOQUES SATISFACCION
    INSERT INTO [NORMALIZADOS].[BI_DIM_BLOQUES_SATISFACCION] (BLOQUE_DESCRIPCION)
    VALUES ('Satisfechos'), ('Neutrales'), ('Insatisfechos');
END
GO

----------------------------------------------------------------------------------------------
--- MIGRACIÓN DE TABLAS DE HECHOS --
----------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE [NORMALIZADOS].[sp_migrar_bi_hechos_inscripcion] AS
BEGIN
    -- MIGRACION HECHO 1: INSCRIPCION (Cantidades y Rechazos)
    -- Migración (Debe tener GROUP BY por todas las dimensiones)
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_INSCRIPCION]
    SELECT 
        t.TIEMPO_ID,
        cur.Sede_ID,
        dim_cat.ID,
        dim_tur.ID,
        COUNT(*), -- Total inscripciones (intentos)
        SUM(CASE WHEN i.Inscripcion_Estado = 'Rechazada' THEN 1 ELSE 0 END) -- De ese total, cuantos rechazados
    FROM [NORMALIZADOS].[Inscripcion] i
    JOIN [NORMALIZADOS].[Curso] cur ON i.Curso_Codigo = cur.Curso_Codigo
    JOIN [NORMALIZADOS].[Categoria] cat ON cur.Categoria_ID = cat.Categoria_ID
    JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(i.Inscripcion_Fecha) = t.ANIO AND MONTH(i.Inscripcion_Fecha) = t.MES
    JOIN [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] dim_cat ON cat.Categoria_ID = dim_cat.ID
    JOIN [NORMALIZADOS].[BI_DIM_TURNO_CURSO] dim_tur ON cur.Curso_Turno = dim_tur.CURSO_TURNO
    GROUP BY t.TIEMPO_ID, cur.Sede_ID, dim_cat.ID, dim_tur.ID;
END
GO

CREATE OR ALTER PROCEDURE [NORMALIZADOS].[sp_migrar_bi_hechos_curso] AS
BEGIN
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_CURSO]
    SELECT 
        dim_t.TIEMPO_ID,
        sede.SEDE_ID,
        dim_cat.ID,
        
        -- Métricas de Cursada (Aprobados/Desaprobados)
        SUM(datos_curso.CANTIDAD_APROBADOS) AS CANTIDAD_APROBADOS,
        SUM(datos_curso.CANTIDAD_DESAPROBADOS) AS CANTIDAD_DESAPROBADOS,
        
        -- Métrica Suma Meses y Cantidad Casos
        SUM(datos_curso.SUMATORIA_TIEMPO_FINALIZACION) AS SUMATORIA_TIEMPO_FINALIZACION,
        SUM(datos_curso.CANTIDAD_CASOS_FINALIZACION) AS CANTIDAD_CASOS_FINALIZACION

    FROM (
        -- Subconsulta que agrupa por Curso para calcular las métricas
        SELECT 
            base.Curso_Codigo,
            base.Evaluacion_Curso_fechaEvaluacion, -- Fecha para el JOIN con Tiempo
            base.Sede_ID,                          -- ID para el JOIN con Sede
            base.Categoria_ID,                     -- ID para el JOIN con Categoria
            
            -- Lógica de Aprobados/Desaprobados (Tal cual estaba antes)
            SUM(base.es_aprobado) AS CANTIDAD_APROBADOS,
            SUM(CASE WHEN base.es_aprobado = 0 THEN 1 ELSE 0 END) AS CANTIDAD_DESAPROBADOS,
            
            -- Métricas para el Promedio de Tiempo
            SUM(ISNULL(base.Meses_Hasta_Final, 0)) AS SUMATORIA_TIEMPO_FINALIZACION,
            SUM(CASE WHEN base.Meses_Hasta_Final IS NOT NULL THEN 1 ELSE 0 END) AS CANTIDAD_CASOS_FINALIZACION

        FROM (
            -- Subconsulta interna: Calcula estado por alumno
            SELECT DISTINCT
                ec.Curso_Codigo,
                ec.Evaluacion_Curso_fechaEvaluacion,
                c.Sede_ID,
                c.Categoria_ID,
                c.Curso_FechaInicio,
                eva.Alumno_Legajo,
                
                -- Lógica de Aprobación
                CASE
                WHEN NOT EXISTS (
                    SELECT 1
                    FROM [NORMALIZADOS].[Evaluacion_x_Alumno] eva2
                    JOIN [NORMALIZADOS].[Evaluacion_Curso] ec2 
                        ON eva2.Evaluacion_Curso_ID = ec2.Evaluacion_Curso_ID
                    WHERE eva2.Alumno_Legajo = eva.Alumno_Legajo
                    AND ec2.Curso_Codigo = ec.Curso_Codigo
                    AND (eva2.Evaluacion_Nota IS NULL OR eva2.Evaluacion_Nota < 4)
                )
                AND EXISTS (
                    SELECT 1
                    FROM [NORMALIZADOS].[Trabajo_Practico] tp
                    WHERE tp.Alumno_Legajo = eva.Alumno_Legajo
                    AND tp.Curso_Codigo = ec.Curso_Codigo
                    AND tp.Trabajo_Practico_Nota >= 4
                )
                THEN 1
                ELSE 0
                END AS es_aprobado,

                -- Lógica Tiempo Final (NUEVO: Diferencia Meses entre Inicio y Final Aprobado)
                (SELECT DATEDIFF(MONTH, c.Curso_FechaInicio, ef.Examen_Final_Fecha)
                FROM [NORMALIZADOS].[Evaluacion_Final] evf
                JOIN [NORMALIZADOS].[Examen_Final] ef ON evf.Examen_Final_ID = ef.Examen_Final_ID
                WHERE evf.Alumno_Legajo = eva.Alumno_Legajo 
                AND ef.Curso_Codigo = c.Curso_Codigo
                AND evf.Evaluacion_Final_Nota >= 4 -- Solo si aprobó el final cuenta
                ) AS Meses_Hasta_Final

            FROM [NORMALIZADOS].[Evaluacion_x_Alumno] eva
                INNER JOIN [NORMALIZADOS].[Evaluacion_Curso] ec 
                ON eva.Evaluacion_Curso_ID = ec.Evaluacion_Curso_ID
                INNER JOIN [NORMALIZADOS].[Curso] c 
                ON c.Curso_Codigo = ec.Curso_Codigo
        ) AS base
        GROUP BY base.Curso_Codigo, base.Evaluacion_Curso_fechaEvaluacion, base.Sede_ID, base.Categoria_ID
    ) datos_curso

    INNER JOIN [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] dim_cat ON dim_cat.ID = datos_curso.Categoria_ID
    INNER JOIN [NORMALIZADOS].[BI_DIM_SEDE] sede ON sede.SEDE_ID = datos_curso.Sede_ID
    INNER JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] dim_t 
        ON dim_t.ANIO = YEAR(datos_curso.Evaluacion_Curso_fechaEvaluacion)
        AND dim_t.MES = MONTH(datos_curso.Evaluacion_Curso_fechaEvaluacion)
    GROUP BY 
        dim_t.TIEMPO_ID, 
        sede.SEDE_ID,
        dim_cat.ID
END
GO

-- MIGRACION HECHO 3: EXAMEN FINAL (Promedios y Ausentismo)
CREATE OR ALTER PROCEDURE [NORMALIZADOS].[sp_migrar_bi_examen_final] AS
BEGIN
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_EXAMEN_FINAL]
        (TIEMPO_ID, SEDE_ID, CATEGORIA_CURSO_CODIGO, ALUMNO_RANGO_ETARIO_ID, 
        SUMA_NOTAS_FINAL, CANTIDAD_EXAMENES_CON_NOTA, CANTIDAD_TOTAL_INSCRIPTOS, CANTIDAD_TOTAL_AUSENTES)
    SELECT 
        t.TIEMPO_ID,
        c.Sede_ID,
        dim_cat.ID,
        dim_eta.ID,
        
        -- Suma de notas (solo si estuvo presente y tiene nota)
        SUM(CASE WHEN ev.Evaluacion_Final_Presente = 1 THEN ev.Evaluacion_Final_Nota ELSE 0 END),
        
        -- Cantidad de exámenes que tienen nota (para dividir después)
        SUM(CASE WHEN ev.Evaluacion_Final_Presente = 1 THEN 1 ELSE 0 END),
        
        -- Total de gente que se anotó al final
        COUNT(*),
        
        -- Total de ausentes
        SUM(CASE WHEN ev.Evaluacion_Final_Presente = 0 THEN 1 ELSE 0 END)

    FROM [NORMALIZADOS].[Evaluacion_Final] ev
    JOIN [NORMALIZADOS].[Examen_Final] ef ON ev.Examen_Final_ID = ef.Examen_Final_ID
    JOIN [NORMALIZADOS].[Curso] c ON ef.Curso_Codigo = c.Curso_Codigo
    JOIN [NORMALIZADOS].[Categoria] cat ON c.Categoria_ID = cat.Categoria_ID
    JOIN [NORMALIZADOS].[Alumno] alu ON ev.Alumno_Legajo = alu.Alumno_Legajo

    -- JOINs a Dimensiones
    JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(ef.Examen_Final_Fecha) = t.ANIO AND MONTH(ef.Examen_Final_Fecha) = t.MES
    JOIN [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] dim_cat ON cat.Categoria_Descripcion = dim_cat.CURSO_CATEGORIA
    JOIN [NORMALIZADOS].[BI_DIM_ETARIO_ALUMNO] dim_eta 
        ON dim_eta.ALUMNO_RANGO_ETARIO = [NORMALIZADOS].[fx_obtener_rango_etario](alu.Alumno_FechaNacimiento)
    GROUP BY t.TIEMPO_ID, c.Sede_ID, dim_cat.ID, dim_eta.ID
END
GO

-- MIGRACION HECHO 5: ENCUESTA
CREATE OR ALTER PROCEDURE [NORMALIZADOS].[sp_migrar_bi_encuestas] AS
BEGIN
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_ENCUESTA]
        (TIEMPO_ID, SEDE_ID, PROFESOR_RANGO_ETARIO_ID, BLOQUE_SATISFACCION_ID, CANTIDAD_ENCUESTAS)
    SELECT
        t.TIEMPO_ID,
        sede.SEDE_ID,
        dim_eta.ID,
        dim_bloque.BLOQUE_ID,
        COUNT(*) AS CANTIDAD_ENCUESTAS
    FROM [NORMALIZADOS].[Encuesta] enc
        INNER JOIN [NORMALIZADOS].[Detalle_Encuesta] de ON de.Encuesta_ID = enc.Encuesta_ID
        INNER JOIN [NORMALIZADOS].[Curso] c ON enc.Curso_Codigo = c.Curso_Codigo
        INNER JOIN [NORMALIZADOS].[Profesor] p ON p.Profesor_ID = c.Profesor_ID
        INNER JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(enc.Encuesta_FechaRegistro) = t.ANIO AND MONTH(enc.Encuesta_FechaRegistro) = t.MES
        INNER JOIN [NORMALIZADOS].[BI_DIM_SEDE] sede ON sede.SEDE_ID = c.Sede_ID
        INNER JOIN [NORMALIZADOS].[BI_DIM_ETARIO_PROFESOR] dim_eta 
            ON dim_eta.PROFESOR_RANGO_ETARIO = [NORMALIZADOS].[fx_obtener_rango_etario](p.Profesor_FechaNacimiento)
        INNER JOIN [NORMALIZADOS].[BI_DIM_BLOQUES_SATISFACCION] dim_bloque
            ON dim_bloque.BLOQUE_DESCRIPCION = 
            CASE 
                WHEN de.Encuesta_Nota BETWEEN 7 AND 10 THEN 'Satisfechos'
                WHEN de.Encuesta_Nota BETWEEN 1 AND 4 THEN 'Insatisfechos'
                ELSE 'Neutrales'
            END
    GROUP BY
        dim_bloque.BLOQUE_ID,
        t.TIEMPO_ID,
        sede.SEDE_ID,
        dim_eta.ID
    ORDER BY t.TIEMPO_ID, sede.SEDE_ID, dim_bloque.BLOQUE_ID
END
GO

CREATE OR ALTER PROCEDURE [NORMALIZADOS].[sp_migrar_bi_hechos] AS
BEGIN
    -- -- ------------------------------------------
    -- -- MIGRACION HECHO 7: PAGO 
    -- -- ------------------------------------------
    -- -- Parte A: Pagos Reales
    -- INSERT INTO [NORMALIZADOS].[BI_HECHOS_PAGO] (TIEMPO_ID, IMPORTE_PAGADO, IMPORTE_FACTURADO, PAGO_EN_TERMINO, PAGO_FUERA_TERMINO)
    -- SELECT
    --     t.TIEMPO_ID,
    --     p.Pago_Importe,
    --     0, 
    --     CASE WHEN p.Pago_Fecha <= f.Factura_FechaVencimiento THEN 1 ELSE 0 END,
    --     CASE WHEN p.Pago_Fecha > f.Factura_FechaVencimiento THEN 1 ELSE 0 END
    -- FROM [NORMALIZADOS].[Pago] p
    -- JOIN [NORMALIZADOS].[Factura] f ON p.Factura_Numero = f.Factura_Numero
    -- JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(p.Pago_Fecha) = t.ANIO AND MONTH(p.Pago_Fecha) = t.MES;

    -- -- Parte B: Deudas
    -- INSERT INTO [NORMALIZADOS].[BI_HECHOS_PAGO] (TIEMPO_ID, IMPORTE_PAGADO, IMPORTE_FACTURADO, PAGO_EN_TERMINO, PAGO_FUERA_TERMINO)
    -- SELECT 
    --     t.TIEMPO_ID,
    --     0,
    --     f.Factura_Total,
    --     0, 0
    -- FROM [NORMALIZADOS].[Factura] f
    -- JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(f.Factura_FechaEmision) = t.ANIO AND MONTH(f.Factura_FechaEmision) = t.MES
    -- WHERE NOT EXISTS (SELECT 1 FROM [NORMALIZADOS].[Pago] p WHERE p.Factura_Numero = f.Factura_Numero);

    -- -- ------------------------------------------
    -- -- MIGRACION HECHO 8: INGRESOS 
    -- -- ------------------------------------------
    -- INSERT INTO [NORMALIZADOS].[BI_HECHOS_INGRESOS] (TIEMPO_ID, CATEGORIA_CURSO_CODIGO, SEDE_ID, TOTAL_INGRESOS)
    -- SELECT
    --     t.TIEMPO_ID,
    --     dim_cat.ID,
    --     c.Sede_ID,
    --     SUM(p.Pago_Importe)
    -- FROM [NORMALIZADOS].[Pago] p
    -- JOIN [NORMALIZADOS].[Factura] f ON p.Factura_Numero = f.Factura_Numero
    -- JOIN [NORMALIZADOS].[Detalle_Factura] df ON f.Factura_Numero = df.Factura_Numero
    -- JOIN [NORMALIZADOS].[Curso] c ON df.Curso_Codigo = c.Curso_Codigo
    -- JOIN [NORMALIZADOS].[Categoria] cat ON c.Categoria_ID = cat.Categoria_ID
    -- JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(p.Pago_Fecha) = t.ANIO AND MONTH(p.Pago_Fecha) = t.MES
    -- JOIN [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] dim_cat ON cat.Categoria_Descripcion = dim_cat.CURSO_CATEGORIA
    -- GROUP BY t.TIEMPO_ID, dim_cat.ID, c.Sede_ID;
------------------------------------------------------------------

-- ------------------------------------------
    -- MIGRACION HECHO 4: PAGO (CORREGIDO: Apunta a ID -1 si es nulo)
    -- ------------------------------------------
    ;WITH Finanzas_Unificadas AS (
        -- Bloque Facturación (Deuda)
        SELECT 
            f.Factura_FechaEmision AS Fecha_Evento,
            c.Sede_ID,
            cat.Categoria_Descripcion,
            CAST(NULL AS VARCHAR(255)) AS Medio_Pago_Nombre,
            0 AS Importe_Pagado,
            df.Detalle_Factura_Importe AS Importe_Facturado, 
            0 AS Pago_En_Termino,
            0 AS Pago_Fuera_Termino
        FROM [NORMALIZADOS].[Factura] f
        JOIN [NORMALIZADOS].[Detalle_Factura] df ON f.Factura_Numero = df.Factura_Numero
        JOIN [NORMALIZADOS].[Curso] c ON df.Curso_Codigo = c.Curso_Codigo
        JOIN [NORMALIZADOS].[Categoria] cat ON c.Categoria_ID = cat.Categoria_ID

        UNION ALL

        -- Bloque Pagos (Cobro)
        SELECT 
            p.Pago_Fecha AS Fecha_Evento,
            c.Sede_ID,
            cat.Categoria_Descripcion,
            p.Pago_MedioPago AS Medio_Pago_Nombre,
            p.Pago_Importe AS Importe_Pagado,
            0 AS Importe_Facturado, 
            CASE WHEN p.Pago_Fecha <= f.Factura_FechaVencimiento THEN 1 ELSE 0 END, 
            CASE WHEN p.Pago_Fecha > f.Factura_FechaVencimiento THEN 1 ELSE 0 END
        FROM [NORMALIZADOS].[Pago] p
        JOIN [NORMALIZADOS].[Factura] f ON p.Factura_Numero = f.Factura_Numero
        JOIN [NORMALIZADOS].[Detalle_Factura] df ON f.Factura_Numero = df.Factura_Numero
        JOIN [NORMALIZADOS].[Curso] c ON df.Curso_Codigo = c.Curso_Codigo
        JOIN [NORMALIZADOS].[Categoria] cat ON c.Categoria_ID = cat.Categoria_ID
    )
    INSERT INTO [NORMALIZADOS].[BI_HECHOS_PAGO]
        (TIEMPO_ID, SEDE_ID, CATEGORIA_CURSO_CODIGO, MEDIO_PAGO_ID, 
        IMPORTE_PAGADO, IMPORTE_FACTURADO, CANTIDAD_PAGOS_EN_TERMINO, CANTIDAD_PAGOS_FUERA_TERMINO)
    SELECT
        t.TIEMPO_ID,
        fu.Sede_ID,
        dim_cat.ID,
        -- AQUI ESTÁ EL ARREGLO: Si no encuentra medio de pago, usa -1 (Pendiente)
        ISNULL(dim_mp.MEDIO_PAGO_ID, -1), 
        
        SUM(fu.Importe_Pagado),
        SUM(fu.Importe_Facturado),
        SUM(fu.Pago_En_Termino),
        SUM(fu.Pago_Fuera_Termino)

    FROM Finanzas_Unificadas fu
    JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON YEAR(fu.Fecha_Evento) = t.ANIO AND MONTH(fu.Fecha_Evento) = t.MES
    JOIN [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] dim_cat ON fu.Categoria_Descripcion = dim_cat.CURSO_CATEGORIA
    LEFT JOIN [NORMALIZADOS].[BI_DIM_MEDIO_PAGO] dim_mp ON fu.Medio_Pago_Nombre = dim_mp.MEDIO_PAGO_NOMBRE
    GROUP BY t.TIEMPO_ID, fu.Sede_ID, dim_cat.ID, ISNULL(dim_mp.MEDIO_PAGO_ID, -1);
END
GO
---------------------------------------------------------------------------------------------------
-- 6. EJECUCIÓN DE MIGRACIÓN
---------------------------------------------------------------------------------------------------
BEGIN TRANSACTION
    EXEC [NORMALIZADOS].[sp_migrar_bi_dimensiones];
    EXEC [NORMALIZADOS].[sp_migrar_bi_hechos_inscripcion];
    EXEC [NORMALIZADOS].[sp_migrar_bi_hechos_curso];
    EXEC [NORMALIZADOS].[sp_migrar_bi_examen_final];
    EXEC [NORMALIZADOS].[sp_migrar_bi_encuestas];
    EXEC [NORMALIZADOS].[sp_migrar_bi_hechos];
COMMIT TRANSACTION
GO

---------------------------------------------------------------------------------------------------
-- 7. CREACIÓN DE VISTAS (Adaptadas a las nuevas Tablas)
---------------------------------------------------------------------------------------------------

-- 1. Categorías y turnos más solicitados
-- Fuente: BI_HECHOS_INSCRIPCION
CREATE VIEW [NORMALIZADOS].[Vista_01_Categorias_Turnos_Mas_Solicitados] AS
SELECT TOP 3
    t.ANIO,
    s.SEDE_NOMBRE,
    dc.CURSO_CATEGORIA,
    dt.CURSO_TURNO,
    SUM(h.CANTIDAD_INSCRIPTOS) as CANTIDAD_TOTAL
FROM [NORMALIZADOS].[BI_HECHOS_INSCRIPCION] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
JOIN [NORMALIZADOS].[BI_DIM_SEDE] s ON h.SEDE_ID = s.SEDE_ID
JOIN [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] dc ON h.CATEGORIA_CURSO_CODIGO = dc.ID
JOIN [NORMALIZADOS].[BI_DIM_TURNO_CURSO] dt ON h.TURNO_CURSO_CODIGO = dt.ID
GROUP BY t.ANIO,
    s.SEDE_ID, s.SEDE_NOMBRE,
    dc.ID, dc.CURSO_CATEGORIA, 
    dt.ID, dt.CURSO_TURNO
ORDER BY 5 DESC;
GO

-- 2. Tasa de rechazo de inscripciones (Por mes y por sede)
-- Fuente: BI_HECHOS_INSCRIPCION
CREATE VIEW [NORMALIZADOS].[Vista_02_Tasa_Rechazo_Inscripciones] AS
SELECT
    t.ANIO,
    t.MES,
    s.SEDE_NOMBRE,
    -- Formula: (Total Rechazados / Total Inscriptos) * 100
    (SUM(CAST(h.CANTIDAD_RECHAZADOS AS DECIMAL(10,2))) / NULLIF(SUM(h.CANTIDAD_INSCRIPTOS),0)) * 100 AS PORCENTAJE_RECHAZO
FROM [NORMALIZADOS].[BI_HECHOS_INSCRIPCION] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
JOIN [NORMALIZADOS].[BI_DIM_SEDE] s ON h.SEDE_ID = s.SEDE_ID
GROUP BY t.ANIO, t.MES, s.SEDE_NOMBRE;
GO

SELECT * FROM [NORMALIZADOS].[BI_HECHOS_INSCRIPCION]
GO
-- 3. Comparación de desempeño de cursada (Aprobación por sede por año)
-- Fuente: BI_HECHOS_CURSO
CREATE VIEW [NORMALIZADOS].[Vista_03_Desempeno_Cursada] AS
SELECT
    t.ANIO,
    s.SEDE_NOMBRE,
    -- Formula: (Aprobados / (Aprobados + Desaprobados)) * 100
    CASE WHEN SUM(h.CANTIDAD_APROBADOS + h.CANTIDAD_DESAPROBADOS) = 0 THEN 0
    ELSE 
        (SUM(CAST(h.CANTIDAD_APROBADOS AS DECIMAL(10,2))) / 
        NULLIF(SUM(h.CANTIDAD_APROBADOS + h.CANTIDAD_DESAPROBADOS),0)) * 100 
    END AS PORCENTAJE_APROBACION

FROM [NORMALIZADOS].[BI_HECHOS_CURSO] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
JOIN [NORMALIZADOS].[BI_DIM_SEDE] s ON h.SEDE_ID = s.SEDE_ID
GROUP BY t.ANIO, s.SEDE_NOMBRE
ORDER BY t.ANIO
GO

-- 4. Tiempo promedio de finalización de curso (Por categoria, por año)
-- Fuente: BI_HECHOS_CURSO
-- Nota: Calculamos el promedio dividiendo la SUMA DE MESES por la CANTIDAD DE ALUMNOS.
CREATE VIEW [NORMALIZADOS].[Vista_04_Tiempo_Promedio_Finalizacion] AS
SELECT
    t.ANIO,
    dc.CURSO_CATEGORIA,
    -- Formula: Suma total de meses / Total de alumnos que finalizaron
    CASE WHEN SUM(h.CANTIDAD_CASOS_FINALIZACION) = 0 THEN 0
    ELSE 
        CAST(SUM(h.SUMATORIA_TIEMPO_FINALIZACION) AS DECIMAL(10,2)) / 
        NULLIF(SUM(h.CANTIDAD_CASOS_FINALIZACION),0)
    END AS PROMEDIO_MESES_FINALIZACION
FROM [NORMALIZADOS].[BI_HECHOS_CURSO] h
INNER JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
INNER JOIN [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] dc ON h.CATEGORIA_CURSO_CODIGO = dc.ID
GROUP BY t.ANIO, dc.CURSO_CATEGORIA
ORDER BY t.ANIO
GO

-- 5. Nota promedio de finales (Rango etario alumno, categoria curso, semestre/SEMESTRE)
-- Fuente: BI_HECHOS_EXAMEN_FINAL
-- Nota: Igual que la anterior, promedio ponderado (Suma Notas / Cantidad Examenes).
CREATE VIEW [NORMALIZADOS].[Vista_05_Promedio_Nota_Finales] AS
SELECT
    t.ANIO,
    t.SEMESTRE,
    da.ALUMNO_RANGO_ETARIO,
    dc.CURSO_CATEGORIA,
    FORMAT(CAST(SUM(h.SUMA_NOTAS_FINAL) AS DECIMAL(10,2)) / 
    NULLIF(SUM(h.CANTIDAD_EXAMENES_CON_NOTA),0), 'N2') AS PROMEDIO_NOTA
FROM [NORMALIZADOS].[BI_HECHOS_EXAMEN_FINAL] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
JOIN [NORMALIZADOS].[BI_DIM_ETARIO_ALUMNO] da ON h.ALUMNO_RANGO_ETARIO_ID = da.ID
JOIN [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] dc ON h.CATEGORIA_CURSO_CODIGO = dc.ID
WHERE h.CANTIDAD_EXAMENES_CON_NOTA > 0
GROUP BY 
    t.ANIO, t.SEMESTRE,
    da.ID, da.ALUMNO_RANGO_ETARIO,
    dc.ID, dc.CURSO_CATEGORIA
GO

-- 6. Tasa de ausentismo finales (Por semestre/SEMESTRE, por sede)
-- Fuente: BI_HECHOS_EXAMEN_FINAL
CREATE VIEW [NORMALIZADOS].[Vista_06_Ausentismo_Finales] AS
SELECT
    t.ANIO,
    t.SEMESTRE,
    s.SEDE_NOMBRE,
    -- Formula: (Ausentes / Total Inscriptos) * 100
    (SUM(CAST(h.CANTIDAD_TOTAL_AUSENTES AS DECIMAL(10,2))) / 
    SUM(h.CANTIDAD_TOTAL_INSCRIPTOS)) * 100 AS PORCENTAJE_AUSENTISMO
FROM [NORMALIZADOS].[BI_HECHOS_EXAMEN_FINAL] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
JOIN [NORMALIZADOS].[BI_DIM_SEDE] s ON h.SEDE_ID = s.SEDE_ID
WHERE h.CANTIDAD_TOTAL_INSCRIPTOS > 0
GROUP BY t.ANIO, t.SEMESTRE, s.SEDE_NOMBRE;
GO

-- 7. Desvío de pagos (Porcentaje pagos fuera de termino por semestre/SEMESTRE)
-- Fuente: BI_HECHOS_PAGO
CREATE VIEW [NORMALIZADOS].[Vista_07_Desvio_Pagos] AS
SELECT
    t.SEMESTRE,
    -- Formula: (Pagos tarde / Total Pagos) * 100
    (SUM(CAST(h.CANTIDAD_PAGOS_FUERA_TERMINO AS DECIMAL(10,2))) / 
     NULLIF(SUM(h.CANTIDAD_PAGOS_EN_TERMINO + h.CANTIDAD_PAGOS_FUERA_TERMINO),0)) * 100 AS PORCENTAJE_PAGOS_TARDIOS
FROM [NORMALIZADOS].[BI_HECHOS_PAGO] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
WHERE (h.CANTIDAD_PAGOS_EN_TERMINO + h.CANTIDAD_PAGOS_FUERA_TERMINO) > 0 -- Solo si hubo pagos
GROUP BY t.SEMESTRE;
GO

-- 8. Tasa de Morosidad Financiera mensual (Importe Adeudado / Facturacion Esperada)
-- Fuente: BI_HECHOS_PAGO
CREATE VIEW [NORMALIZADOS].[Vista_08_Morosidad_Mensual] AS
SELECT
    t.ANIO,
    t.MES,
    -- Deuda = (Facturado - Pagado)
    -- Tasa = Deuda / Facturado
    CASE 
        WHEN SUM(h.IMPORTE_FACTURADO) = 0 THEN 0 
        ELSE ((SUM(h.IMPORTE_FACTURADO) - SUM(h.IMPORTE_PAGADO)) / SUM(h.IMPORTE_FACTURADO)) * 100 
    END AS TASA_MOROSIDAD
FROM [NORMALIZADOS].[BI_HECHOS_PAGO] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
GROUP BY t.ANIO, t.MES;
GO

-- 9. Ingresos por categoría de cursos (Top 3 por sede, por año)
-- Fuente: BI_HECHOS_PAGO (Antes era Ingresos, ahora unificado)
CREATE VIEW [NORMALIZADOS].[Vista_09_Ingresos_Categoria] AS
SELECT TOP 3 WITH TIES
    t.ANIO,
    s.SEDE_NOMBRE,
    dc.CURSO_CATEGORIA,
    SUM(h.IMPORTE_PAGADO) AS TOTAL_INGRESOS
FROM [NORMALIZADOS].[BI_HECHOS_PAGO] h
JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
JOIN [NORMALIZADOS].[BI_DIM_SEDE] s ON h.SEDE_ID = s.SEDE_ID
JOIN [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] dc ON h.CATEGORIA_CURSO_CODIGO = dc.ID
GROUP BY t.ANIO, s.SEDE_NOMBRE, dc.CURSO_CATEGORIA
ORDER BY t.ANIO, s.SEDE_NOMBRE, TOTAL_INGRESOS DESC;
GO

-- 10. Índice de satisfacción (Por rango etario profesor y sede)
-- Fuente: BI_HECHOS_ENCUESTA
CREATE VIEW [NORMALIZADOS].[Vista_10_Indice_Satisfaccion] AS
SELECT
    t.ANIO,
    s.SEDE_NOMBRE,
    dp.PROFESOR_RANGO_ETARIO,
    ((
      (SUM(CASE WHEN db.BLOQUE_DESCRIPCION = 'Satisfechos' THEN h.CANTIDAD_ENCUESTAS ELSE 0 END) * 1.0 / SUM(h.CANTIDAD_ENCUESTAS)) 
      - 
      (SUM(CASE WHEN db.BLOQUE_DESCRIPCION = 'Insatisfechos' THEN h.CANTIDAD_ENCUESTAS ELSE 0 END) * 1.0 / SUM(h.CANTIDAD_ENCUESTAS))
     ) * 100 + 100) / 2 AS INDICE_SATISFACCION
FROM [NORMALIZADOS].[BI_HECHOS_ENCUESTA] h
JOIN [NORMALIZADOS].[BI_DIM_SEDE] s ON h.SEDE_ID = s.SEDE_ID
JOIN [NORMALIZADOS].[BI_DIM_ETARIO_PROFESOR] dp ON h.PROFESOR_RANGO_ETARIO_ID = dp.ID
JOIN [NORMALIZADOS].[BI_DIM_BLOQUES_SATISFACCION] db ON h.BLOQUE_SATISFACCION_ID = db.BLOQUE_ID
INNER JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] t ON h.TIEMPO_ID = t.TIEMPO_ID
GROUP BY 
    s.SEDE_ID, s.SEDE_NOMBRE, 
    dp.ID, dp.PROFESOR_RANGO_ETARIO,
    t.ANIO
HAVING SUM(h.CANTIDAD_ENCUESTAS) > 0
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