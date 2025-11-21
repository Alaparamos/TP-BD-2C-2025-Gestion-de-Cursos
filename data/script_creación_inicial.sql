USE [GD2C2025]
GO

-- Drop de los indices
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Curso_Profesor')
    DROP INDEX IX_Curso_Profesor ON [NORMALIZADOS].[Curso];
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Curso_Sede')
    DROP INDEX IX_Curso_Sede ON [NORMALIZADOS].[Curso];
GO
-- Drop de tablas
DROP TABLE IF EXISTS [NORMALIZADOS].[Detalle_Encuesta];
DROP TABLE IF EXISTS [NORMALIZADOS].[Encuesta];
DROP TABLE IF EXISTS [NORMALIZADOS].[Pago];
DROP TABLE IF EXISTS [NORMALIZADOS].[Detalle_Factura];
DROP TABLE IF EXISTS [NORMALIZADOS].[Factura];
DROP TABLE IF EXISTS [NORMALIZADOS].[Inscripcion_Final];
DROP TABLE IF EXISTS [NORMALIZADOS].[Evaluacion_Final];
DROP TABLE IF EXISTS [NORMALIZADOS].[Examen_Final];
DROP TABLE IF EXISTS [NORMALIZADOS].[Trabajo_Practico];
DROP TABLE IF EXISTS [NORMALIZADOS].[Evaluacion_x_Alumno];
DROP TABLE IF EXISTS [NORMALIZADOS].[Evaluacion_Curso];
DROP TABLE IF EXISTS [NORMALIZADOS].[Modulo_x_Curso];
DROP TABLE IF EXISTS [NORMALIZADOS].[Inscripcion];
DROP TABLE IF EXISTS [NORMALIZADOS].[Curso];
DROP TABLE IF EXISTS [NORMALIZADOS].[Modulo];
DROP TABLE IF EXISTS [NORMALIZADOS].[Categoria];
DROP TABLE IF EXISTS [NORMALIZADOS].[Profesor];
DROP TABLE IF EXISTS [NORMALIZADOS].[Alumno];
DROP TABLE IF EXISTS [NORMALIZADOS].[Sede];
DROP TABLE IF EXISTS [NORMALIZADOS].[Institucion];
DROP TABLE IF EXISTS [NORMALIZADOS].[Localidad];
DROP TABLE IF EXISTS [NORMALIZADOS].[Provincia];
GO

-- Drop de los procedures
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND SCHEMA_NAME(schema_id) = 'NORMALIZADOS')
BEGIN
DROP PROCEDURE IF EXISTS
    [NORMALIZADOS].[sp_migrar_localidades_provincias],
    [NORMALIZADOS].[sp_migrar_institucion],
    [NORMALIZADOS].[sp_migrar_sede],
    [NORMALIZADOS].[sp_migrar_alumno],
    [NORMALIZADOS].[sp_migrar_profesor],
    [NORMALIZADOS].[sp_migrar_inscripcion],
    [NORMALIZADOS].[sp_migrar_categorias],
    [NORMALIZADOS].[sp_migrar_cursos],
    [NORMALIZADOS].[sp_migrar_modulo],
    [NORMALIZADOS].[sp_migrar_modulo_x_curso],
    [NORMALIZADOS].[sp_migrar_evaluacion_curso],
    [NORMALIZADOS].[sp_migrar_evaluacion_x_alumno],
    [NORMALIZADOS].[sp_migrar_trabajo_practico],
    [NORMALIZADOS].[sp_migrar_examen_final],
    [NORMALIZADOS].[sp_migrar_evaluacion_final],
    [NORMALIZADOS].[sp_migrar_inscripcion_final],
    [NORMALIZADOS].[sp_migrar_factura],
    [NORMALIZADOS].[sp_migrar_detalle_factura],
    [NORMALIZADOS].[sp_migrar_pago],
    [NORMALIZADOS].[sp_migrar_encuesta],
    [NORMALIZADOS].[sp_migrar_detalle_encuesta]
    ;
END
GO

-- Drop del schema
IF EXISTS (SELECT * FROM sys.schemas WHERE name = 'NORMALIZADOS')
    DROP SCHEMA [NORMALIZADOS];
GO

CREATE SCHEMA NORMALIZADOS;
GO

CREATE TABLE [NORMALIZADOS].[Provincia] (
    Id_Provincia BIGINT IDENTITY(1,1) PRIMARY KEY,
    Provincia_Nombre NVARCHAR(255) NOT NULL
);
GO

CREATE TABLE [NORMALIZADOS].[Localidad] (
    Id_Localidad BIGINT IDENTITY(1,1) PRIMARY KEY,
    Localidad_Nombre NVARCHAR(255) NOT NULL,
    Id_Provincia BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Provincia](Id_Provincia)
);
GO


