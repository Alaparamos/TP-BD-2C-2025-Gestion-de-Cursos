USE [GD2C2025]
GO

CREATE SCHEMA NORMALIZADOS;
GO

-- Tabla Provincia
CREATE TABLE [NORMALIZADOS].[Provincia] (
    id_provincia BIGINT IDENTITY(1,1) PRIMARY KEY,
    provincia_nombre NVARCHAR(255) NOT NULL
);
GO

-- Tabla Localidad
CREATE TABLE [NORMALIZADOS].[Localidad] (
    id_Localidad BIGINT IDENTITY(1,1) PRIMARY KEY,
    localidad_nombre NVARCHAR(255) NOT NULL,
    id_provincia BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Provincia](id_provincia)
);
GO

-- Tabla Institucion
CREATE TABLE [NORMALIZADOS].[Institucion] (
    id_institucion BIGINT IDENTITY(1,1) PRIMARY KEY,
    Institucion_Nombre NVARCHAR(255) NOT NULL,
    Institucion_RazonSocial NVARCHAR(255) NOT NULL,
    Institucion_Cuit NVARCHAR(255) UNIQUE
);
GO

-- Tabla Sede
CREATE TABLE [NORMALIZADOS].[Sede] (
    id_sede BIGINT IDENTITY(1,1) PRIMARY KEY,
    Sede_Nombre NVARCHAR(255) NOT NULL,
    id_localidad BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Localidad](id_localidad),
    Sede_Direccion NVARCHAR(255),
    Sede_Telefono NVARCHAR(255),
    Sede_Mail NVARCHAR(255),
    id_institucion BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Institucion](id_institucion)
);
GO

-- Tabla Alumno
CREATE TABLE [NORMALIZADOS].[Alumno] (
	legajo BIGINT PRIMARY KEY,
    Alumno_DNI BIGINT,
    Alumno_Nombre VARCHAR(255),
    Alumno_Apellido VARCHAR(255),
    Alumno_FechaNacimiento DATETIME2(6),
    Alumno_Direccion VARCHAR(255),
    Alumno_Telefono VARCHAR(255),
    --Alumno_Mail VARCHAR(255) UNIQUE,
    Alumno_Mail VARCHAR(255),
    id_localidad BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Localidad](id_Localidad)
);
GO

-- Tabla Profesor
CREATE TABLE [NORMALIZADOS].[Profesor] (
    Profesor_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    Profesor_Nombre NVARCHAR(255) NOT NULL,
    Profesor_Apellido NVARCHAR(255) NOT NULL,
    Profesor_Dni NVARCHAR(255) NOT NULL,
    Profesor_FechaNacimiento DATETIME2(6) NOT NULL,
    Profesor_Direccion NVARCHAR(255),
    Profesor_Telefono NVARCHAR(255),
    Profesor_Mail NVARCHAR(255),
    id_localidad BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Localidad](id_localidad)
);
GO

-- Tabla Categoria
CREATE TABLE [NORMALIZADOS].[Categoria] (
    id_categoria BIGINT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL
);
GO

-- Tabla Curso
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
    id_categoria BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Categoria](id_categoria),
    id_sede BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Sede](id_sede),
    id_profesor BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Profesor](Profesor_id)
);
GO

CREATE INDEX IX_Curso_Profesor ON [NORMALIZADOS].Curso(id_profesor);
CREATE INDEX IX_Curso_Sede ON [NORMALIZADOS].Curso(id_sede);
GO

-- Tabla Inscripción
CREATE TABLE [NORMALIZADOS].[Inscripcion] (
    Inscripcion_Numero BIGINT PRIMARY KEY,
    Inscripcion_Fecha DATETIME2(6) NOT NULL,
    Inscripcion_Estado VARCHAR(255) 
        CHECK(Inscripcion_Estado IN ('Pendiente','Confirmada', 'Rechazada')),
    Inscripcion_FechaRespuesta DATETIME2(6),
    id_alumno BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Alumno](legajo),
    id_curso BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Curso](Curso_Codigo)
);
GO

-- Tabla intermedia Modulo_x_Curso
CREATE TABLE [NORMALIZADOS].[Modulo_x_Curso] (
    id_modulo BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Modulo](id_modulo),
    id_curso BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Curso](Curso_Codigo),
    PRIMARY KEY (id_modulo, id_curso)
);
GO

