-- Actividad Formativa S5

-- USUARIO EA2_1_MDY_FOL

/* Se modificó la contraseña del usuario de EA2_1-CreaUsuario.sql por 
   requerimiento de seguridad de Oracle SQL Developer (contraseña 'duoc')

   La línea alterada fue esta: 

   CREATE USER EA2_1_MDY_FOL IDENTIFIED BY "H0l4.O_r4cL3!"
	
*/




/* Función almacenada que retorna el 
   descuento a aplicar rescatado desde 
   la tabla PORC_DESCTO_3RA_EDAD dada una edad.
   En caso de no encontrar un porcentaje, retornará 0. */

CREATE OR REPLACE FUNCTION fn_desc_edad (
    p_edad NUMBER)
    RETURN NUMBER
IS
    -- VARIABLES PARA CÁLCULOS  
    p_porcentaje  NUMBER := 0;
    v_minimo      NUMBER;
    v_maximo      NUMBER;
    
    -- VARIABLES PARA MANEJO DE ERRORES  
    v_codigo_error  NUMBER;
    v_mensaje_error VARCHAR2(255);  
    v_id_error      NUMBER;
    v_error_query   VARCHAR2(255);

BEGIN
    -- QUERY A EJECUTARSE
    v_error_query := 'INSERT INTO errores_informe (id_error, rutina_afectada, mensaje_oracle) 
                      VALUES (:1, :2, :3)';

    -- Validación del parámetro p_edad
    IF p_edad < 0 THEN
        v_id_error := SEQ_ERROR.NEXTVAL;
        DBMS_OUTPUT.PUT_LINE('ID_ERROR: ' || v_id_error || ' - El parámetro p_edad debe ser un número positivo.');
        -- SQL DINÁMICO para registrar el error
        EXECUTE IMMEDIATE v_error_query USING v_id_error, 'Validación de p_edad.', 'El parámetro p_edad debe ser un número positivo.';
        RETURN 0;
    END IF;

    -- Obtener el rango mínimo y máximo para la edad
    SELECT MIN(anno_ini), MAX(anno_ter)
    INTO v_minimo, v_maximo
    FROM PORC_DESCTO_3RA_EDAD;

    -- Comparar la edad con los valores mínimo y máximo
    IF p_edad < v_minimo THEN
        -- Si la edad es menor que el valor mínimo
        DBMS_OUTPUT.PUT_LINE('Edad no corresponde a tercera edad.'); 
        RETURN 0;
        
    ELSIF p_edad > v_maximo THEN
        -- Si la edad es mayor que el valor máximo
        DBMS_OUTPUT.PUT_LINE('Edad excede el valor máximo programado.');
        RETURN 0;
    ELSE
        -- Si la edad está dentro de los rangos válidos
        SELECT porcentaje_descto
        INTO p_porcentaje
        FROM PORC_DESCTO_3RA_EDAD
        WHERE p_edad >= anno_ini
          AND p_edad <= anno_ter;
    END IF;

    -- Retornar el porcentaje
    RETURN p_porcentaje;

EXCEPTION
    -- EXCEPCIÓN PREDEFINIDA POR ORACLE
    WHEN OTHERS THEN
        v_id_error := SEQ_ERROR.NEXTVAL;
        DBMS_OUTPUT.PUT_LINE('ID_ERROR: ' || v_id_error || ' - Error Desconocido.');
        v_codigo_error := SQLCODE;
        v_mensaje_error := SQLERRM; 
        -- SQL DINÁMICO
        EXECUTE IMMEDIATE v_error_query USING v_id_error, v_codigo_error || ' - Porcentaje descuento tercera edad.', v_mensaje_error;
        RETURN 0;

END fn_desc_edad;
/