CREATE TABLE [NORMALIZADOS].[Institucion] (
    Institucion_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Institucion_Nombre NVARCHAR(255) NOT NULL,
    Institucion_RazonSocial NVARCHAR(255) NOT NULL,
    Institucion_Cuit NVARCHAR(255) UNIQUE
);
GO

CREATE TABLE [NORMALIZADOS].[Sede] (
    Sede_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Sede_Nombre NVARCHAR(255) NOT NULL,
    Id_Localidad BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Localidad](Id_Localidad),
    Sede_Direccion NVARCHAR(255),
    Sede_Telefono NVARCHAR(255),
    Sede_Mail NVARCHAR(255),
    Institucion_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Institucion](Institucion_ID)
);
GO


CREATE TABLE [NORMALIZADOS].[Alumno] (
	Alumno_Legajo BIGINT PRIMARY KEY,
    Alumno_Dni BIGINT,
    Alumno_Nombre VARCHAR(255),
    Alumno_Apellido VARCHAR(255),
    Alumno_FechaNacimiento DATETIME2(6),
    Alumno_Direccion VARCHAR(255),
    Alumno_Telefono VARCHAR(255),
    Alumno_Mail VARCHAR(255),
    Id_Localidad BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Localidad](Id_Localidad)
);
GO

CREATE TABLE [NORMALIZADOS].[Profesor] (
    Profesor_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Profesor_Nombre NVARCHAR(255) NOT NULL,
    Profesor_Apellido NVARCHAR(255) NOT NULL,
    Profesor_Dni NVARCHAR(255) NOT NULL,
    Profesor_FechaNacimiento DATETIME2(6) NOT NULL,
    Profesor_Direccion NVARCHAR(255),
    Profesor_Telefono NVARCHAR(255),
    Profesor_Mail NVARCHAR(255),
    Id_Localidad BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Localidad](Id_Localidad)
);
GO

CREATE TABLE [NORMALIZADOS].[Categoria] (
    Categoria_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Categoria_Descripcion VARCHAR(255) NOT NULL
);
GO

CREATE TABLE [NORMALIZADOS].[Curso] (
    Curso_Codigo BIGINT PRIMARY KEY,
    Curso_Nombre VARCHAR(255) NOT NULL,
    Curso_Descripcion VARCHAR(255),
    Curso_Turno VARCHAR(255) 
        CHECK (Curso_Turno IN ('Mañana','Tarde','Noche')),
    Curso_Dia VARCHAR(255)
        CHECK (Curso_Dia IN ('Lunes','Martes','Miercoles','Jueves','Viernes','Sabado','Domingo')),
    Curso_FechaInicio DATETIME2(6) NOT NULL,
    Curso_FechaFin DATETIME2(6) NOT NULL,
    Curso_DuracionMeses BIGINT NOT NULL,  -- opcionalmente calculable -> VER DE ELIMINARLO
    Curso_PrecioMensual DECIMAL(38,2) NOT NULL,
    Categoria_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Categoria](Categoria_ID),
    Sede_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Sede](Sede_ID),
    Profesor_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Profesor](Profesor_ID)
);
GO


CREATE INDEX IX_Curso_Profesor ON [NORMALIZADOS].Curso(Profesor_ID);
CREATE INDEX IX_Curso_Sede ON [NORMALIZADOS].Curso(Sede_ID);
GO

-- Tabla Inscripcion
CREATE TABLE [NORMALIZADOS].[Inscripcion] (
    Inscripcion_Numero BIGINT PRIMARY KEY,
    Inscripcion_Fecha DATETIME2(6) NOT NULL,
    Inscripcion_Estado VARCHAR(255) 
        CHECK(Inscripcion_Estado IN ('Pendiente','Confirmada', 'Rechazada')),
    Inscripcion_FechaRespuesta DATETIME2(6),
    Alumno_Legajo BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Alumno](Alumno_Legajo),
    Curso_Codigo BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Curso](Curso_Codigo)
);
GO

-- Tabla Modulo
CREATE TABLE [NORMALIZADOS].[Modulo] (
    Modulo_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Modulo_Nombre VARCHAR(255) NOT NULL,
    Modulo_Descripcion VARCHAR(255)
);
GO

-- Tabla Modulo_x_Curso INTERMEDIA
CREATE TABLE [NORMALIZADOS].[Modulo_x_Curso] (
    Modulo_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Modulo](Modulo_ID),
    Curso_Codigo BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Curso](Curso_Codigo),
    PRIMARY KEY (Modulo_ID, Curso_Codigo)
);
GO

