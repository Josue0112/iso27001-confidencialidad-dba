-- =====================================================================
-- 07_clon_dev_enmascarado.sql
-- Controles: A8.11 Enmascaramiento (estático), A8.12 Prevención de fuga,
-- A5.12 Clasificación.
-- Crea un clon de desarrollo SIN datos reales. La transformación se hace en
-- el mismo CREATE TABLE AS SELECT, así los datos originales nunca se copian.
-- Ejecutar como SYS AS SYSDBA.
-- =====================================================================

ALTER SESSION SET CONTAINER = XEPDB1;

CREATE USER rrhh_dev NO AUTHENTICATION
  DEFAULT TABLESPACE users
  QUOTA 50M ON users;

CREATE TABLE rrhh_dev.empleados TABLESPACE users AS
SELECT id_empleado,
       'Empleado de prueba ' || id_empleado                       AS nombre,
       -- Las cédulas de prueba empiezan con 0, que no es una provincia válida
       '0-' || LPAD(MOD(id_empleado * 7919, 10000), 4, '0') || '-' ||
               LPAD(MOD(id_empleado * 104729, 10000), 4, '0')      AS cedula,
       'usuario' || id_empleado || '@ejemplo.test'                AS correo,
       '0000' || LPAD(id_empleado, 4, '0')                        AS telefono,
       ROUND(DBMS_RANDOM.VALUE(400000, 2600000), -3)              AS salario,
       departamento,
       fecha_ingreso,
       fecha_salida
FROM rrhh.empleados;

COMMENT ON TABLE rrhh_dev.empleados IS 'INTERNO - clon de desarrollo con datos enmascarados';

-- El desarrollador solo trabaja sobre el clon
GRANT SELECT, INSERT, UPDATE, DELETE ON rrhh_dev.empleados TO dev_rrhh;

-- Comprobación: ninguna cédula del clon debe coincidir con una real
SELECT COUNT(*) AS cedulas_reales_en_clon
FROM rrhh_dev.empleados dev
JOIN rrhh.empleados prod ON prod.cedula = dev.cedula;

SELECT id_empleado, nombre, cedula, correo, salario
FROM rrhh_dev.empleados
FETCH FIRST 5 ROWS ONLY;