-- Tabla modulo
CREATE TABLE [NORMALIZADOS].[Modulo] (
    id_modulo BIGINT IDENTITY(1,1) PRIMARY KEY,
    Modulo_Nombre VARCHAR(255) NOT NULL,
    Modulo_Descripcion VARCHAR(255)
);
GO

create table [NORMALIZADOS].[Evaluacion_Curso](
    id_evaluacion BIGINT IDENTITY(1,1) PRIMARY KEY,
    Evaluacion_Fecha DATETIME2(6) NOT NULL,
    id_curso BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Curso](Curso_Codigo)
);
GO

--tabla intermedia Evaluacion aluno
CREATE TABLE [NORMALIZADOS].[Evaluacion_x_Alumno] (
    id_evaluacion BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Evaluacion_Curso](id_evaluacion),
    id_alumno BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Alumno](legajo),
    Evaluacion_Nota DECIMAL(5,2),
    Evaluacion_Presente BIT,
    Evaluacion_Instancia: bigint
    PRIMARY KEY (id_evaluacion, id_alumno)
);
GO

CREATE TABLE [NORMALIZADOS].[Trabajo_Practico] (
    id_trabajo BIGINT IDENTITY(1,1) PRIMARY KEY,
    Trabajo_Practico_Nota DECIMAL(5,2),
    Trabajo_Practico_Fecha DATETIME2(6) NOT NULL,
    id_curso BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Curso](Curso_Codigo)
);
GO

create table [NORMALIZADOS].[Examen_Final](
    id_examen_final BIGINT IDENTITY(1,1) PRIMARY KEY,
    Examen_Final_Hora VARCHAR(255),
    Examen_Final_Fecha DATETIME2(6),
    Examen_Final_Descripcion VARCHAR(255),
    id_curso BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Curso](Curso_Codigo)
);
GO

CREATE TABLE [NORMALIZADOS].[Evaluacion_Final] (
    id_evaluacion_final BIGINT IDENTITY(1,1) PRIMARY KEY,
    Evaluacion_Final_Nota DECIMAL(5,2),
    Evaluacion_Final_Presente BIT,
    id_examen_final BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Examen_Final](id_examen_final),
    id_alumno BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Alumno](legajo)
    id_profesor BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Profesor](Profesor_id)
);
GO

CREATE TABLE [NORMALIZADOS].[Inscripcion_Final] (
    id_inscripcion_examen_final BIGINT IDENTITY(1,1) PRIMARY KEY,
    Inscripcion_ExamenFinal_Fecha DATETIME2(6) NOT NULL,
    id_examen_final BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Examen_Final](id_examen_final),
    id_alumno BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Alumno](legajo)
);
GO

CREATE TABLE [NORMALIZADOS].[Factura] (
    Factura_Numero BIGINT PRIMARY KEY,
    Factura_FechaEmision DATETIME2(6) NOT NULL,
    Factura_FechaVencimiento DATETIME2(6) NOT NULL,
    Factura_Total DECIMAL(18,2) NOT NULL,
    id_alumno BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Alumno](legajo)
);
GO

CREATE TABLE [NORMALIZADOS].[Detalle_Factura] (
    id_detalle BIGINT IDENTITY(1,1) PRIMARY KEY,
    curso_codigo BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Curso](Curso_Codigo),
    Periodo_Año bigint,
    Periodo_Mes bigint,
    Detalle_Factura_Importe bigint,
    id_factura BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Factura](Factura_Numero)
);
GO


CREATE TABLE [NORMALIZADOS].[Pago] (
    Pago_Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    Pago_Fecha DATETIME2(6) NOT NULL,
    Pago_Importe DECIMAL(18,2) NOT NULL,
    Pago_MedioPago VARCHAR(255),
    id_factura BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Factura](Factura_Numero)
);

-- Tabla principal: Encuesta
CREATE TABLE [NORMALIZADOS].[Encuesta] (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_curso BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Curso](Curso_Codigo),
    Encuesta_FechaRegistro DATETIME2(6) NOT NULL,
    Encuesta_Observacion VARCHAR(255)
);
GO

