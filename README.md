# Controles ISO 27001:2022 para la confidencialidad en Oracle 21c XE

Trabajo del curso Administración de Bases de Datos (EIF402), Universidad Nacional, II Ciclo 2026.

## Estructura del repositorio

```
artefacto_iso27001.html   Artefacto interactivo (abrir en el navegador)
/informe        Informe en PDF (exportado del documento)
/scripts        Scripts de implementación, pruebas y verificación
/evidencias     Capturas y salida de 99_verificacion.sql
README.md       Esta guía
```

## Requisitos

- Oracle Database 21c XE instalado, con la PDB XEPDB1 abierta.
- SQL Developer (para la mayoría de scripts) y SQL*Plus (para los que reinician la base).
- Unos 3 GB libres en disco para el respaldo RMAN.

Antes de empezar, abrir cada script y ajustar las líneas `DEFINE` con las rutas de tu equipo. Para ver dónde están los datafiles:

```sql
SELECT file_name FROM dba_data_files;
```

## Pasos a seguir

### 1. Preparar el entorno (Planificar)

1. Crear el repositorio Git y las carpetas de arriba.
2. Tomar una captura del estado inicial ejecutando `99_verificacion.sql` **antes** de aplicar controles. Varias secciones van a dar error o salir vacías; eso sirve como evidencia del "antes".

### 2. Aplicar los controles (Hacer)

Ejecutar en este orden. Después de cada script, revisar que no haya errores inesperados y sacar captura de la comprobación final.

| Orden | Script | Herramienta | Conexión |
| --- | --- | --- | --- |
| 1 | `00_esquema_laboratorio.sql` | SQL Developer (F5) | SYS AS SYSDBA |
| 2 | `01_identidades_autenticacion.sql` | SQL Developer (F5) | SYS AS SYSDBA |
| 3 | `02_privilegios_clasificacion.sql` | SQL Developer (F5) | SYS AS SYSDBA |
| 4 | `03_tde.sql` | **SQL*Plus** (`sqlplus / as sysdba`) | SYS AS SYSDBA |
| 5 | `04_redaccion_vpd.sql` | SQL Developer (F5) | SYS AS SYSDBA |
| 6 | `05_auditoria.sql` | SQL Developer (F5) | SYS AS SYSDBA o SEG_ADMIN |
| 7 | `07_clon_dev_enmascarado.sql` | SQL Developer (F5) | SYS AS SYSDBA |
| 8 | `08_eliminacion_segura.sql` | SQL Developer (F5) | SYS AS SYSDBA |
| 9 | `06_respaldo_cifrado.rman` | SQL*Plus + RMAN | SYS AS SYSDBA |
| 10 | `09_sqlnet_ora.txt` | Editor de texto + `lsnrctl` | — |

Notas:

- El respaldo (06) va de último a propósito: así ya incluye el clon y no incluye el tablespace viejo sin cifrar que elimina el 08.
- Para `03_tde.sql`: crear primero las carpetas `wallet` y `wallet\tde`. Guardar la clave del keystore; sin ella no se recuperan los datos cifrados.
- Para `06_respaldo_cifrado.rman`: si la base está en NOARCHIVELOG, hacer el paso previo que está en el encabezado del archivo. Luego ejecutar `rman target / @06_respaldo_cifrado.rman`.
- Para `09_sqlnet_ora.txt`: hacer copia del `sqlnet.ora` original. Si después SQL Developer no conecta, revisar `TCP.INVITED_NODES`.

### 3. Probar (Verificar)

1. Ejecutar `10_pruebas.sql` con F5. Sacar captura de cada bloque con su ID (`PR-01.png`, `PR-02.png`, ...).
2. Hacer las pruebas manuales que están al final de ese archivo (PR-07 y PR-15).
3. Ejecutar `99_verificacion.sql` conectado **por red** (no con `/ as sysdba`) para que E16 muestre el cifrado. Guardar `verificacion_controles.txt` en `/evidencias`.
4. Comparar cada resultado con la columna "Resultado esperado" del informe. Si algo salió distinto, corregir el nivel y el estado en la matriz de la sección 7.

### 4. Hallazgos (Actuar)

Revisar la sección 9 del informe. Si alguna prueba falló, agregarla como hallazgo nuevo con su acción de mejora.

### 5. Completar el informe

1. Llenar nombre y carné en la portada y en la declaración jurada.
2. Llenar las columnas "Validación" y "Fuente verificada" de la tabla de IA con lo que realmente revisaste o cambiaste. Si usaste más prompts, agregar una fila por cada uno.
3. Insertar las capturas más importantes en el informe (al menos una por control).
4. Exportar el documento a PDF y guardarlo en `/informe`.

### 6. Repositorio

```
git add .
git commit -m "Entrega controles ISO 27001 confidencialidad DBA"
git push
```

Hacer commits por etapa (scripts, evidencias, informe) para que el historial muestre el avance.

### 7. Video de 5 minutos

Guion sugerido:

| Minuto | Contenido |
| --- | --- |
| 0:00-0:45 | Objetivo, entorno (Oracle 21c XE, esquema RRHH ficticio) y ciclo PHVA |
| 0:45-1:30 | Riesgos R-CONF-01 a 05 y por qué tres son altos |
| 1:30-3:30 | Demostración en vivo: PR-01 y PR-02 (APP_VENTAS ve solo VENTAS con datos ocultos), PR-03 (JEFE_RRHH ve todo), PR-06 y PR-10 (el DBA no ve datos ni puede apagar la auditoría), PR-09 (el auditor ve los accesos) |
| 3:30-4:15 | Evidencias: E11 (tablespace cifrado), E20 (respaldo cifrado), E16 (red cifrada) |
| 4:15-5:00 | Matriz de evaluación, hallazgos y plan de mejora |

## Volver a empezar desde cero

`98_reiniciar_laboratorio.sql` borra usuarios, roles, perfil, políticas y tablespaces del laboratorio y deja XEPDB1 como antes del 00. Se puede correr aunque la instalación haya quedado a medias.

```
sqlplus / as sysdba
@98_reiniciar_laboratorio.sql
```

El keystore TDE, el modo ARCHIVELOG y el `sqlnet.ora` se mantienen. Por eso, al reinstalar, en lugar del 03 se usa `03b_tde_solo_tablespace.sql`:

```
00, 01, 02, 03b, 04, 05, 07, 08, 06 (RMAN), 10, 99
```
