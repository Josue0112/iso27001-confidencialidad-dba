-- =====================================================================
-- 03_tde.sql
-- Cifrado en reposo con Transparent Data Encryption.
-- Controles: A8.12 Prevención de fuga de datos (complementario A8.24 Criptografía).
--
-- IMPORTANTE: ejecutar en SQL*Plus como SYS AS SYSDBA, porque hay que
-- reiniciar la base y SQL Developer no ejecuta SHUTDOWN/STARTUP.
--   sqlplus / as sysdba
--
-- ANTES de empezar, crear en el sistema operativo las carpetas:
--   C:\APP\JOSGU\PRODUCT\21C\ADMIN\XE\WALLET
--   C:\APP\JOSGU\PRODUCT\21C\ADMIN\XE\WALLET\TDE
-- (ajustar la ruta a tu equipo; debe coincidir con ruta_wallet)
-- =====================================================================

DEFINE ruta_wallet     = 'C:\APP\JOSGU\PRODUCT\21C\ADMIN\XE\WALLET'
DEFINE ruta_datafiles  = 'C:\APP\JOSGU\PRODUCT\21C\ORADATA\XE\XEPDB1'
DEFINE clave_keystore  = 'Ks#Lab2026!Tde'

-- ---------------- PARTE A: configuración en CDB$ROOT ----------------
ALTER SESSION SET CONTAINER = CDB$ROOT;

ALTER SYSTEM SET WALLET_ROOT = '&ruta_wallet' SCOPE = SPFILE;

SHUTDOWN IMMEDIATE
STARTUP
ALTER PLUGGABLE DATABASE ALL OPEN;

ALTER SYSTEM SET TDE_CONFIGURATION = 'KEYSTORE_CONFIGURATION=FILE' SCOPE = BOTH;

-- Crear el keystore, abrirlo y generar la clave maestra para todos los contenedores
ADMINISTER KEY MANAGEMENT CREATE KEYSTORE IDENTIFIED BY "&clave_keystore";
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "&clave_keystore" CONTAINER = ALL;
ADMINISTER KEY MANAGEMENT SET KEY IDENTIFIED BY "&clave_keystore" WITH BACKUP CONTAINER = ALL;

-- Keystore de apertura automática para que la base arranque sin pedir clave.
-- (Riesgo aceptado en laboratorio; ver hallazgo H-05 del informe.)
ADMINISTER KEY MANAGEMENT CREATE AUTO_LOGIN KEYSTORE FROM KEYSTORE IDENTIFIED BY "&clave_keystore";

SELECT con_id, wrl_type, status, wallet_type FROM v$encryption_wallet;

-- ---------------- PARTE B: tablespace cifrado en XEPDB1 ----------------
ALTER SESSION SET CONTAINER = XEPDB1;

CREATE TABLESPACE rrhh_seguro
  DATAFILE '&ruta_datafiles\rrhh_seguro01.dbf' SIZE 50M REUSE
  AUTOEXTEND ON NEXT 10M MAXSIZE 300M
  ENCRYPTION USING 'AES256' ENCRYPT;

ALTER USER rrhh QUOTA UNLIMITED ON rrhh_seguro;
ALTER USER rrhh DEFAULT TABLESPACE rrhh_seguro;

-- Mover tablas e índices al tablespace cifrado
ALTER TABLE rrhh.empleados     MOVE TABLESPACE rrhh_seguro;
ALTER TABLE rrhh.usuario_depto MOVE TABLESPACE rrhh_seguro;
ALTER INDEX rrhh.empleados_pk     REBUILD TABLESPACE rrhh_seguro;
ALTER INDEX rrhh.usuario_depto_pk REBUILD TABLESPACE rrhh_seguro;

-- Comprobación: RRHH_SEGURO debe aparecer con AES256
SELECT t.name AS tablespace, e.encryptionalg, e.encryptedts
FROM v$encrypted_tablespaces e
JOIN v$tablespace t ON t.ts# = e.ts# AND t.con_id = e.con_id;

SELECT segment_name, tablespace_name
FROM dba_segments
WHERE owner = 'RRHH';