-- Tabla Evaluacion_Curso
CREATE TABLE [NORMALIZADOS].[Evaluacion_Curso](
    Evaluacion_Curso_ID  BIGINT IDENTITY(1,1) PRIMARY KEY,
    Evaluacion_Curso_fechaEvaluacion DATETIME2(6) NOT NULL,
    Modulo_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Modulo](Modulo_ID)
);
GO

-- Tabla Evaluacion_x_Alumno INTERMEDIA
CREATE TABLE [NORMALIZADOS].[Evaluacion_x_Alumno] (
    Evaluacion_Curso_ID  BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Evaluacion_Curso](Evaluacion_Curso_ID),
    Alumno_Legajo BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Alumno](Alumno_Legajo),
    Evaluacion_Nota BIGINT,
    Evaluacion_Presente BIT,
    Evaluacion_Instancia BIGINT
    PRIMARY KEY (Evaluacion_Curso_ID, Alumno_Legajo)
);
GO

-- Tabla Trabajo_Practico
CREATE TABLE [NORMALIZADOS].[Trabajo_Practico] (
    Trabajo_Practico_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Trabajo_Practico_Nota BIGINT,
    Trabajo_Practico_FechaEvaluacion DATETIME2(6) NOT NULL,
    Curso_Codigo BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Curso](Curso_Codigo),
    Alumno_Legajo BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Alumno](Alumno_Legajo)
);
GO

-- Tabla Examen_Final
create table [NORMALIZADOS].[Examen_Final](
    Examen_Final_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Examen_Final_Hora VARCHAR(255),
    Examen_Final_Fecha DATETIME2(6),
    Examen_Final_Descripcion VARCHAR(255),
    Curso_Codigo BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Curso](Curso_Codigo)
);
GO

-- Tabla Evaluacion_Final
CREATE TABLE [NORMALIZADOS].[Evaluacion_Final] (
    Evaluacion_Final_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Evaluacion_Final_Nota BIGINT,
    Evaluacion_Final_Presente BIT,
    Examen_Final_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Examen_Final](Examen_Final_ID),
    Alumno_Legajo BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Alumno](Alumno_Legajo),
    Profesor_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Profesor](Profesor_ID)
);
GO

-- Tabla Inscripcion_Final
CREATE TABLE [NORMALIZADOS].[Inscripcion_Final] (
    Inscripcion_Final_Nro BIGINT IDENTITY(1,1) PRIMARY KEY,
    Inscripcion_Final_Fecha DATETIME2(6) NOT NULL,
    Examen_Final_ID BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Examen_Final](Examen_Final_ID),
    Alumno_Legajo BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Alumno](Alumno_Legajo)
);
GO

-- Tabla Factura
CREATE TABLE [NORMALIZADOS].[Factura] (
    Factura_Numero BIGINT PRIMARY KEY,
    Factura_FechaEmision DATETIME2(6) NOT NULL,
    Factura_FechaVencimiento DATETIME2(6) NOT NULL,
    Factura_Total DECIMAL(18,2) NOT NULL,
    Alumno_Legajo BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Alumno](Alumno_Legajo)
);
GO

-- Tabla Detalle_Factura
CREATE TABLE [NORMALIZADOS].[Detalle_Factura] (
    Detalle_Factura_Numero BIGINT IDENTITY(1,1) PRIMARY KEY,
    Curso_Codigo BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Curso](Curso_Codigo),
    Periodo_Año BIGINT,
    Periodo_Mes BIGINT,
    Detalle_Factura_Importe DECIMAL(18, 2),
    Factura_Numero BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Factura](Factura_Numero)
);
GO

-- Tabla Pago
CREATE TABLE [NORMALIZADOS].[Pago] (
    Pago_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Pago_Fecha DATETIME2(6) NOT NULL,
    Pago_Importe DECIMAL(18,2) NOT NULL,
    Pago_MedioPago VARCHAR(255),
    Factura_Numero BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Factura](Factura_Numero)
);
GO

-- Tabla Encuesta
CREATE TABLE [NORMALIZADOS].[Encuesta] (
    Encuesta_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Curso_Codigo BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Curso](Curso_Codigo),
    Encuesta_FechaRegistro DATETIME2(6) NOT NULL,
    Encuesta_Observacion VARCHAR(255)
);
GO

-- Tabla Detalle_Encuesta
CREATE TABLE [NORMALIZADOS].[Detalle_Encuesta] (
    Detalle_Encuesta_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Encuesta_ID BIGINT NOT NULL FOREIGN KEY REFERENCES [NORMALIZADOS].[Encuesta](Encuesta_ID),
    Encuesta_Pregunta VARCHAR(255) NOT NULL,
    Encuesta_Nota BIGINT NOT NULL
        CHECK (Encuesta_Nota BETWEEN 1 AND 10)
);
GO


-- ----------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------
-- --------------- PROCEDIMIENTOS ALMACENADOS PARA MIGRAR DATOS ---------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------


