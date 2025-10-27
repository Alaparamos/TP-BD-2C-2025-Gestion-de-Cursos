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
    Sede_Telefono NVARCHAR(255),
    Sede_Mail NVARCHAR(255),
    id_institucion BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Institucion](id_institucion)
);
GO

CREATE TABLE [NORMALIZADOS].[Alumno] (
	legajo BIGINT PRIMARY KEY,
    Alumno_DNI BIGINT,
    Alumno_Nombre VARCHAR(255),
    Alumno_Apellido VARCHAR(255),
    Alumno_FechaNacimiento DATETIME2(6),
    Alumno_Direccion VARCHAR(255),
    Alumno_Telefono VARCHAR(255),
    Alumno_Mail VARCHAR(255) UNIQUE,
    id_localidad BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Localidad](id_Localidad)
);
GO

-- Tabla Profesor
CREATE TABLE [NORMALIZADOS].[Profesor] (
    Profesor_id NVARCHAR(255) PRIMARY KEY,
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

CREATE TABLE [NORMALIZADOS].[Inscripcion] (
    Inscripcion_Numero BIGINT PRIMARY KEY,
    Inscripcion_Fecha DATETIME2(6) NOT NULL,
    Inscripcion_Estado VARCHAR(255) 
        CHECK(Inscripcion_Estado IN ('pendiente','aprobado', 'rechazada')),
    Inscripcion_FechaRespuesta DATETIME2(6),
    id_alumno BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Alumno](legajo)
);
GO

-- Tabla Categoria
CREATE TABLE [NORMALIZADOS].[Categoria] (
    id_categoria BIGINT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL
);
GO

-- Tabla Curso
CREATE TABLE [NORMALIZADOS].[Curso] (
    Curso_Codigo BIGINT PRIMARY KEY,
    Curso_Nombre VARCHAR(255) NOT NULL,
    Curso_Descripcion VARCHAR(255),
    Curso_Turno VARCHAR(255) 
        CHECK (Curso_Turno IN ('maniana','tarde','noche')),
    Curso_FechaInicio DATETIME2(6) NOT NULL,
    Curso_FechaFin DATETIME2(6) NOT NULL,
    Curso_DuracionMeses BIGINT NOT NULL,  -- opcionalmente calculable -> VER DE ELIMINARLO
    Curso_PrecioMensual DECIMAL(38,2) NOT NULL,
    id_categoria BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Categoria](id_categoria),
    id_sede BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Sede](id_sede),
    id_profesor NVARCHAR(255) FOREIGN KEY REFERENCES [NORMALIZADOS].[Profesor](Profesor_id)
);
GO

CREATE INDEX IX_Curso_Profesor ON [NORMALIZADOS].Curso(id_profesor);
CREATE INDEX IX_Curso_Sede ON [NORMALIZADOS].Curso(id_sede);
GO

-- Tabla DiaSemana
CREATE TABLE [NORMALIZADOS].[DiaSemana] (
    id SMALLINT PRIMARY KEY,
    dia VARCHAR(255) 
        CHECK (dia IN ('Lunes','Martes','Miercoles','Jueves','Viernes','Sabado','Domingo'))
);
GO

-- Tabla intermedia Curso_Dia
CREATE TABLE [NORMALIZADOS].[Curso_Dia] (
    id_dia_semana SMALLINT FOREIGN KEY REFERENCES [NORMALIZADOS].[DiaSemana](id) ,
    id_curso BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Curso](Curso_Codigo),
    PRIMARY KEY (id_dia_semana, id_curso)
);
GO

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
    INSERT INTO [NORMALIZADOS].[Sede] (Sede_Nombre, id_localidad, Sede_Telefono, Sede_Mail, id_institucion)
    SELECT DISTINCT Sede_Nombre, localidad.id_localidad AS id_localidad, Sede_Telefono, Sede_Mail, institucion.id_institucion as id_institucion
    FROM [GD2C2025].[gd_esquema].[Maestra] maestra
        INNER JOIN [NORMALIZADOS].[Localidad] localidad ON localidad.localidad_nombre = maestra.Sede_Localidad
        INNER JOIN [NORMALIZADOS].[Institucion] institucion ON institucion.Institucion_Nombre = maestra.Institucion_Nombre
    WHERE Sede_Nombre IS NOT NULL
END
GO

-- Primero eliminar índices creados manualmente
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

-- Finalmente, eliminar el schema
DROP SCHEMA IF EXISTS [NORMALIZADOS];
GO

EXECUTE [NORMALIZADOS].sp_migrar_localidades
EXECUTE [NORMALIZADOS].sp_migrar_institucion
EXECUTE [NORMALIZADOS].sp_migrar_sede