-- Tabla detalle: Detalle
CREATE TABLE [NORMALIZADOS].[Detalle_Encuesta] (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_encuesta BIGINT NOT NULL FOREIGN KEY REFERENCES [NORMALIZADOS].[Encuesta](id),
    Encuesta_Pregunta VARCHAR(255) NOT NULL,
    Encuesta_Nota BIGINT NOT NULL
        CHECK (Encuesta_Nota BETWEEN 1 AND 10)
);
GO



-- Tabla DiaSemana
/*
CREATE TABLE [NORMALIZADOS].[DiaSemana] (
    id SMALLINT PRIMARY KEY,
    dia VARCHAR(255) 
        CHECK (dia IN ('Lunes','Martes','Miercoles','Jueves','Viernes','Sabado','Domingo'))
);
GO
*/

-- -- Tabla intermedia Curso_Dia
-- CREATE TABLE [NORMALIZADOS].[Curso_Dia] (
--     id_dia_semana SMALLINT FOREIGN KEY REFERENCES [NORMALIZADOS].[DiaSemana](id) ,
--     id_curso BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Curso](Curso_Codigo),
--     PRIMARY KEY (id_dia_semana, id_curso)
-- );
-- GO

/*
TABLAS QUE FALTAN:


*/


-- Procedimientos almacenados para migrar datos desde la tabla Maestra al esquema NORMALIZADOS

CREATE PROCEDURE [NORMALIZADOS].sp_migrar_localidades AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Provincia] (provincia_nombre)
        -- Institucion tiene cambiado Sede_Localidad por Sede_Provincia
        SELECT Sede_Localidad FROM [GD2C2025].[gd_esquema].[Maestra]
        WHERE Sede_Localidad is NOT NULL
        UNION
        SELECT Profesor_Provincia FROM [GD2C2025].[gd_esquema].[Maestra]
        WHERE Profesor_Provincia is NOT NULL
        UNION
        SELECT Alumno_Provincia FROM [GD2C2025].[gd_esquema].[Maestra]
        WHERE Alumno_Provincia is NOT NULL
    INSERT INTO [NORMALIZADOS].[Localidad] (localidad_nombre, id_provincia)
        SELECT localidades.localidad_nombre, p.id_provincia
        FROM (
            SELECT Sede_Localidad as provincia_nombre, Sede_Provincia as localidad_nombre
            FROM [GD2C2025].[gd_esquema].[Maestra]
            WHERE Sede_Localidad is NOT NULL AND Sede_Provincia IS NOT NULL
            UNION
            SELECT Profesor_Provincia as provincia_nombre, Profesor_Localidad as localidad_nombre
            FROM [GD2C2025].[gd_esquema].[Maestra]
            WHERE Profesor_Provincia is NOT NULL AND Profesor_Localidad IS NOT NULL
            UNION
            SELECT Alumno_Provincia as provincia_nombre, Alumno_Localidad as localidad_nombre
            FROM [GD2C2025].[gd_esquema].[Maestra]
            WHERE Alumno_Provincia is NOT NULL AND Alumno_Localidad IS NOT NULL
        ) as localidades
        INNER JOIN [NORMALIZADOS].[Provincia] p
        ON localidades.provincia_nombre = p.provincia_nombre
END
GO

CREATE PROCEDURE [NORMALIZADOS].sp_migrar_institucion AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Institucion] 
    SELECT DISTINCT Institucion_Nombre, Institucion_RazonSocial, Institucion_Cuit FROM [GD2C2025].[gd_esquema].[Maestra]
    WHERE Institucion_Nombre IS NOT NULL AND Institucion_RazonSocial IS NOT NULL
END
GO

CREATE PROCEDURE [NORMALIZADOS].sp_migrar_sede AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Sede] (Sede_Nombre, id_localidad, Sede_Telefono, Sede_Mail, Sede_Direccion, id_institucion)
    SELECT DISTINCT Sede_Nombre, localidad.id_localidad AS id_localidad, Sede_Telefono, Sede_Mail, Sede_Direccion, institucion.id_institucion as id_institucion
    FROM [GD2C2025].[gd_esquema].[Maestra] maestra
        INNER JOIN [NORMALIZADOS].[Localidad] localidad ON localidad.localidad_nombre = maestra.Sede_Provincia
        INNER JOIN [NORMALIZADOS].[Provincia] provincia on provincia.provincia_nombre = maestra.Sede_Localidad and localidad.id_provincia = provincia.id_provincia
        INNER JOIN [NORMALIZADOS].[Institucion] institucion ON institucion.Institucion_Cuit = maestra.Institucion_Cuit
    WHERE Sede_Nombre IS NOT NULL