-- PROVINCIAS Y LOCALIDADES
CREATE PROCEDURE [NORMALIZADOS].sp_migrar_localidades_provincias AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Provincia] (Provincia_Nombre)
        -- Institucion tiene cambiado Sede_Localidad por Sede_Provincia
        SELECT Sede_Localidad FROM [GD2C2025].[gd_esquema].[Maestra]
        WHERE Sede_Localidad is NOT NULL
        UNION
        SELECT Profesor_Provincia FROM [GD2C2025].[gd_esquema].[Maestra]
        WHERE Profesor_Provincia is NOT NULL
        UNION
        SELECT Alumno_Provincia FROM [GD2C2025].[gd_esquema].[Maestra]
        WHERE Alumno_Provincia is NOT NULL
    INSERT INTO [NORMALIZADOS].[Localidad] (Localidad_Nombre, Id_Provincia)
        SELECT localidades.Localidad_Nombre, p.Id_Provincia
        FROM (
            SELECT Sede_Localidad as Provincia_Nombre, Sede_Provincia as Localidad_Nombre
            FROM [GD2C2025].[gd_esquema].[Maestra]
            WHERE Sede_Localidad is NOT NULL AND Sede_Provincia IS NOT NULL
            UNION
            SELECT Profesor_Provincia as Provincia_Nombre, Profesor_Localidad as Localidad_Nombre
            FROM [GD2C2025].[gd_esquema].[Maestra]
            WHERE Profesor_Provincia is NOT NULL AND Profesor_Localidad IS NOT NULL
            UNION
            SELECT Alumno_Provincia as Provincia_Nombre, Alumno_Localidad as Localidad_Nombre
            FROM [GD2C2025].[gd_esquema].[Maestra]
            WHERE Alumno_Provincia is NOT NULL AND Alumno_Localidad IS NOT NULL
        ) as localidades
        INNER JOIN [NORMALIZADOS].[Provincia] p
        ON localidades.Provincia_Nombre = p.Provincia_Nombre
END
GO

-- INSTITUCION
CREATE PROCEDURE [NORMALIZADOS].sp_migrar_institucion AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Institucion] 
    SELECT DISTINCT Institucion_Nombre, Institucion_RazonSocial, Institucion_Cuit FROM [GD2C2025].[gd_esquema].[Maestra]
    WHERE Institucion_Nombre IS NOT NULL AND Institucion_RazonSocial IS NOT NULL
END
GO

-- SEDE
CREATE PROCEDURE [NORMALIZADOS].sp_migrar_sede AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Sede] (Sede_Nombre, Id_Localidad, Sede_Telefono, Sede_Mail, Sede_Direccion, Institucion_ID)
    SELECT DISTINCT Sede_Nombre, localidad.Id_Localidad AS Id_Localidad, Sede_Telefono, Sede_Mail, Sede_Direccion, institucion.Institucion_ID AS Id_Institucion
    FROM [GD2C2025].[gd_esquema].[Maestra] maestra
        INNER JOIN [NORMALIZADOS].[Localidad] localidad ON localidad.Localidad_Nombre = maestra.Sede_Provincia
        INNER JOIN [NORMALIZADOS].[Provincia] provincia ON provincia.Provincia_Nombre = maestra.Sede_Localidad AND localidad.Id_Provincia = provincia.Id_Provincia
        INNER JOIN [NORMALIZADOS].[Institucion] institucion ON institucion.Institucion_Cuit = maestra.Institucion_Cuit
    WHERE Sede_Nombre IS NOT NULL
END
GO

-- ALUMNO
CREATE PROCEDURE [NORMALIZADOS].sp_migrar_alumno AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Alumno](Alumno_Legajo, Alumno_DNI, Alumno_Nombre, Alumno_Apellido, Alumno_FechaNacimiento, Alumno_Direccion, Alumno_Telefono, Alumno_Mail, Id_Localidad)
    SELECT DISTINCT 
        Alumno_Legajo,
        Alumno_DNI,
        Alumno_Nombre,
        Alumno_Apellido,
        Alumno_FechaNacimiento,
        Alumno_Direccion,
        Alumno_Telefono,
        Alumno_Mail,
        localidad.Id_Localidad AS Id_Localidad
    FROM [GD2C2025].[gd_esquema].[Maestra] maestra
        INNER JOIN [NORMALIZADOS].[Localidad] localidad ON localidad.Localidad_Nombre = maestra.Alumno_Localidad
        INNER JOIN [NORMALIZADOS].[Provincia] provincia ON provincia.Provincia_Nombre = maestra.Alumno_Provincia AND localidad.Id_Provincia = provincia.Id_Provincia
    WHERE Alumno_Legajo IS NOT NULL
