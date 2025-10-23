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
    id_institucion BIGINT PRIMARY KEY,
    Institucion_Nombre NVARCHAR(255) NOT NULL,
    Institucion_RazonSocial NVARCHAR(255) NOT NULL,
    Institucion_Cuit NVARCHAR(255) UNIQUE
);
GO

-- Tabla Sede
CREATE TABLE [NORMALIZADOS].[Sede] (
    id_sede BIGINT PRIMARY KEY,
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
        CHECK (Curso_Turno IN ('mañana','tarde','noche')),
    Curso_FechaInicio DATETIME2(6) NOT NULL,
    Curso_FechaFin DATETIME2(6) NOT NULL,
    Curso_DuracionMeses BIGINT NOT NULL,  -- opcionalmente calculable
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
        CHECK (dia IN ('Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'))
);
GO

-- Tabla intermedia Curso_Dia
CREATE TABLE [NORMALIZADOS].[Curso_Dia] (
    id_dia_semana SMALLINT FOREIGN KEY REFERENCES [NORMALIZADOS].[DiaSemana](id) ,
    id_curso BIGINT FOREIGN KEY REFERENCES [NORMALIZADOS].[Curso](Curso_Codigo),
    PRIMARY KEY (id_dia_semana, id_curso)
);
GO

CREATE PROCEDURE sp_migrar_localidades AS
BEGIN
    INSERT INTO [NORMALIZADOS].[Provincia] (provincia_nombre)
        SELECT Sede_Provincia FROM [GD2C2025].[gd_esquema].[Maestra]
        UNION
        SELECT Profesor_Provincia FROM [GD2C2025].[gd_esquema].[Maestra]
        UNION
        SELECT Alumno_Provincia FROM [GD2C2025].[gd_esquema].[Maestra]
    INSERT INTO [NORMALIZADOS].[Localidad] (localidad_nombre, id_provincia)
        SELECT m.Alumno_Localidad, m.Profesor_Localidad, m.Sede_Localidad
        FROM [NORMALIZADOS].[Provincia] p
            JOIN [GD2C2025].[gd_esquema].[Maestra] m 
            ON p.provincia_nombre = m.Alumno_Provincia OR p.provincia_nombre = m.Profesor_Provincia OR p.provincia_nombre = m.Sede_Localidad
END
GO