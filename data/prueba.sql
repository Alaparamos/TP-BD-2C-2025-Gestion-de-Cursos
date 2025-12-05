--SELECT * FROM [NORMALIZADOS].[Provincia];
--SELECT * FROM [NORMALIZADOS].[Localidad]
--ORDER BY Id_Provincia;
--SELECT * FROM [NORMALIZADOS].[Institucion];
--SELECT * FROM [NORMALIZADOS].[Sede];
--SELECT * FROM [NORMALIZADOS].[Alumno];
--SELECT * FROM [NORMALIZADOS].[Profesor];
--SELECT * FROM [NORMALIZADOS].[Categoria];
--SELECT * FROM [NORMALIZADOS].[Curso];
--SELECT * FROM [NORMALIZADOS].[Inscripcion];
--SELECT * FROM [NORMALIZADOS].[Modulo];
--SELECT * FROM [NORMALIZADOS].[Modulo_x_Curso];
--SELECT * FROM [NORMALIZADOS].[Evaluacion_Curso];
--SELECT * FROM [NORMALIZADOS].[Evaluacion_x_Alumno];
--SELECT * FROM [NORMALIZADOS].[Trabajo_Practico];
--SELECT * FROM [NORMALIZADOS].[Examen_Final];
--SELECT * FROM [NORMALIZADOS].[Evaluacion_Final];
--SELECT * FROM [NORMALIZADOS].[Inscripcion_Final];
--SELECT * FROM [NORMALIZADOS].[Factura];
--SELECT * FROM [NORMALIZADOS].[Detalle_Factura];
--SELECT * FROM [NORMALIZADOS].[Pago];
--SELECT * FROM [NORMALIZADOS].[Encuesta];
--SELECT * FROM [NORMALIZADOS].[Detalle_Encuesta]
--ORDER BY Encuesta_ID;
--GO

SELECT 'Provincia' AS Tabla, COUNT(*) AS Cantidad FROM [NORMALIZADOS].[Provincia]
UNION ALL
SELECT 'Localidad', COUNT(*) FROM [NORMALIZADOS].[Localidad]
UNION ALL
SELECT 'Institucion', COUNT(*) FROM [NORMALIZADOS].[Institucion]
UNION ALL
SELECT 'Sede', COUNT(*) FROM [NORMALIZADOS].[Sede]
UNION ALL
SELECT 'Alumno', COUNT(*) FROM [NORMALIZADOS].[Alumno]
UNION ALL
SELECT 'Profesor', COUNT(*) FROM [NORMALIZADOS].[Profesor]
UNION ALL
SELECT 'Categoria', COUNT(*) FROM [NORMALIZADOS].[Categoria]
UNION ALL
SELECT 'Curso', COUNT(*) FROM [NORMALIZADOS].[Curso]
UNION ALL
SELECT 'Inscripcion', COUNT(*) FROM [NORMALIZADOS].[Inscripcion]
UNION ALL
SELECT 'Modulo', COUNT(*) FROM [NORMALIZADOS].[Modulo]
UNION ALL
SELECT 'Modulo_x_Curso', COUNT(*) FROM [NORMALIZADOS].[Modulo_x_Curso]
UNION ALL
SELECT 'Evaluacion_Curso', COUNT(*) FROM [NORMALIZADOS].[Evaluacion_Curso]
UNION ALL
SELECT 'Evaluacion_x_Alumno', COUNT(*) FROM [NORMALIZADOS].[Evaluacion_x_Alumno]
UNION ALL
SELECT 'Trabajo_Practico', COUNT(*) FROM [NORMALIZADOS].[Trabajo_Practico]
UNION ALL
SELECT 'Examen_Final', COUNT(*) FROM [NORMALIZADOS].[Examen_Final]
UNION ALL
SELECT 'Evaluacion_Final', COUNT(*) FROM [NORMALIZADOS].[Evaluacion_Final]
UNION ALL
SELECT 'Inscripcion_Final', COUNT(*) FROM [NORMALIZADOS].[Inscripcion_Final]
UNION ALL
SELECT 'Factura', COUNT(*) FROM [NORMALIZADOS].[Factura]
UNION ALL
SELECT 'Detalle_Factura', COUNT(*) FROM [NORMALIZADOS].[Detalle_Factura]
UNION ALL
SELECT 'Pago', COUNT(*) FROM [NORMALIZADOS].[Pago]
UNION ALL
SELECT 'Encuesta', COUNT(*) FROM [NORMALIZADOS].[Encuesta]
UNION ALL
SELECT 'Detalle_Encuesta', COUNT(*) FROM [NORMALIZADOS].[Detalle_Encuesta];