END
GO

-- PROFESOR
CREATE PROCEDURE [NORMALIZADOS].sp_migrar_profesor AS
BEGIN 
    INSERT INTO [NORMALIZADOS].[Profesor] (Profesor_Nombre, Profesor_Apellido, Profesor_Dni, Profesor_FechaNacimiento,Profesor_Direccion,
    Profesor_Telefono,Profesor_Mail, Id_Localidad)
    SELECT DISTINCT Profesor_Nombre, Profesor_Apellido, Profesor_Dni, Profesor_FechaNacimiento,Profesor_Direccion,
    Profesor_Telefono,Profesor_Mail, localidad.Id_Localidad AS Id_Localidad
    FROM [GD2C2025].[gd_esquema].[Maestra] maestra
        INNER JOIN [NORMALIZADOS].[Localidad] localidad ON localidad.Localidad_Nombre = maestra.Sede_Localidad 
    WHERE Profesor_Nombre IS NOT NULL
END
GO

-- CATEGORIA
CREATE PROCEDURE [NORMALIZADOS].sp_migrar_categorias AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Categoria] (Categoria_Descripcion)
    SELECT DISTINCT Curso_Categoria AS nombre FROM [GD2C2025].[gd_esquema].[Maestra]
    WHERE Curso_Categoria IS NOT NULL
    ORDER BY Curso_Categoria ASC
END
GO

-- CURSO
CREATE PROCEDURE [NORMALIZADOS].sp_migrar_cursos AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Curso] (Curso_Codigo, Curso_Nombre, Curso_Descripcion, Curso_Turno, Curso_Dia, Curso_FechaInicio, Curso_FechaFin,
    Curso_DuracionMeses, Curso_PrecioMensual, Categoria_ID, Sede_ID, Profesor_ID)
    SELECT DISTINCT 
        Curso_Codigo,
        Curso_Nombre,
        Curso_Descripcion,
        Curso_Turno, 
        Curso_Dia, --se interpreta que se cursa una vez por semana (segun tabla maestra)
        Curso_FechaInicio,
        Curso_FechaFin,
        Curso_DuracionMeses,
        Curso_PrecioMensual,
        categoria.Categoria_ID AS Categoria_ID,
        sede.Sede_ID AS Sede_ID,
        profesor.Profesor_Id AS Profesor_ID
    FROM [GD2C2025].[gd_esquema].[Maestra] maestra
        INNER JOIN [NORMALIZADOS].[Categoria] categoria ON categoria.Categoria_Descripcion = maestra.Curso_Categoria
        INNER JOIN [NORMALIZADOS].[Sede] sede ON sede.Sede_Nombre = maestra.Sede_Nombre
        INNER JOIN [NORMALIZADOS].[Profesor] profesor ON profesor.Profesor_Dni = maestra.Profesor_Dni
    WHERE Curso_Codigo IS NOT NULL
END
GO

-- INSCRIPCION
CREATE PROCEDURE [NORMALIZADOS].sp_migrar_inscripcion AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Inscripcion] (Inscripcion_Numero, Inscripcion_Fecha, Inscripcion_Estado, Inscripcion_FechaRespuesta, Alumno_Legajo, Curso_Codigo)
    SELECT DISTINCT 
        Inscripcion_Numero,
        Inscripcion_Fecha,
        Inscripcion_Estado,
        Inscripcion_FechaRespuesta,
        alumno.Alumno_Legajo AS Alumno_Legajo,
        curso.Curso_Codigo AS Curso_Codigo
    FROM [GD2C2025].[gd_esquema].[Maestra] maestra
        INNER JOIN [NORMALIZADOS].[Curso] curso ON curso.Curso_Codigo = maestra.Curso_Codigo
        INNER JOIN [NORMALIZADOS].[Alumno] alumno ON alumno.Alumno_Legajo = maestra.Alumno_Legajo
    WHERE Inscripcion_Numero IS NOT NULL
END
GO

-- MODULO
CREATE PROCEDURE [NORMALIZADOS].sp_migrar_modulo AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Modulo] (Modulo_Nombre, Modulo_Descripcion)
    SELECT DISTINCT 
        Modulo_Nombre,
        Modulo_Descripcion
    FROM [GD2C2025].[gd_esquema].[Maestra]
    WHERE Modulo_Nombre IS NOT NULL
END
GO

-- MODULO X CURSO
CREATE PROCEDURE [NORMALIZADOS].sp_migrar_modulo_x_curso AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Modulo_x_Curso] (Modulo_ID, Curso_Codigo)
    SELECT DISTINCT 
        modulo.Modulo_ID AS Modulo_ID,
        curso.Curso_Codigo AS Curso_Codigo
    FROM [GD2C2025].[gd_esquema].[Maestra] maestra
        INNER JOIN [NORMALIZADOS].[Modulo] modulo ON modulo.Modulo_Nombre = maestra.Modulo_Nombre
        INNER JOIN [NORMALIZADOS].[Curso] curso ON curso.Curso_Codigo = maestra.Curso_Codigo
    WHERE maestra.Modulo_Nombre IS NOT NULL
