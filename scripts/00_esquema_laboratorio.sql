-- =====================================================================
-- 00_esquema_laboratorio.sql
-- Crea el entorno de laboratorio: tablespace, esquema RRHH y datos ficticios.
-- Ejecutar como SYS AS SYSDBA (SQL Developer, modo script F5, o SQL*Plus).
-- Base: Oracle 21c XE, PDB XEPDB1.
-- =====================================================================

-- Ajustar esta ruta a la carpeta de datafiles de XEPDB1 en tu equipo.
-- Se puede consultar con:  SELECT file_name FROM dba_data_files;
DEFINE ruta_datafiles = 'C:\APP\JOSGU\PRODUCT\21C\ORADATA\XE\XEPDB1'

ALTER SESSION SET CONTAINER = XEPDB1;
SET SERVEROUTPUT ON

-- Tablespace SIN cifrar (estado "antes"). En el script 03 los datos
-- se mueven a un tablespace cifrado y en el 08 este se elimina.
CREATE TABLESPACE rrhh_datos
  DATAFILE '&ruta_datafiles\rrhh_datos01.dbf' SIZE 50M REUSE
  AUTOEXTEND ON NEXT 10M MAXSIZE 300M;

-- Dueño del esquema sin contraseña: nadie puede iniciar sesión como RRHH (A5.16)
CREATE USER rrhh NO AUTHENTICATION
  DEFAULT TABLESPACE rrhh_datos
  QUOTA UNLIMITED ON rrhh_datos;

CREATE TABLE rrhh.empleados (
  id_empleado    NUMBER(6)     CONSTRAINT empleados_pk PRIMARY KEY,
  nombre         VARCHAR2(80)  NOT NULL,
  cedula         VARCHAR2(12)  NOT NULL,
  correo         VARCHAR2(80),
  telefono       VARCHAR2(9),
  salario        NUMBER(10,2),
  departamento   VARCHAR2(20)  NOT NULL,
  fecha_ingreso  DATE          NOT NULL,
  fecha_salida   DATE
) TABLESPACE rrhh_datos;

-- Tabla que asocia cada usuario con el departamento que puede ver (usada por VPD)
CREATE TABLE rrhh.usuario_depto (
  usuario       VARCHAR2(128) CONSTRAINT usuario_depto_pk PRIMARY KEY,
  departamento  VARCHAR2(20)  NOT NULL
) TABLESPACE rrhh_datos;

-- 60 empleados FICTICIOS. Cada décimo empleado salió de la empresa hace 6 años
-- (sirve para la prueba de eliminación por retención del script 08).
BEGIN
  FOR numero_empleado IN 1 .. 60 LOOP
    INSERT INTO rrhh.empleados VALUES (
      numero_empleado,
      'Persona Ficticia ' || numero_empleado,
      TRUNC(DBMS_RANDOM.VALUE(1, 8)) || '-' ||
        LPAD(TRUNC(DBMS_RANDOM.VALUE(0, 10000)), 4, '0') || '-' ||
        LPAD(TRUNC(DBMS_RANDOM.VALUE(0, 10000)), 4, '0'),
      'persona' || numero_empleado || '@empresa-ficticia.cr',
      '8' || LPAD(TRUNC(DBMS_RANDOM.VALUE(0, 10000000)), 7, '0'),
      ROUND(DBMS_RANDOM.VALUE(450000, 2500000), 2),
      CASE MOD(numero_empleado, 4)
        WHEN 0 THEN 'FINANZAS'
        WHEN 1 THEN 'TI'
        WHEN 2 THEN 'VENTAS'
        ELSE 'RRHH'
      END,
      CASE WHEN MOD(numero_empleado, 10) = 0
           THEN ADD_MONTHS(SYSDATE, -TRUNC(DBMS_RANDOM.VALUE(90, 180)))
           ELSE ADD_MONTHS(SYSDATE, -TRUNC(DBMS_RANDOM.VALUE(1, 60)))
      END,
      CASE WHEN MOD(numero_empleado, 10) = 0
           THEN ADD_MONTHS(SYSDATE, -72)
      END
    );
  END LOOP;
  COMMIT;
END;
/

-- Comprobación
SELECT departamento, COUNT(*) AS cantidad
FROM rrhh.empleados
GROUP BY departamento
ORDER BY departamento;