/*
    -- Probar Función 1: fn_desc_edad
    -- Bloque anónimo

    DECLARE
    v_descuento NUMBER;

    BEGIN
        v_descuento := fn_desc_edad(90);
        DBMS_OUTPUT.PUT_LINE(v_descuento); -- Resulado esperado 20

    END;
    /

    -- Función 1: fn_desc_edad funcionando ok.  
*/






/* Función almacenada que retorna la 
   cantidad de días de atraso que registra 
   una atención dado el ID de atención.
   Esta función utiliza Native Dynamic SQL. */



CREATE OR REPLACE FUNCTION fn_dias_atraso (
    p_id_atencion NUMBER)
    RETURN NUMBER

IS
    -- VARIABLES PARA CÁLCULOS  
    v_dias_atraso  NUMBER;
    v_query       VARCHAR2(255);

    -- VARIABLES PARA MANEJO DE ERRORES  
    v_error_query   VARCHAR2(255);
    v_id_error      NUMBER;
    v_codigo_error  NUMBER;
    v_mensaje_error VARCHAR2(255);  
    


BEGIN
    
    v_dias_atraso := 0;
    
    -- QUERY A EJECUTARSE
    v_query := 'SELECT GREATEST((fecha_pago - fecha_venc_pago), 0) AS dias_atraso
                FROM pago_atencion 
                WHERE ate_id = :1';


    v_error_query := 'INSERT INTO errores_informe (id_error, rutina_afectada, mensaje_oracle) 
                      VALUES (:1, :2, :3)';

    
    -- SQL DINÁMICO CON INTO
    EXECUTE IMMEDIATE v_query INTO v_dias_atraso USING p_id_atencion;


    -- Retornar los días de atraso
    RETURN v_dias_atraso;


EXCEPTION
    -- EXCEPCIÓN PREDEFINIDA POR ORACLE
    WHEN NO_DATA_FOUND THEN
        -- Cuando no se encuentra el ID de atención
        v_id_error := SEQ_ERROR.NEXTVAL;
        DBMS_OUTPUT.PUT_LINE('ID_ERROR: ' || v_id_error || ' - No se encontró la atención con el ID proporcionado.');
        EXECUTE IMMEDIATE v_error_query USING v_id_error, 'Cálculo días de atraso.', 'No se encontró la atención con el ID ' || p_id_atencion;
        RETURN -1;

    WHEN OTHERS THEN
        v_id_error := SEQ_ERROR.NEXTVAL;
        DBMS_OUTPUT.PUT_LINE('ID_ERROR: ' || v_id_error || ' - Error Desconocido.');
        v_codigo_error := SQLCODE;
        v_mensaje_error := SQLERRM; 
        EXECUTE IMMEDIATE v_error_query USING v_id_error, v_codigo_error || ' - Usando fn_dias_atraso.', v_mensaje_error;
        RETURN -1; 


END fn_dias_atraso;
/



/*
    -- Probar Función 2: fn_dias_atraso
    -- Bloque anónimo

    DECLARE
    v_dias_atraso NUMBER;

    BEGIN
        v_dias_atraso := fn_dias_atraso(542);
        DBMS_OUTPUT.PUT_LINE(v_dias_atraso); -- Resulado esperado 12

    END;
    /

    -- Función 2: fn_dias_atraso funcionando ok.  
*/









/* Función almacenada que retorna la edad del paciente
   al primer día de un periodo de tiempo entregado (MM-YYYY) 
   dado el RUT del paciente sin dígito verificador. (12456789) */


CREATE OR REPLACE FUNCTION fn_edad_periodo (
    p_rut_paciente NUMBER,
    p_periodo      VARCHAR2)
    RETURN NUMBER

IS

    -- VARIABLES PARA CÁLCULOS  
    v_edad        NUMBER;
    v_query       VARCHAR2(255);
    v_fecha       DATE;

    -- VARIABLES PARA MANEJO DE ERRORES  
    v_error_query VARCHAR2(255);
    v_id_error      NUMBER;
    v_codigo_error  NUMBER;
    v_mensaje_error VARCHAR2(255);  

