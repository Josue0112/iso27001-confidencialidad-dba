-- =====================================================================
-- 08_eliminacion_segura.sql
-- Control: A8.10 Eliminación de información.
-- Ejecutar como SYS AS SYSDBA, DESPUÉS de los scripts 03 a 07.
-- =====================================================================

ALTER SESSION SET CONTAINER = XEPDB1;
SET SERVEROUTPUT ON

-- 1. Datos fuera del plazo de retención.
--    Supuesto del laboratorio: se conservan 5 años después de la salida.
--    El borrado queda registrado por POL_ACCESO_EMPLEADOS (script 05).
SELECT COUNT(*) AS empleados_a_eliminar
FROM rrhh.empleados
WHERE fecha_salida < ADD_MONTHS(SYSDATE, -60);

DELETE FROM rrhh.empleados
WHERE fecha_salida < ADD_MONTHS(SYSDATE, -60);
COMMIT;

-- 2. Tablespace original sin cifrar.
--    Aunque las tablas se movieron, sus bloques viejos pueden conservar datos
--    en claro. Antes de eliminarlo se verifica que no le queden objetos.
DECLARE
  v_segmentos NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_segmentos
  FROM dba_segments
  WHERE tablespace_name = 'RRHH_DATOS';

  IF v_segmentos > 0 THEN
    RAISE_APPLICATION_ERROR(-20001,
      'RRHH_DATOS todavía tiene ' || v_segmentos || ' segmentos. Revisar el script 03.');
  END IF;
  DBMS_OUTPUT.PUT_LINE('RRHH_DATOS está vacío; se puede eliminar.');
END;
/

DROP TABLESPACE rrhh_datos INCLUDING CONTENTS AND DATAFILES;

-- 3. Papelera de reciclaje (objetos borrados que aún se podrían recuperar)
PURGE DBA_RECYCLEBIN;

-- Nota: DROP TABLESPACE borra el archivo pero no sobrescribe el disco.
-- El borrado seguro a nivel de sistema operativo queda pendiente (hallazgo H-04).

-- Comprobación
SELECT COUNT(*) AS objetos_en_papelera FROM dba_recyclebin;
SELECT tablespace_name FROM dba_tablespaces WHERE tablespace_name LIKE 'RRHH%';