END
GO


CREATE PROCEDURE [NORMALIZADOS].sp_migrar_evaluacion_curso AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Evaluacion_Curso] (Evaluacion_Curso_fechaEvaluacion, Modulo_ID)
    SELECT Evaluacion_Curso_fechaEvaluacion, modulo.Modulo_ID
    FROM [GD2C2025].[gd_esquema].[Maestra] maestra
        INNER JOIN [NORMALIZADOS].[Modulo] modulo ON modulo.Modulo_Nombre = maestra.Modulo_Nombre
        INNER JOIN [NORMALIZADOS].[Modulo_x_Curso] mxc ON mxc.Modulo_ID = modulo.Modulo_ID AND maestra.Curso_Codigo = mxc.Curso_Codigo
    WHERE maestra.Modulo_Nombre IS NOT NULL
END
GO


CREATE OR ALTER PROCEDURE [NORMALIZADOS].sp_migrar_evaluacion_x_alumno AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Evaluacion_x_Alumno] (Evaluacion_Curso_ID, Alumno_Legajo, Evaluacion_Nota, Evaluacion_Presente, Evaluacion_Instancia)
    SELECT
    (SELECT e.Modulo_ID FROM [NORMALIZADOS].[Modulo] e WHERE e.Modulo_Nombre = m.Modulo_Nombre) AS Evaluacion_Curso_ID,
    m.Alumno_Legajo,
    m.Evaluacion_Curso_Nota,
    m.Evaluacion_Curso_Presente,
    m.Evaluacion_Curso_Instancia
    FROM [GD2C2025].[gd_esquema].[Maestra] m
    WHERE m.Alumno_Legajo IN (SELECT Alumno_Legajo FROM [NORMALIZADOS].[Alumno]) AND m.Evaluacion_Curso_Presente IS NOT NULL
        AND m.Evaluacion_Curso_fechaEvaluacion IS NOT NULL
END
GO

-- TRABAJO PRACTICO
CREATE PROCEDURE [NORMALIZADOS].sp_migrar_trabajo_practico AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Trabajo_Practico] (Trabajo_Practico_Nota, Trabajo_Practico_FechaEvaluacion, Curso_Codigo, Alumno_Legajo)
    SELECT DISTINCT 
        Trabajo_Practico_Nota,
        Trabajo_Practico_FechaEvaluacion,
        curso.Curso_Codigo AS Curso_Codigo,
        alumno.Alumno_Legajo AS Alumno_Legajo
    FROM [GD2C2025].[gd_esquema].[Maestra] maestra
        INNER JOIN [NORMALIZADOS].[Curso] curso ON curso.Curso_Codigo = maestra.Curso_Codigo
        INNER JOIN [NORMALIZADOS].[Alumno] alumno ON alumno.Alumno_Legajo = maestra.Alumno_Legajo
    WHERE Trabajo_Practico_FechaEvaluacion IS NOT NULL
END
GO

-- EXAMEN FINAL
CREATE PROCEDURE [NORMALIZADOS].sp_migrar_examen_final AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Examen_Final] (Examen_Final_Hora, Examen_Final_Fecha, Examen_Final_Descripcion, Curso_Codigo)
    SELECT DISTINCT 
        Examen_Final_Hora,
        Examen_Final_Fecha,
        Examen_Final_Descripcion,
        curso.Curso_Codigo AS Curso_Codigo
    FROM [GD2C2025].[gd_esquema].[Maestra] maestra
        INNER JOIN [NORMALIZADOS].[Curso] curso ON curso.Curso_Codigo = maestra.Curso_Codigo
    WHERE Examen_Final_Fecha IS NOT NULL
END
GO

-- EVALUACION FINAL
CREATE PROCEDURE [NORMALIZADOS].sp_migrar_evaluacion_final AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Evaluacion_Final] (Evaluacion_Final_Nota, Evaluacion_Final_Presente, Examen_Final_ID, Alumno_Legajo, Profesor_ID)
    SELECT DISTINCT 
        Evaluacion_Final_Nota,
        Evaluacion_Final_Presente,
        examen.Examen_Final_ID AS Examen_Final_ID,
        alumno.Alumno_Legajo AS Alumno_Legajo,
        profesor.Profesor_ID AS Profesor_ID
    FROM [GD2C2025].[gd_esquema].[Maestra] maestra
        INNER JOIN [NORMALIZADOS].[Examen_Final] examen ON examen.Curso_Codigo = maestra.Curso_Codigo
        INNER JOIN [NORMALIZADOS].[Alumno] alumno ON alumno.Alumno_Legajo = maestra.Alumno_Legajo
        INNER JOIN [NORMALIZADOS].[Profesor] profesor ON profesor.Profesor_Dni = maestra.Profesor_Dni
    WHERE Evaluacion_Final_Nota IS NOT NULL
