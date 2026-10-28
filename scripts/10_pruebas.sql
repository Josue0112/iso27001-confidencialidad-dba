-- =====================================================================
-- 10_pruebas.sql
-- Batería de pruebas PR-01 a PR-15.
-- Ejecutar con F5 (modo script) en SQL Developer o en SQL*Plus.
-- Cada bloque se conecta con un usuario distinto. Sacar captura del
-- resultado de cada prueba y guardarla en evidencias/ con el ID (ej. PR-01.png).
-- Algunos errores son el resultado ESPERADO: no detener el script por ellos.
-- =====================================================================

DEFINE servicio = 'localhost:1521/XEPDB1'
WHENEVER SQLERROR CONTINUE
SET LINESIZE 200 PAGESIZE 100
COLUMN event_timestamp FORMAT A28
COLUMN dbusername      FORMAT A12
COLUMN action_name     FORMAT A12
COLUMN object_name     FORMAT A12
COLUMN nombre          FORMAT A22
COLUMN cedula          FORMAT A12

-- ---------------------------------------------------------------------
PROMPT ===== PR-01 (VPD): APP_VENTAS solo debe ver VENTAS =====
CONNECT app_ventas/"Av#Lab2026!Vt"@&servicio
SELECT departamento, COUNT(*) AS filas FROM rrhh.empleados GROUP BY departamento;

PROMPT ===== PR-02 (Redacción): cédula *-****-1234 y salario 0 =====
SELECT id_empleado, cedula, salario FROM rrhh.empleados FETCH FIRST 5 ROWS ONLY;

PROMPT ===== PR-05 (Privilegios): UPDATE debe fallar con ORA-01031 =====
UPDATE rrhh.empleados SET salario = 1;
ROLLBACK;

-- ---------------------------------------------------------------------
PROMPT ===== PR-03 (Positiva): JEFE_RRHH ve 4 departamentos y datos completos =====
CONNECT jefe_rrhh/"Jf#Lab2026!Rh"@&servicio
SELECT departamento, COUNT(*) AS filas FROM rrhh.empleados GROUP BY departamento;
SELECT id_empleado, cedula, salario FROM rrhh.empleados FETCH FIRST 5 ROWS ONLY;

-- ---------------------------------------------------------------------
PROMPT ===== PR-04 (Clon DEV): primera consulta ORA-00942, segunda con cédulas 0- =====
CONNECT dev_rrhh/"Dv#Lab2026!Rr"@&servicio
SELECT COUNT(*) FROM rrhh.empleados;
SELECT id_empleado, nombre, cedula FROM rrhh_dev.empleados FETCH FIRST 5 ROWS ONLY;

-- ---------------------------------------------------------------------
PROMPT ===== PR-06 (DBA sin datos): debe fallar con ORA-00942 =====
CONNECT dba_oper/"Db#Lab2026!Op"@&servicio
SELECT * FROM rrhh.empleados;

PROMPT ===== PR-10 (Separación de funciones): NOAUDIT debe fallar con ORA-01031 =====
NOAUDIT POLICY pol_acceso_empleados;

PROMPT ===== PR-08 (Contraseña débil): debe fallar con ORA-28003 =====
PROMPT (DBA_OPER tiene CREATE USER, así que el único motivo de fallo es la clave)
CREATE USER prueba_clave IDENTIFIED BY "clave123" PROFILE perfil_seguro;

-- ---------------------------------------------------------------------
PROMPT ===== PR-09 (Auditoría): aparecen los SELECT de APP_VENTAS =====
CONNECT auditor_ext/"Au#Lab2026!Ex"@&servicio
SELECT event_timestamp, dbusername, action_name, object_name, return_code
FROM unified_audit_trail
WHERE unified_audit_policies LIKE '%POL_ACCESO_EMPLEADOS%'
ORDER BY event_timestamp DESC
FETCH FIRST 20 ROWS ONLY;

PROMPT ===== Registro del intento de PR-10 (DBA_OPER) =====
SELECT event_timestamp, dbusername, action_name, return_code
FROM unified_audit_trail
WHERE dbusername = 'DBA_OPER'
ORDER BY event_timestamp DESC
FETCH FIRST 10 ROWS ONLY;

-- =====================================================================
-- PRUEBAS MANUALES (no se automatizan en este script)
--
-- PR-07 (Autenticación): en una terminal, intentar 5 veces:
--     sqlplus app_ventas/ClaveMala@localhost:1521/XEPDB1
--   Luego, como SYS:
--     SELECT username, account_status FROM dba_users WHERE username = 'APP_VENTAS';
--     -> LOCKED(TIMED)
--     SELECT event_timestamp, dbusername, return_code FROM unified_audit_trail
--     WHERE action_name = 'LOGON' AND return_code <> 0 ORDER BY event_timestamp DESC;
--   Para desbloquear: ALTER USER app_ventas ACCOUNT UNLOCK;
--
-- PR-11 (TDE):          secciones E10 y E11 de 99_verificacion.sql
-- PR-12 (Respaldo):     ejecutar 06_respaldo_cifrado.rman y la sección E20
-- PR-13 (Red):          después de 09_sqlnet_ora.txt, sección E16
-- PR-14 (Eliminación):  después de 08_eliminacion_segura.sql, sección E18
--
-- PR-15 (DLP): en una terminal:
--     expdp jefe_rrhh/"Jf#Lab2026!Rh"@localhost:1521/XEPDB1 tables=rrhh.empleados directory=DATA_PUMP_DIR dumpfile=prueba.dmp
--   Resultado esperado: error por falta de privilegios sobre el directorio
--   o sobre las tablas de otro esquema (JEFE_RRHH no tiene roles de exportación).
-- =====================================================================
