-- =====================================================================
-- 02_privilegios_clasificacion.sql
-- Controles: A5.12 Clasificación, A5.15 Control de acceso,
-- A5.18 Derechos de acceso, A8.2 Acceso privilegiado, A5.33 (roles de auditoría).
-- Ejecutar como SYS AS SYSDBA, después del script 01.
-- =====================================================================

ALTER SESSION SET CONTAINER = XEPDB1;

-- ---------- Roles por función (mínimo privilegio) ----------
CREATE ROLE rol_rrhh_lectura;
CREATE ROLE rol_rrhh_escritura;
-- Quien tiene ROL_RRHH_CONFIDENCIAL ve cédula y salario sin redactar (script 04).
-- ROL_DBA_OPERATIVO: administración sin rol DBA ni privilegios ANY.
-- (Los comentarios van en su propia línea: SQL*Plus no ejecuta una
--  instrucción si después del ; hay un comentario en la misma línea.)
CREATE ROLE rol_rrhh_confidencial;
CREATE ROLE rol_dba_operativo;

GRANT SELECT ON rrhh.empleados TO rol_rrhh_lectura;
GRANT INSERT, UPDATE ON rrhh.empleados TO rol_rrhh_escritura;

-- Operación diaria del DBA, sin acceso a los datos de RRHH
GRANT CREATE SESSION, CREATE USER, ALTER USER, DROP USER,
      CREATE TABLESPACE, ALTER TABLESPACE, CREATE PROFILE, ALTER PROFILE
  TO rol_dba_operativo;
GRANT SELECT_CATALOG_ROLE TO rol_dba_operativo;

-- ---------- Asignación a usuarios ----------
GRANT CREATE SESSION TO jefe_rrhh, app_ventas, analista_ti, dev_rrhh, auditor_ext, seg_admin;

GRANT rol_rrhh_lectura      TO jefe_rrhh, app_ventas, analista_ti;
GRANT rol_rrhh_escritura    TO jefe_rrhh;
GRANT rol_rrhh_confidencial TO jefe_rrhh;

GRANT rol_dba_operativo TO dba_oper;

-- Separación de funciones en la auditoría (A5.33):
-- solo SEG_ADMIN administra políticas; el auditor solo las lee.
GRANT AUDIT_ADMIN  TO seg_admin;
GRANT AUDIT_VIEWER TO auditor_ext;
GRANT SELECT_CATALOG_ROLE TO auditor_ext;

-- DEV_RRHH no recibe nada sobre RRHH; trabaja solo en el clon (script 07).

-- ---------- PUBLIC ----------
-- No se otorga nada a PUBLIC sobre RRHH. Como endurecimiento adicional se
-- podrían revocar paquetes de red de PUBLIC. Se deja comentado porque puede
-- invalidar componentes de XE; probar antes y recompilar con utlrp.sql:
-- REVOKE EXECUTE ON utl_http FROM PUBLIC;
-- REVOKE EXECUTE ON utl_tcp  FROM PUBLIC;
-- REVOKE EXECUTE ON utl_smtp FROM PUBLIC;

-- ---------- Clasificación de la información (A5.12) ----------
COMMENT ON TABLE  rrhh.empleados              IS 'CONFIDENCIAL - contiene datos personales (Ley 8968)';
COMMENT ON COLUMN rrhh.empleados.cedula       IS 'CONFIDENCIAL - identificador personal';
COMMENT ON COLUMN rrhh.empleados.salario      IS 'CONFIDENCIAL - dato financiero';
COMMENT ON COLUMN rrhh.empleados.nombre       IS 'RESTRINGIDO - dato personal';
COMMENT ON COLUMN rrhh.empleados.correo       IS 'RESTRINGIDO - dato de contacto';
COMMENT ON COLUMN rrhh.empleados.telefono     IS 'RESTRINGIDO - dato de contacto';
COMMENT ON COLUMN rrhh.empleados.departamento IS 'INTERNO';

-- Comprobación
SELECT grantee, granted_role
FROM dba_role_privs
WHERE grantee IN (SELECT username FROM dba_users WHERE oracle_maintained = 'N')
ORDER BY grantee, granted_role;

SELECT grantee, table_name, privilege
FROM dba_tab_privs
WHERE owner = 'RRHH'
ORDER BY table_name, grantee;