END
GO

-- INSCRIPCION FINAL
CREATE PROCEDURE [NORMALIZADOS].sp_migrar_inscripcion_final AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Inscripcion_Final] (Inscripcion_Final_Fecha, Examen_Final_ID, Alumno_Legajo)
    SELECT DISTINCT 
        Inscripcion_Final_Fecha,
        examen.Examen_Final_ID AS Examen_Final_ID,
        alumno.Alumno_Legajo AS Alumno_Legajo
    FROM [GD2C2025].[gd_esquema].[Maestra] maestra
        INNER JOIN [NORMALIZADOS].[Examen_Final] examen ON examen.Curso_Codigo = maestra.Curso_Codigo
        INNER JOIN [NORMALIZADOS].[Alumno] alumno ON alumno.Alumno_Legajo = maestra.Alumno_Legajo
    WHERE Inscripcion_Final_Fecha IS NOT NULL
END
GO

-- FACTURA
CREATE PROCEDURE [NORMALIZADOS].sp_migrar_factura AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Factura] (Factura_Numero, Factura_FechaEmision, Factura_FechaVencimiento, Factura_Total, Alumno_Legajo)
    SELECT DISTINCT 
        Factura_Numero,
        Factura_FechaEmision,
        Factura_FechaVencimiento,
        Factura_Total,
        alumno.Alumno_Legajo AS Alumno_Legajo
    FROM [GD2C2025].[gd_esquema].[Maestra] maestra
        INNER JOIN [NORMALIZADOS].[Alumno] alumno ON alumno.Alumno_Legajo = maestra.Alumno_Legajo
    WHERE Factura_Numero IS NOT NULL
END
GO

-- DETALLE FACTURA
CREATE PROCEDURE [NORMALIZADOS].sp_migrar_detalle_factura AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Detalle_Factura] (Curso_Codigo, Periodo_Año, Periodo_Mes, Detalle_Factura_Importe, Factura_Numero)
    SELECT DISTINCT 
        curso.Curso_Codigo AS Curso_Codigo,
        Periodo_Anio,
        Periodo_Mes,
        Detalle_Factura_Importe,
        factura.Factura_Numero AS Factura_Numero
    FROM [GD2C2025].[gd_esquema].[Maestra] maestra
        INNER JOIN [NORMALIZADOS].[Curso] curso ON curso.Curso_Codigo = maestra.Curso_Codigo
        INNER JOIN [NORMALIZADOS].[Factura] factura ON factura.Factura_Numero = maestra.Factura_Numero
    WHERE Detalle_Factura_Importe IS NOT NULL
END
GO

-- PAGO
CREATE PROCEDURE [NORMALIZADOS].sp_migrar_pago AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Pago] (Pago_Fecha, Pago_Importe, Pago_MedioPago, Factura_Numero)
    SELECT DISTINCT 
        Pago_Fecha,
        Pago_Importe,
        Pago_MedioPago,
        factura.Factura_Numero AS Factura_Numero
    FROM [GD2C2025].[gd_esquema].[Maestra] maestra
        INNER JOIN [NORMALIZADOS].[Factura] factura ON factura.Factura_Numero = maestra.Factura_Numero
    WHERE Pago_Importe IS NOT NULL
END
GO


