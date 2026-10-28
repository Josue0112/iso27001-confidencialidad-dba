-- =====================================================================
-- 99_verificacion.sql
-- Consultas de evidencia E01 a E20 para la matriz de evaluación y el auditor.
-- Ejecutar como SYS AS SYSDBA (o AUDITOR_EXT, salvo E20) con F5 en SQL Developer.
-- El resultado se guarda en verificacion_controles.txt (carpeta evidencias/).
-- =====================================================================

ALTER SESSION SET CONTAINER = XEPDB1;
SET LINESIZE 220 PAGESIZE 200 TRIMSPOOL ON
COLUMN comments FORMAT A50
COLUMN expression FORMAT A60
COLUMN network_service_banner FORMAT A90
COLUMN handle FORMAT A70

SPOOL verificacion_controles.txt

PROMPT === E01 Cuentas con contraseña por defecto (A5.17) ===
SELECT u.username, u.account_status
FROM dba_users_with_defpwd d
JOIN dba_users u ON u.username = d.username
ORDER BY u.account_status, u.username;

PROMPT === E02 Usuarios del laboratorio: estado, perfil y último acceso (A5.16, A5.18) ===
SELECT username, account_status, profile, authentication_type, last_login
FROM dba_users
WHERE oracle_maintained = 'N'
ORDER BY username;

PROMPT === E02b Cuentas Oracle por defecto que siguen abiertas (A5.16) ===
SELECT username, account_status
FROM dba_users
WHERE oracle_maintained = 'Y' AND account_status = 'OPEN';

PROMPT === E03 Perfil seguro (A5.17, A8.5) ===
SELECT resource_name, limit
FROM dba_profiles
WHERE profile = 'PERFIL_SEGURO'
ORDER BY resource_name;

PROMPT === E04 Roles críticos otorgados (A8.2, A5.33, A8.12) ===
SELECT granted_role, grantee
FROM dba_role_privs
WHERE granted_role IN ('DBA', 'AUDIT_ADMIN', 'AUDIT_VIEWER',
                       'DATAPUMP_EXP_FULL_DATABASE', 'EXP_FULL_DATABASE')
ORDER BY granted_role, grantee;

PROMPT === E05 Privilegios ANY en usuarios o roles del laboratorio (A8.2) ===
SELECT grantee, privilege
FROM dba_sys_privs
WHERE privilege LIKE '%ANY%'
  AND grantee IN (SELECT username FROM dba_users WHERE oracle_maintained = 'N'
                  UNION
                  SELECT role FROM dba_roles WHERE oracle_maintained = 'N');

PROMPT === E06 Usuarios con privilegios administrativos (A8.2) ===
SELECT username, sysdba, sysoper, sysbackup, syskm
FROM v$pwfile_users;

PROMPT === E07 Privilegios de objeto sobre RRHH y RRHH_DEV (A5.15) ===
SELECT owner, table_name, grantee, privilege
FROM dba_tab_privs
WHERE owner IN ('RRHH', 'RRHH_DEV')
ORDER BY owner, table_name, grantee;

PROMPT === E08 Roles de los usuarios del laboratorio (A5.15, A5.18) ===
SELECT grantee, granted_role
FROM dba_role_privs
WHERE grantee IN (SELECT username FROM dba_users WHERE oracle_maintained = 'N')
ORDER BY grantee, granted_role;

PROMPT === E09 Clasificación de columnas (A5.12) ===
SELECT table_name, column_name, comments
FROM dba_col_comments
WHERE owner = 'RRHH' AND comments IS NOT NULL
ORDER BY column_name;

PROMPT === E10 Estado del keystore TDE (A8.24 / A8.12) ===
SELECT con_id, wrl_type, status, wallet_type
FROM v$encryption_wallet;

PROMPT === E11 Tablespaces cifrados y ubicación de las tablas (A8.12) ===
SELECT t.name AS tablespace, e.encryptionalg, e.encryptedts
FROM v$encrypted_tablespaces e
JOIN v$tablespace t ON t.ts# = e.ts# AND t.con_id = e.con_id;

SELECT owner, table_name, tablespace_name
FROM dba_tables
WHERE owner = 'RRHH';

PROMPT === E12 Políticas de redacción (A8.11) ===
SELECT object_owner, object_name, policy_name, expression, enable
FROM redaction_policies;
SELECT object_name, column_name, function_type, function_parameters
FROM redaction_columns;

PROMPT === E13 Políticas VPD (A8.3) ===
SELECT object_owner, object_name, policy_name, function, sel, ins, upd, del, enable
FROM dba_policies
WHERE object_owner = 'RRHH';

PROMPT === E14 Políticas de auditoría habilitadas (A8.15, A8.12) ===
SELECT policy_name, enabled_option, entity_name, success, failure
FROM audit_unified_enabled_policies
WHERE policy_name LIKE 'POL\_%' ESCAPE '\'
ORDER BY policy_name;

PROMPT === E15 Registros de auditoría de las últimas 24 horas (A8.15, A5.33) ===
SELECT event_timestamp, dbusername, action_name, object_schema, object_name,
       return_code, unified_audit_policies
FROM unified_audit_trail
WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '1' DAY
ORDER BY event_timestamp DESC
FETCH FIRST 50 ROWS ONLY;

PROMPT === E16 Cifrado de la sesión actual (A8.20) ===
PROMPT (debe mostrar AES256 y SHA256 cuando se conecta por red, no con "/ as sysdba")
SELECT network_service_banner
FROM v$session_connect_info
WHERE sid = SYS_CONTEXT('USERENV', 'SID');

PROMPT === E17 Clon DEV enmascarado (A8.11) ===
SELECT id_empleado, nombre, cedula, correo, telefono
FROM rrhh_dev.empleados
FETCH FIRST 5 ROWS ONLY;

SELECT COUNT(*) AS cedulas_reales_en_clon
FROM rrhh_dev.empleados dev
JOIN rrhh.empleados prod ON prod.cedula = dev.cedula;

PROMPT === E18 Eliminación segura (A8.10) ===
SELECT COUNT(*) AS objetos_en_papelera FROM dba_recyclebin;
SELECT tablespace_name, status FROM dba_tablespaces WHERE tablespace_name LIKE 'RRHH%';
SELECT COUNT(*) AS empleados_fuera_de_retencion
FROM rrhh.empleados
WHERE fecha_salida < ADD_MONTHS(SYSDATE, -60);

PROMPT === E19 Versión y parches (A8.8, complementario) ===
SELECT banner_full FROM v$version;
SELECT patch_id, action, status, action_time, description
FROM dba_registry_sqlpatch
ORDER BY action_time;

PROMPT === E20 Respaldos cifrados (A8.13) - se consulta desde CDB$ROOT ===
ALTER SESSION SET CONTAINER = CDB$ROOT;
SELECT tag, handle, encrypted, completion_time
FROM v$backup_piece
WHERE tag = 'RESPALDO_CIFRADO_LAB'
ORDER BY completion_time DESC;

SPOOL OFF
