-- =====================================================================
-- 04_redaccion_vpd.sql
-- Controles: A8.11 Enmascaramiento (Data Redaction), A8.3 Restricción de
-- acceso a la información (VPD / control por filas).
-- Ejecutar como SYS AS SYSDBA.
-- =====================================================================

ALTER SESSION SET CONTAINER = XEPDB1;

-- ---------- Data Redaction ----------
-- Cédula: se ocultan los primeros 5 dígitos  ->  *-****-1234
-- Salario: redacción total (se muestra 0)
-- Se aplica a toda sesión que NO tenga el rol ROL_RRHH_CONFIDENCIAL.
BEGIN
  DBMS_REDACT.ADD_POLICY(
    object_schema       => 'RRHH',
    object_name         => 'EMPLEADOS',
    policy_name         => 'RED_EMPLEADOS_CONFIDENCIAL',
    column_name         => 'CEDULA',
    function_type       => DBMS_REDACT.PARTIAL,
    function_parameters => 'VFVVVVFVVVV,V-VVVV-VVVV,*,1,5',
    expression          => 'SYS_CONTEXT(''SYS_SESSION_ROLES'',''ROL_RRHH_CONFIDENCIAL'') = ''FALSE''',
    policy_description  => 'Oculta cédula y salario a quien no tenga ROL_RRHH_CONFIDENCIAL');

  DBMS_REDACT.ALTER_POLICY(
    object_schema => 'RRHH',
    object_name   => 'EMPLEADOS',
    policy_name   => 'RED_EMPLEADOS_CONFIDENCIAL',
    action        => DBMS_REDACT.ADD_COLUMN,
    column_name   => 'SALARIO',
    function_type => DBMS_REDACT.FULL);
END;
/

-- ---------- VPD por departamento ----------
INSERT INTO rrhh.usuario_depto VALUES ('APP_VENTAS',  'VENTAS');
INSERT INTO rrhh.usuario_depto VALUES ('ANALISTA_TI', 'TI');
INSERT INTO rrhh.usuario_depto VALUES ('JEFE_RRHH',   'TODOS');
COMMIT;

-- Devuelve la condición que Oracle agrega a cada consulta sobre EMPLEADOS.
-- Usuario sin departamento asignado -> no ve ninguna fila.
CREATE OR REPLACE FUNCTION rrhh.fn_vpd_departamento (
  p_esquema IN VARCHAR2,
  p_objeto  IN VARCHAR2
) RETURN VARCHAR2
AS
  v_departamento rrhh.usuario_depto.departamento%TYPE;
BEGIN
  SELECT departamento
    INTO v_departamento
    FROM rrhh.usuario_depto
   WHERE usuario = SYS_CONTEXT('USERENV', 'SESSION_USER');

  IF v_departamento = 'TODOS' THEN
    RETURN NULL;
  END IF;

  RETURN 'departamento = ''' || v_departamento || '''';
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN '1 = 0';
END;
/

BEGIN
  DBMS_RLS.ADD_POLICY(
    object_schema   => 'RRHH',
    object_name     => 'EMPLEADOS',
    policy_name     => 'VPD_EMPLEADOS_DEPTO',
    function_schema => 'RRHH',
    policy_function => 'FN_VPD_DEPARTAMENTO',
    statement_types => 'SELECT, INSERT, UPDATE, DELETE',
    update_check    => TRUE);
END;
/

-- Comprobación
SELECT object_name, policy_name, expression, enable FROM redaction_policies;
SELECT object_name, column_name, function_type FROM redaction_columns;
SELECT object_name, policy_name, function, sel, ins, upd, del, enable
FROM dba_policies
WHERE object_owner = 'RRHH';