CREATE PROCEDURE [NORMALIZADOS].sp_migrar_encuesta AS
BEGIN
    -- Truco: Insertamos las encuestas asegurando orden para que coincidan con el detalle despues
    -- O mejor aun, definimos que una Encuesta es unica por fila de la maestra.
    -- Como no tenemos ID, vamos a confiar en que el orden de insercion se mantiene o usaremos un cursor.
    
    -- PERO, la forma mas ROBUSTA en SQL para TPs es esta:
    -- 1. Insertamos en Encuesta mirando la Maestra.
    -- 2. En el detalle, como no podemos volver a linkear facil (es anonima), 
    --    necesitamos haber guardado una referencia.
    
    -- SOLUCION SIMPLIFICADA: Vamos a cambiar la estrategia de inserción.
    -- Paso 1: Crear una tabla temporal con ID autogenerado y los datos de la maestra
    CREATE TABLE #EncuestasTemp (
        Temp_ID BIGINT IDENTITY(1,1),
        Curso_Codigo BIGINT,
        Fecha DATETIME2(6),
        Obs VARCHAR(255),
        Preg1 VARCHAR(255), Nota1 INT,
        Preg2 VARCHAR(255), Nota2 INT,
        Preg3 VARCHAR(255), Nota3 INT,
        Preg4 VARCHAR(255), Nota4 INT
    );

    -- Insertamos TODAS las encuestas (sin distinct de fecha/curso, una por fila)
    INSERT INTO #EncuestasTemp (Curso_Codigo, Fecha, Obs, Preg1, Nota1, Preg2, Nota2, Preg3, Nota3, Preg4, Nota4)
    SELECT 
        Curso_Codigo, 
        Encuesta_FechaRegistro, 
        Encuesta_Observacion,
        Encuesta_Pregunta1, Encuesta_Nota1,
        Encuesta_Pregunta2, Encuesta_Nota2,
        Encuesta_Pregunta3, Encuesta_Nota3,
        Encuesta_Pregunta4, Encuesta_Nota4
    FROM [GD2C2025].[gd_esquema].[Maestra]
    WHERE Encuesta_FechaRegistro IS NOT NULL 
      AND Encuesta_Nota1 IS NOT NULL; -- Aseguramos que sea una fila de encuesta valida

    -- Paso 2: Migrar a la tabla ENCUESTA oficial usando IDENTITY_INSERT para mantener los IDs generados
    SET IDENTITY_INSERT [NORMALIZADOS].[Encuesta] ON;

    INSERT INTO [NORMALIZADOS].[Encuesta] (Encuesta_ID, Curso_Codigo, Encuesta_FechaRegistro, Encuesta_Observacion)
    SELECT Temp_ID, Curso_Codigo, Fecha, Obs
    FROM #EncuestasTemp;

    SET IDENTITY_INSERT [NORMALIZADOS].[Encuesta] OFF;

    -- Paso 3: Migrar los DETALLES "despivoteando" las columnas (Preg1, Preg2..) a filas
    -- Pregunta 1
    INSERT INTO [NORMALIZADOS].[Detalle_Encuesta] (Encuesta_ID, Encuesta_Pregunta, Encuesta_Nota)
    SELECT Temp_ID, Preg1, Nota1 FROM #EncuestasTemp WHERE Preg1 IS NOT NULL;

    -- Pregunta 2
    INSERT INTO [NORMALIZADOS].[Detalle_Encuesta] (Encuesta_ID, Encuesta_Pregunta, Encuesta_Nota)
    SELECT Temp_ID, Preg2, Nota2 FROM #EncuestasTemp WHERE Preg2 IS NOT NULL;

    -- Pregunta 3
    INSERT INTO [NORMALIZADOS].[Detalle_Encuesta] (Encuesta_ID, Encuesta_Pregunta, Encuesta_Nota)
    SELECT Temp_ID, Preg3, Nota3 FROM #EncuestasTemp WHERE Preg3 IS NOT NULL;

    -- Pregunta 4
    INSERT INTO [NORMALIZADOS].[Detalle_Encuesta] (Encuesta_ID, Encuesta_Pregunta, Encuesta_Nota)
    SELECT Temp_ID, Preg4, Nota4 FROM #EncuestasTemp WHERE Preg4 IS NOT NULL;

    -- Limpieza
    DROP TABLE #EncuestasTemp;
END
GO

EXEC [NORMALIZADOS].sp_migrar_localidades_provincias;
EXEC [NORMALIZADOS].sp_migrar_institucion;
EXEC [NORMALIZADOS].sp_migrar_sede;
EXEC [NORMALIZADOS].sp_migrar_alumno;
EXEC [NORMALIZADOS].sp_migrar_profesor;
EXEC [NORMALIZADOS].sp_migrar_categorias;
EXEC [NORMALIZADOS].sp_migrar_cursos;
EXEC [NORMALIZADOS].sp_migrar_inscripcion;
EXEC [NORMALIZADOS].sp_migrar_modulo;
EXEC [NORMALIZADOS].sp_migrar_modulo_x_curso;
EXEC [NORMALIZADOS].sp_migrar_evaluacion_curso;
EXEC [NORMALIZADOS].sp_migrar_evaluacion_x_alumno;
EXEC [NORMALIZADOS].sp_migrar_trabajo_practico;
EXEC [NORMALIZADOS].sp_migrar_examen_final;
EXEC [NORMALIZADOS].sp_migrar_evaluacion_final;
EXEC [NORMALIZADOS].sp_migrar_inscripcion_final;
EXEC [NORMALIZADOS].sp_migrar_factura;
EXEC [NORMALIZADOS].sp_migrar_detalle_factura;
EXEC [NORMALIZADOS].sp_migrar_pago;
EXEC [NORMALIZADOS].sp_migrar_encuesta;