BEGIN
    
    v_edad := 0;
    -- Convertir p_periodo a Date con primer día.
    v_fecha := TO_DATE('01-' || p_periodo, 'DD-MM-YYYY');
    
    -- QUERY A EJECUTARSE
    v_query := 'SELECT FLOOR(MONTHS_BETWEEN(TRUNC(:1, ''MM''), fecha_nacimiento) / 12)
                FROM paciente
                WHERE pac_run = :2';


    v_error_query := 'INSERT INTO errores_informe (id_error, rutina_afectada, mensaje_oracle) 
                      VALUES (:1, :2, :3)';


    
    -- SQL DINÁMICO CON INTO
    EXECUTE IMMEDIATE v_query INTO v_edad USING v_fecha, p_rut_paciente;

    -- Revisar edad
    IF v_edad < 0 THEN

    -- Excepción definida por usuario
        v_id_error := SEQ_ERROR.NEXTVAL;
        DBMS_OUTPUT.PUT_LINE('ID_ERROR: '|| v_id_error ||' - El paciente no había nacido en el periodo ingresado.');
        -- SQL DINÁMICO
        EXECUTE IMMEDIATE v_error_query USING v_id_error,'Cálculo para edad.','Paciente no había nacido en el periodo.';
        v_edad := -1;
        RETURN v_edad;


    END IF;


    -- Retornar edad del paciente
    RETURN v_edad;


EXCEPTION

    -- EXCEPCIÓN PREDEFINIDA POR ORACLE
    WHEN NO_DATA_FOUND THEN
        v_id_error := SEQ_ERROR.NEXTVAL;
        DBMS_OUTPUT.PUT_LINE('ID_ERROR: '|| v_id_error ||' - No se encontró el RUT.');
        EXECUTE IMMEDIATE v_error_query USING v_id_error,'Cálculo edad paciente.','No se encontró el pac_run ingresado en tabla PACIENTE';
        RETURN -1;


    WHEN OTHERS THEN
        v_id_error := SEQ_ERROR.NEXTVAL;
        DBMS_OUTPUT.PUT_LINE('ID_ERROR: '|| v_id_error ||' - Error Desconocido.');
        v_codigo_error := SQLCODE;
        v_mensaje_error := SQLERRM; 
        -- SQL DINÁMICO
        EXECUTE IMMEDIATE v_error_query USING v_id_error,v_codigo_error || ' - Usando fn_edad_periodo.',v_mensaje_error;
        RETURN -1;

END fn_edad_periodo;
/



/*
    -- Probar Función 3: fn_edad_periodo
    -- Bloque anónimo

    DECLARE
        v_edad NUMBER;
    BEGIN
        v_edad := fn_edad_periodo(7000164, '01-2024');
        DBMS_OUTPUT.PUT_LINE(v_edad); -- Resulado esperado 30
    END;
    /

    -- Función 3: fn_edad_periodo funcionando ok.  
*/






/* Procedimiento almacenado 1 que permite
    insertar un registro en la tabla RESUMEN_ATENCIONES
    para un periodo determinado y un límite de días de atraso.
    Este procedimiento usa Native Dynamic SQL para ejecutar la sentencia DML. */



CREATE OR REPLACE PROCEDURE sp_resumen_atenciones (
    p_periodo VARCHAR2,
    p_limite_atraso NUMBER)

