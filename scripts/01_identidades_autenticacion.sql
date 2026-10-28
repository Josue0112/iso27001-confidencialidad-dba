-- =====================================================================
-- 01_identidades_autenticacion.sql
-- Controles: A5.16 Gestión de identidades, A5.17 Información de
-- autenticación, A8.5 Autenticación segura.
-- Ejecutar como SYS AS SYSDBA.
-- Las contraseñas son de LABORATORIO; cambiarlas si se reutiliza el entorno.
-- =====================================================================

ALTER SESSION SET CONTAINER = XEPDB1;
SET SERVEROUTPUT ON

-- Perfil de contraseñas seguro.
-- ORA12C_STRONG_VERIFY_FUNCTION exige mínimo 9 caracteres con
-- 2 mayúsculas, 2 minúsculas, 2 dígitos y 2 caracteres especiales.
-- Si da error porque la función no existe, ejecutar primero:
--   @?/rdbms/admin/utlpwdmg.sql
CREATE PROFILE perfil_seguro LIMIT
  FAILED_LOGIN_ATTEMPTS     5
  PASSWORD_LOCK_TIME        1/24      -- bloqueo de 1 hora
  PASSWORD_LIFE_TIME        90
  PASSWORD_GRACE_TIME       7
  PASSWORD_REUSE_TIME       365
  PASSWORD_REUSE_MAX        5
  INACTIVE_ACCOUNT_TIME     90        -- A5.18: bloquea cuentas sin uso
  IDLE_TIME                 30
  PASSWORD_VERIFY_FUNCTION  ora12c_strong_verify_function;

-- Cuentas nominales: una por persona o función, ninguna compartida
CREATE USER jefe_rrhh   IDENTIFIED BY "Jf#Lab2026!Rh" PROFILE perfil_seguro;
CREATE USER app_ventas  IDENTIFIED BY "Av#Lab2026!Vt" PROFILE perfil_seguro;
CREATE USER analista_ti IDENTIFIED BY "At#Lab2026!Tx" PROFILE perfil_seguro;
CREATE USER dev_rrhh    IDENTIFIED BY "Dv#Lab2026!Rr" PROFILE perfil_seguro;
CREATE USER auditor_ext IDENTIFIED BY "Au#Lab2026!Ex" PROFILE perfil_seguro;
CREATE USER dba_oper    IDENTIFIED BY "Db#Lab2026!Op" PROFILE perfil_seguro;
CREATE USER seg_admin   IDENTIFIED BY "Sg#Lab2026!Ad" PROFILE perfil_seguro;

-- Bloquear cuentas mantenidas por Oracle que estén abiertas (excepto SYS y SYSTEM).
-- Algunas cuentas comunes no se pueden alterar desde la PDB; se informa y se sigue.
BEGIN
  FOR cuenta IN (SELECT username
                 FROM dba_users
                 WHERE oracle_maintained = 'Y'
                   AND account_status = 'OPEN'
                   AND username NOT IN ('SYS', 'SYSTEM')) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'ALTER USER "' || cuenta.username || '" ACCOUNT LOCK';
      DBMS_OUTPUT.PUT_LINE('Bloqueada: ' || cuenta.username);
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('No se pudo bloquear ' || cuenta.username || ': ' || SQLERRM);
    END;
  END LOOP;
END;
/

-- Comprobación
SELECT username, account_status, profile, authentication_type
FROM dba_users
WHERE oracle_maintained = 'N'
ORDER BY username;

SELECT * FROM dba_users_with_defpwd;
