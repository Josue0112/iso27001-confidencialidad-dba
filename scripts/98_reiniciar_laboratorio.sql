-- =====================================================================
-- 98_reiniciar_laboratorio.sql
-- Deja XEPDB1 como estaba antes del script 00, para repetir la instalación.
-- Se puede correr aunque la instalación haya quedado a medias: lo que no
-- existe se informa y se salta.
--
-- Ejecutar en SQL*Plus como SYS AS SYSDBA:
--   sqlplus / as sysdba
--   @98_reiniciar_laboratorio.sql
--
-- NO se deshace (no hace falta para reinstalar):
--   - El keystore TDE y el parámetro WALLET_ROOT. Al reinstalar, en lugar
--     del 03 se corre 03b_tde_solo_tablespace.sql.
--   - El modo ARCHIVELOG.
--   - Los cambios de sqlnet.ora.
--   - El bloqueo de las cuentas Oracle por defecto hecho en el 01.
--
-- Orden para reinstalar después de este script:
--   00, 01, 02, 03b, 04, 05, 07, 08, 06 (RMAN), 10, 99
-- =====================================================================

ALTER SESSION SET CONTAINER = XEPDB1;
SET SERVEROUTPUT ON

DECLARE
  PROCEDURE ejecutar(p_sentencia IN VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE p_sentencia;
    DBMS_OUTPUT.PUT_LINE('OK      ' || p_sentencia);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Saltado ' || p_sentencia || '  -> ' || SQLERRM);
  END;
BEGIN
  -- 1. Cerrar sesiones abiertas de los usuarios del laboratorio
  FOR sesion IN (SELECT sid, serial#
                 FROM v$session
                 WHERE username IN ('JEFE_RRHH','APP_VENTAS','ANALISTA_TI','DEV_RRHH',
                                    'AUDITOR_EXT','DBA_OPER','SEG_ADMIN','PRUEBA_CLAVE')) LOOP
    ejecutar('ALTER SYSTEM KILL SESSION ''' || sesion.sid || ',' || sesion.serial# || ''' IMMEDIATE');
  END LOOP;

  -- 2. Políticas de auditoría: primero se desactivan y luego se borran
  FOR politica IN (SELECT policy_name, entity_name
                   FROM audit_unified_enabled_policies
                   WHERE policy_name IN ('POL_ACCESO_EMPLEADOS','POL_GESTION_IDENTIDADES',
                                         'POL_LOGON_FALLIDO','POL_EXPORTACION',
                                         'POL_POLITICAS_SEGURIDAD','POL_ACTIVIDAD_DBA')) LOOP
    IF politica.entity_name = 'ALL USERS' THEN
      ejecutar('NOAUDIT POLICY ' || politica.policy_name);
    ELSE
      ejecutar('NOAUDIT POLICY ' || politica.policy_name || ' BY ' || politica.entity_name);
    END IF;
  END LOOP;

  ejecutar('DROP AUDIT POLICY pol_acceso_empleados');
  ejecutar('DROP AUDIT POLICY pol_gestion_identidades');
  ejecutar('DROP AUDIT POLICY pol_logon_fallido');
  ejecutar('DROP AUDIT POLICY pol_exportacion');
  ejecutar('DROP AUDIT POLICY pol_politicas_seguridad');
  ejecutar('DROP AUDIT POLICY pol_actividad_dba');

  -- 3. Redacción y VPD (también se borran con la tabla; se hace explícito por claridad)
  ejecutar('BEGIN DBMS_REDACT.DROP_POLICY(''RRHH'', ''EMPLEADOS'', ''RED_EMPLEADOS_CONFIDENCIAL''); END;');
  ejecutar('BEGIN DBMS_RLS.DROP_POLICY(''RRHH'', ''EMPLEADOS'', ''VPD_EMPLEADOS_DEPTO''); END;');

  -- 4. Usuarios (CASCADE borra sus tablas, la función VPD y el clon)
  ejecutar('DROP USER rrhh_dev CASCADE');
  ejecutar('DROP USER rrhh CASCADE');
  ejecutar('DROP USER jefe_rrhh CASCADE');
  ejecutar('DROP USER app_ventas CASCADE');
  ejecutar('DROP USER analista_ti CASCADE');
  ejecutar('DROP USER dev_rrhh CASCADE');
  ejecutar('DROP USER auditor_ext CASCADE');
  ejecutar('DROP USER dba_oper CASCADE');
  ejecutar('DROP USER seg_admin CASCADE');
  -- por si la prueba PR-08 llegó a crearlo
  ejecutar('DROP USER prueba_clave CASCADE');

  -- 5. Roles y perfil
  ejecutar('DROP ROLE rol_rrhh_lectura');
  ejecutar('DROP ROLE rol_rrhh_escritura');
  ejecutar('DROP ROLE rol_rrhh_confidencial');
  ejecutar('DROP ROLE rol_dba_operativo');
  ejecutar('DROP PROFILE perfil_seguro CASCADE');

  -- 6. Tablespaces y sus archivos
  ejecutar('DROP TABLESPACE rrhh_seguro INCLUDING CONTENTS AND DATAFILES');
  ejecutar('DROP TABLESPACE rrhh_datos INCLUDING CONTENTS AND DATAFILES');

  -- 7. Papelera
  ejecutar('PURGE DBA_RECYCLEBIN');
END;
/

-- 8. (Opcional) Vaciar la auditoría para que la demostración empiece limpia.
--    Quitar los comentarios de las 3 líneas siguientes si se quiere usar.
-- BEGIN
--   DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED, use_last_arch_timestamp => FALSE);
-- END;
-- /

-- 9. (Opcional) Borrar los respaldos del laboratorio. Se hace desde cmd con RMAN:
--    rman target /
--    DELETE NOPROMPT BACKUP TAG 'RESPALDO_CIFRADO_LAB';

-- Comprobación: las tres consultas deben devolver 0 filas
SELECT username FROM dba_users
WHERE username IN ('RRHH','RRHH_DEV','JEFE_RRHH','APP_VENTAS','ANALISTA_TI',
                   'DEV_RRHH','AUDITOR_EXT','DBA_OPER','SEG_ADMIN');

SELECT tablespace_name FROM dba_tablespaces WHERE tablespace_name LIKE 'RRHH%';

SELECT policy_name FROM audit_unified_policies WHERE policy_name LIKE 'POL\_%' ESCAPE '\';