IS

    -- CURSOR EXPLÍCITO PARA OBTENER DATOS DE ATENCIONES Y EDAD DEL PACIENTE
    CURSOR cr_atencion IS
        SELECT
            pa.ate_id               AS ate_id,
            p.pac_run              AS pac_run,
            pa.fecha_venc_pago      AS fecha_venc_pago,
            pa.fecha_pago           AS fecha_pago,
            a.costo                 AS monto_atencion,
            FLOOR(MONTHS_BETWEEN(TRUNC(pa.fecha_pago, 'MM'), p.fecha_nacimiento) / 12)  AS edad_paciente
        FROM pago_atencion pa LEFT JOIN atencion a 
            ON pa.ate_id = a.ate_id LEFT JOIN paciente p 
            ON a.pac_run = p.pac_run
        WHERE TO_CHAR(a.fecha_atencion,'MM-YYYY') = p_periodo;


    -- VARIABLES PARA CÁLCULOS E INSERT
    v_dias_atraso       NUMBER;
    v_descuento         NUMBER;
    v_monto_cancelar    NUMBER;
    v_edad_paciente     NUMBER;

    -- VARIABLES PARA SQL DINÁMICO  
    v_query       VARCHAR2(255);
    v_error_query VARCHAR2(255);
    
    -- VARIABLES PARA MANEJO DE ERRORES  
    v_codigo_error  NUMBER;
    v_mensaje_error VARCHAR2(255);  
    v_id_error      NUMBER;
    
    -- DEFINICIÓN DE EXCEPCIÓN 
    excepcion_excede_limite_atraso EXCEPTION;
    
     

BEGIN
    

     -- QUERY A EJECUTARSE
    v_query := 'INSERT INTO resumen_atenciones (ate_id, monto_atencion, dias_atraso, descuento, monto_cancelar) 
                VALUES (:1, :2, :3, :4, :5)';


    v_error_query := 'INSERT INTO errores_informe (id_error, rutina_afectada, mensaje_oracle) 
                      VALUES (:1, :2, :3)';


    -- Validación del parámetro p_limite_atraso
    IF p_limite_atraso < 0 THEN
        v_id_error := SEQ_ERROR.NEXTVAL;
        DBMS_OUTPUT.PUT_LINE('ID_ERROR: ' || v_id_error || ' - El parámetro p_limite_atraso debe ser un número positivo.');
        -- SQL DINÁMICO para registrar el error
        EXECUTE IMMEDIATE v_error_query USING v_id_error, 'Validación de p_limite_atraso.', 'El parámetro p_limite_atraso debe ser un número positivo.';
        RETURN;
    END IF;


    -- Abrir cursor explícito cr_atencion
        FOR reg_atenciones IN cr_atencion LOOP

            BEGIN
                -- Calcular días de atraso usando la función almacenada fn_dias_atraso. 
                v_dias_atraso := fn_dias_atraso(reg_atenciones.ate_id);

                -- Si los días de atraso exceden el límite:
                IF v_dias_atraso > p_limite_atraso THEN 
                    -- Excepción definida por usuario (excepcion_excede_limite_atraso)
                    
                    /* RAISE excepcion_excede_limite_atraso;
                        Si se usa RAISE, el valor no se insertará en la tabla RESUMEN_ATENCIONES.

                        Si se desea evitar el insert del error en RESUMEN_ATENCIONES, 
                        cambiar las 4 líneas siguientes por RAISE excepcion_excede_limite_atraso; */
                    v_id_error := SEQ_ERROR.NEXTVAL;
                    DBMS_OUTPUT.PUT_LINE('ID_ERROR: '|| v_id_error ||' - Los días de atraso de id: '|| reg_atenciones.ate_id ||' exceden el límite.');
                    -- SQL DINÁMICO
                    EXECUTE IMMEDIATE v_error_query USING v_id_error,'Cálculo para insert en RESUMEN_ATENCIONES.','Días de atraso de id: '|| reg_atenciones.ate_id ||' exceden el límite paramétrico.';


                END IF;


                -- Calcular edad del paciente usando función almacenada fn_edad_periodo. 
                v_edad_paciente := fn_edad_periodo (reg_atenciones.pac_run, p_periodo);


                -- Calcular el valor del descuento usando la función almacenada fn_desc_edad.
                v_descuento := ROUND(reg_atenciones.monto_atencion * (fn_desc_edad(v_edad_paciente)/100));

                -- Calcular el monto a cancelar.
                v_monto_cancelar := reg_atenciones.monto_atencion - v_descuento;
                
                -- Almacenar datos en tabla RESUMEN_ATENCIONES usando SQL dinámico.

                EXECUTE IMMEDIATE v_query USING reg_atenciones.ate_id,
                                                reg_atenciones.monto_atencion,
                                                v_dias_atraso,
                                                v_descuento,
                                                v_monto_cancelar;
            EXCEPTION

                -- EXCEPCIÓN DEFINIDA POR USUARIO
                WHEN excepcion_excede_limite_atraso THEN
                    v_id_error := SEQ_ERROR.NEXTVAL;
                    DBMS_OUTPUT.PUT_LINE('ID_ERROR: '|| v_id_error ||' - Los días de atraso exceden el límite.');
                    -- SQL DINÁMICO
                    EXECUTE IMMEDIATE v_error_query USING v_id_error,'Cálculo para insert en RESUMEN_ATENCIONES.','Días de atraso exceden el límite paramétrico.';


                -- EXCEPCIÓN PREDEFINIDA POR ORACLE

                WHEN DUP_VAL_ON_INDEX THEN
                    v_id_error := SEQ_ERROR.NEXTVAL;
                    DBMS_OUTPUT.PUT_LINE('ID_ERROR: '|| v_id_error ||' - Se ingresó un valor duplicado.');
                    EXECUTE IMMEDIATE v_error_query USING v_id_error,'Insert en RESUMEN_ATENCIONES.','Valor duplicado en RESUMEN_ATENCIONES.';
                


                WHEN OTHERS THEN
                    v_id_error := SEQ_ERROR.NEXTVAL;
                    DBMS_OUTPUT.PUT_LINE('ID_ERROR: '|| v_id_error ||' - Error Desconocido.');
                    v_codigo_error := SQLCODE;
                    v_mensaje_error := SQLERRM; 
                    -- SQL DINÁMICO
                    EXECUTE IMMEDIATE v_error_query USING v_id_error,v_codigo_error || ' - Usando Cursor cr_atencion.',v_mensaje_error;
        
            END;



        END LOOP;


