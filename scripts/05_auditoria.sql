-- =====================================================================
-- 05_auditoria.sql
-- Controles: A8.15 Registro, A5.33 Protección de registros,
-- A8.12 Prevención de fuga (auditoría de exportaciones), A8.2 (actividad del DBA).
-- Ejecutar como SEG_ADMIN (tiene AUDIT_ADMIN) o como SYS AS SYSDBA.
-- =====================================================================

-- Si se ejecuta como SYS:
ALTER SESSION SET CONTAINER = XEPDB1;

-- 1. Acceso a datos personales
CREATE AUDIT POLICY pol_acceso_empleados
  ACTIONS SELECT ON rrhh.empleados,
          INSERT ON rrhh.empleados,
          UPDATE ON rrhh.empleados,
          DELETE ON rrhh.empleados;
AUDIT POLICY pol_acceso_empleados;

-- 2. Gestión de identidades y privilegios
CREATE AUDIT POLICY pol_gestion_identidades
  ACTIONS CREATE USER, ALTER USER, DROP USER,
          CREATE ROLE, DROP ROLE,
          CREATE PROFILE, ALTER PROFILE,
          GRANT, REVOKE;
AUDIT POLICY pol_gestion_identidades;

-- 3. Inicios de sesión fallidos
CREATE AUDIT POLICY pol_logon_fallido
  ACTIONS LOGON;
AUDIT POLICY pol_logon_fallido WHENEVER NOT SUCCESSFUL;

-- 4. Exportaciones con Data Pump (fuga de datos)
CREATE AUDIT POLICY pol_exportacion
  ACTIONS COMPONENT = DATAPUMP EXPORT;
AUDIT POLICY pol_exportacion;

-- 5. Cambios en las políticas de seguridad (redacción, VPD, claves TDE)
CREATE AUDIT POLICY pol_politicas_seguridad
  ACTIONS EXECUTE ON sys.dbms_redact,
          EXECUTE ON sys.dbms_rls,
          ADMINISTER KEY MANAGEMENT;
AUDIT POLICY pol_politicas_seguridad;

-- 6. Toda la actividad del DBA operativo
CREATE AUDIT POLICY pol_actividad_dba
  ACTIONS ALL;
AUDIT POLICY pol_actividad_dba BY dba_oper;

-- Comprobación
SELECT policy_name, enabled_option, entity_name, success, failure
FROM audit_unified_enabled_policies
WHERE policy_name LIKE 'POL\_%' ESCAPE '\'
ORDER BY policy_name;