END
GO

CREATE PROCEDURE [NORMALIZADOS].sp_migrar_profesor AS
BEGIN 
    INSERT INTO [NORMALIZADOS].[Profesor] (Profesor_Nombre, Profesor_Apellido, Profesor_Dni, Profesor_FechaNacimiento,Profesor_Direccion,
    Profesor_Telefono,Profesor_Mail, id_localidad)
    SELECT DISTINCT Profesor_Nombre, Profesor_Apellido, Profesor_Dni, Profesor_FechaNacimiento,Profesor_Direccion,
    Profesor_Telefono,Profesor_Mail, localidad.id_localidad as id_localidad
    from [GD2C2025].[gd_esquema].[Maestra] maestra
        INNER JOIN [NORMALIZADOS].[Localidad] localidad ON localidad.localidad_nombre = maestra.Sede_Localidad 
    Where Profesor_Nombre is not null
END
GO

CREATE PROCEDURE [NORMALIZADOS].sp_migrar_alumno AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Alumno](legajo, Alumno_DNI, Alumno_Nombre, Alumno_Apellido, Alumno_FechaNacimiento, Alumno_Direccion, Alumno_Telefono, Alumno_Mail, id_localidad)
    SELECT DISTINCT 
        Alumno_Legajo,
        Alumno_DNI,
        Alumno_Nombre,
        Alumno_Apellido,
        Alumno_FechaNacimiento,
        Alumno_Direccion,
        Alumno_Telefono,
        Alumno_Mail,
        localidad.id_localidad AS id_localidad
    FROM [GD2C2025].[gd_esquema].[Maestra] maestra
        INNER JOIN [NORMALIZADOS].[Localidad] localidad ON localidad.localidad_nombre = maestra.Alumno_Localidad
        INNER JOIN [NORMALIZADOS].[Provincia] provincia on provincia.provincia_nombre = maestra.Alumno_Provincia and localidad.id_provincia = provincia.id_provincia
    WHERE Alumno_Legajo IS NOT NULL
END
GO

CREATE PROCEDURE [NORMALIZADOS].sp_migrar_inscripcion AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Inscripcion](Inscripcion_Numero, Inscripcion_Fecha, Inscripcion_Estado, Inscripcion_FechaRespuesta, id_alumno, id_curso)
    SELECT DISTINCT 
        Inscripcion_Numero,
        Inscripcion_Fecha,
        Inscripcion_Estado,
        Inscripcion_FechaRespuesta,
        alumno.legajo AS id_alumno,
        curso.Curso_Codigo AS id_curso
    FROM [GD2C2025].[gd_esquema].[Maestra] maestra
        INNER JOIN [NORMALIZADOS].[Curso] curso ON curso.Curso_Codigo = maestra.Curso_Codigo
        INNER JOIN [NORMALIZADOS].[Alumno] alumno ON alumno.legajo = maestra.Alumno_Legajo
    WHERE Inscripcion_Numero IS NOT NULL
END
GO

CREATE PROCEDURE [NORMALIZADOS].sp_migrar_categorias AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Categoria] (nombre)
    SELECT DISTINCT Curso_Categoria AS nombre FROM [GD2C2025].[gd_esquema].[Maestra]
    WHERE Curso_Categoria IS NOT NULL
    ORDER BY Curso_Categoria ASC
END
GO



--script para migrar datos de la tabla Curso
CREATE PROCEDURE [NORMALIZADOS].sp_migrar_cursos AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Curso] (Curso_Codigo, Curso_Nombre, Curso_Descripcion, Curso_Turno, Curso_Dia, Curso_FechaInicio, Curso_FechaFin,
    Curso_DuracionMeses, Curso_PrecioMensual, id_categoria, id_sede, id_profesor)
    SELECT DISTINCT 
        Curso_Codigo,
        Curso_Nombre,
        Curso_Descripcion,
        Curso_Turno, -- se agrega también el turno
        Curso_Dia, --se interpreta que4 se cursa una vez por semana (segun tabla maestra)
        Curso_FechaInicio,
        Curso_FechaFin,
        Curso_DuracionMeses,
        Curso_PrecioMensual,
        categoria.id_categoria AS id_categoria,
        sede.id_sede AS id_sede,
        profesor.Profesor_id AS id_profesor
    FROM [GD2C2025].[gd_esquema].[Maestra] maestra
        INNER JOIN [NORMALIZADOS].[Categoria] categoria ON categoria.nombre = maestra.Curso_Categoria
        INNER JOIN [NORMALIZADOS].[Sede] sede ON sede.Sede_Nombre = maestra.Sede_Nombre
        INNER JOIN [NORMALIZADOS].[Profesor] profesor ON profesor.Profesor_Dni = maestra.Profesor_Dni
    WHERE Curso_Codigo IS NOT NULL