SELECT 
        dim_t.ANIO,
        sede.SEDE_NOMBRE,
        dim_cat.CURSO_CATEGORIA,
        SUM(cur.CANTIDAD_APROBADOS) AS TOTAL_APROBADOS,
        SUM(cur.CANTIDAD_DESAPROBADOS) AS TOTAL_DESAPROBADOS
    FROM (
        SELECT 
            Curso_Codigo,
            Evaluacion_Curso_fechaEvaluacion,
            SUM(es_aprobado) AS CANTIDAD_APROBADOS,
            SUM(CASE WHEN es_aprobado = 0 THEN 1 ELSE 0 END) AS CANTIDAD_DESAPROBADOS
        FROM (
            SELECT DISTINCT
                ec.Curso_Codigo,
                ec.Evaluacion_Curso_fechaEvaluacion,
                eva.Alumno_Legajo, -- TODO: Después sacarlo
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
                END AS es_aprobado
            FROM [NORMALIZADOS].[Evaluacion_x_Alumno] eva
                INNER JOIN [NORMALIZADOS].[Evaluacion_Curso] ec 
                ON eva.Evaluacion_Curso_ID = ec.Evaluacion_Curso_ID
        ) AS alumnos
        GROUP BY Curso_Codigo, Evaluacion_Curso_fechaEvaluacion
    ) cur
        INNER JOIN [NORMALIZADOS].[Curso] c ON c.Curso_Codigo = cur.Curso_Codigo
        INNER JOIN [NORMALIZADOS].[BI_DIM_CATEGORIA_CURSO] dim_cat ON dim_cat.ID = c.Categoria_ID
        INNER JOIN [NORMALIZADOS].[BI_DIM_SEDE] sede ON sede.SEDE_ID = c.Sede_ID
        -- JOIN AJUSTADO: Unimos por Año Y Mes para evitar duplicados
        INNER JOIN [NORMALIZADOS].[BI_DIM_TIEMPO] dim_t 
            ON dim_t.ANIO = YEAR(cur.Evaluacion_Curso_fechaEvaluacion)
            AND dim_t.MES = MONTH(cur.Evaluacion_Curso_fechaEvaluacion)
    GROUP BY 
        dim_t.ANIO,
        sede.SEDE_NOMBRE,
        dim_cat.CURSO_CATEGORIA

SELECT * FROM [NORMALIZADOS].[Examen_Final] ef
    INNER JOIN [NORMALIZADOS].[Curso] c ON c.Curso_Codigo = ef.Curso_Codigo
    INNER JOIN [NORMALIZADOS].[Categoria] cat ON c.Categoria_ID = cat.Categoria_ID
    INNER JOIN [NORMALIZADOS].[Evaluacion_Final] ev ON ef.Examen_Final_ID = ev.Examen_Final_ID
    INNER JOIN [NORMALIZADOS].[Alumno] a ON ev.Alumno_Legajo = a.Alumno_Legajo 
        AND '< 25' = [NORMALIZADOS].[fx_obtener_rango_etario](a.Alumno_FechaNacimiento)
    WHERE cat.Categoria_Descripcion = 'Categoria N°:3'
        AND YEAR(ef.Examen_Final_Fecha) = 2025 AND MONTH(ef.Examen_Final_Fecha) BETWEEN 7 AND 12

        SELECT * 
FROM [NORMALIZADOS].[Encuesta] enc
        INNER JOIN [NORMALIZADOS].[Detalle_Encuesta] de ON de.Encuesta_ID = enc.Encuesta_ID
        INNER JOIN [NORMALIZADOS].[Curso] c ON enc.Curso_Codigo = c.Curso_Codigo
        INNER JOIN [NORMALIZADOS].[Profesor] p ON p.Profesor_ID = c.Profesor_ID
WHERE c.Curso_Codigo = 32020 AND de.Encuesta_Nota BETWEEN 5 AND 6












SELECT
        t.TIEMPO_ID,
        sede.SEDE_ID,
        dim_eta.ID, 
        c.Curso_Codigo, 
        p.Profesor_ID, 
        COUNT(*) AS CANTIDAD_ENCUESTAS,
        CASE 
            WHEN de.Encuesta_Nota BETWEEN 7 AND 10 THEN 'Satisfechos'
            WHEN de.Encuesta_Nota BETWEEN 1 AND 4 THEN 'Insatisfechos'
            ELSE 'Neutrales'
        END AS Bloque_Satisfaccion
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
                END
    GROUP BY c.Curso_Codigo, p.Profesor_ID,
        t.TIEMPO_ID,
        sede.SEDE_ID,
        dim_eta.ID,
        dim_bloque.BLOQUE_ID;


SELECT * 
FROM [NORMALIZADOS].[Encuesta] enc
    INNER JOIN [NORMALIZADOS].[Detalle_Encuesta] de ON enc.Encuesta_ID = de.Encuesta_ID
    INNER JOIN [NORMALIZADOS].[Curso] cur ON enc.Curso_Codigo = cur.Curso_Codigo
    INNER JOIN [NORMALIZADOS].[Sede] s ON cur.Sede_ID = s.Sede_ID
WHERE s.SEDE_ID = 4 AND YEAR(enc.Encuesta_FechaRegistro) = 2025 AND MONTH(enc.Encuesta_FechaRegistro) = 7
AND de.Encuesta_Nota BETWEEN 5 AND 6