END sp_resumen_atenciones;
/


/*
    -- Probar Procedimiento 1: sp_resumen_atenciones

      -- Bloque anónimo

        DECLARE

        BEGIN
            sp_resumen_atenciones('01-2024', 150);

        END;
        /

        -- Revisar tablas:


        -- TABLA resumen_atenciones
        SELECT * 
        FROM resumen_atenciones;


        -- TABLA errores_informe
        SELECT *
        FROM errores_informe;
    

        -- Procedimiento 1: sp_resumen_atenciones funcionando ok.  
*/







/* Procedimiento almacenado (principal) para generar
   informes solicitados ingresando un periodo MM-YYYY 
   y un límite de días de atraso de forma paramétrica. */


CREATE OR REPLACE PROCEDURE sp_generar_informes (
    p_periodo VARCHAR2,
    p_limite_atraso NUMBER)

IS


BEGIN
    
    -- Llamar al procedimiento 1 para que genere informes.
    sp_resumen_atenciones(p_periodo, p_limite_atraso);


END sp_generar_informes;
/



-- Probar Procedimiento (principal): sp_generar_informes


/*
    -- SI DESEA VACIAR TABLAS:
    
    TRUNCATE TABLE RESUMEN_ATENCIONES;
    TRUNCATE TABLE ERRORES_INFORME;
*/


-- Bloque anónimo

DECLARE

BEGIN
    -- INGRESAR 01-2024 COMO PERIODO Y 150 COMO LÍMITE DE DÍAS
    sp_generar_informes('&Ingrese_periodo_MM_guion_YYYY', &Ingrese_limite_dias);
END;
/

-- Revisar tablas:

-- TABLA resumen_atenciones
SELECT * 
FROM resumen_atenciones;


-- TABLA errores_informe
SELECT *
FROM errores_informe;