END
GO

-- create procedure sp_migrar_dias_semana as
-- BEGIN
--     INSERT INTO [NORMALIZADOS].[DiaSemana] (dia)
--     VALUES 
--         ('Lunes'),
--         ('Martes'),
--         ('Miercoles'),
--         ('Jueves'),
--         ('Viernes'),
--         ('Sabado'),
--         ('Domingo')
-- END
-- GO

-- CREATE PROCEDURE sp_migrar_curso_dia AS
--     INSERT INTO [NORMALIZADOS].[Curso_Dia] (id_dia_semana, id_curso)
--     SELECT 
--         ds.id AS id_dia_semana,
--         c.Curso_Codigo AS id_curso
--     FROM [GD2C2025].[gd_esquema].[Maestra] maestra
--     INNER JOIN [NORMALIZADOS].[Curso] c ON c.Curso_Codigo = maestra.Curso_Codigo
--     INNER JOIN [NORMALIZADOS].[DiaSemana] ds ON ds.dia = maestra.Curso_Dia
-- BEGIN
-- END
-- GO

-- Eliminar el schema NORMALIZADOS y todo su contenido  --------------------------------------

-- Primero eliminar �ndices creados manualmente
DROP INDEX IF EXISTS IX_Curso_Profesor ON [NORMALIZADOS].[Curso];
DROP INDEX IF EXISTS IX_Curso_Sede ON [NORMALIZADOS].[Curso];
GO

-- Tablas sin dependencias externas o que dependen de otras
DROP TABLE IF EXISTS [NORMALIZADOS].[Curso_Dia];
DROP TABLE IF EXISTS [NORMALIZADOS].[Curso];
DROP TABLE IF EXISTS [NORMALIZADOS].[DiaSemana];
DROP TABLE IF EXISTS [NORMALIZADOS].[Inscripcion];
DROP TABLE IF EXISTS [NORMALIZADOS].[Profesor];
DROP TABLE IF EXISTS [NORMALIZADOS].[Alumno];
DROP TABLE IF EXISTS [NORMALIZADOS].[Sede];
DROP TABLE IF EXISTS [NORMALIZADOS].[Categoria];
DROP TABLE IF EXISTS [NORMALIZADOS].[Institucion];
DROP TABLE IF EXISTS [NORMALIZADOS].[Localidad];
DROP TABLE IF EXISTS [NORMALIZADOS].[Provincia];
GO

DROP PROCEDURE 
    [NORMALIZADOS].[sp_migrar_localidades],
    [NORMALIZADOS].[sp_migrar_institucion],
    [NORMALIZADOS].[sp_migrar_sede],
    [NORMALIZADOS].[sp_migrar_alumno],
    [NORMALIZADOS].[sp_migrar_profesor],
    [NORMALIZADOS].[sp_migrar_inscripcion],
    [NORMALIZADOS].[sp_migrar_categorias],
    [NORMALIZADOS].[sp_migrar_cursos];
GO

-- Finalmente, eliminar el schema
DROP SCHEMA IF EXISTS [NORMALIZADOS];
GO

EXECUTE [NORMALIZADOS].sp_migrar_localidades
EXECUTE [NORMALIZADOS].sp_migrar_institucion
EXECUTE [NORMALIZADOS].sp_migrar_sede
EXECUTE [NORMALIZADOS].sp_migrar_alumno
EXECUTE [NORMALIZADOS].sp_migrar_profesor
EXECUTE [NORMALIZADOS].sp_migrar_inscripcion
EXECUTE [NORMALIZADOS].sp_migrar_categorias
EXECUTE [NORMALIZADOS].sp_migrar_cursos