-- =====================================================================
-- 03b_tde_solo_tablespace.sql
-- Se usa EN LUGAR del 03 cuando se reinstala después de 98_reiniciar_laboratorio.sql.
-- El keystore ya existe y abre solo (auto-login), así que no se reinicia la base:
-- solo se crea el tablespace cifrado y se mueven las tablas.
-- Ejecutar en SQL*Plus como SYS AS SYSDBA, después del 02.
-- =====================================================================

DEFINE ruta_datafiles = 'C:\APP\JOSGU\PRODUCT\21C\ORADATA\XE\XEPDB1'

-- El keystore debe aparecer OPEN en todos los contenedores.
-- Si sale CLOSED, abrirlo desde CDB$ROOT con:
--   ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "Ks#Lab2026!Tde" CONTAINER = ALL;
SELECT con_id, status, wallet_type FROM v$encryption_wallet;

ALTER SESSION SET CONTAINER = XEPDB1;

CREATE TABLESPACE rrhh_seguro
  DATAFILE '&ruta_datafiles\rrhh_seguro01.dbf' SIZE 50M REUSE
  AUTOEXTEND ON NEXT 10M MAXSIZE 300M
  ENCRYPTION USING 'AES256' ENCRYPT;

ALTER USER rrhh QUOTA UNLIMITED ON rrhh_seguro;
ALTER USER rrhh DEFAULT TABLESPACE rrhh_seguro;

ALTER TABLE rrhh.empleados     MOVE TABLESPACE rrhh_seguro;
ALTER TABLE rrhh.usuario_depto MOVE TABLESPACE rrhh_seguro;
ALTER INDEX rrhh.empleados_pk     REBUILD TABLESPACE rrhh_seguro;
ALTER INDEX rrhh.usuario_depto_pk REBUILD TABLESPACE rrhh_seguro;

-- Comprobación: RRHH_SEGURO con AES256 y las 4 piezas de RRHH en él
SELECT t.name AS tablespace, e.encryptionalg, e.encryptedts
FROM v$encrypted_tablespaces e
JOIN v$tablespace t ON t.ts# = e.ts# AND t.con_id = e.con_id;

SELECT segment_name, tablespace_name
FROM dba_segments
WHERE owner = 'RRHH';
