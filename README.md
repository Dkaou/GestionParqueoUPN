# 🅿️ Gestión de Parqueo - Universidad Privada del Norte

## Base de Datos Avanzadas y Big Data — Evaluación T1

Sistema de gestión de parqueo universitario desarrollado en **T-SQL (SQL Server)**.

### 📋 Contenido del Proyecto

| Punto | Descripción |
|-------|-------------|
| **a)** | Diagrama de la Base de Datos |
| **b)** | Creación de la BD `GestionParqueoUPN` en T-SQL |
| **c)** | 9 tablas con restricciones (PK, FK, CHECK, UNIQUE, DEFAULT) |
| **d)** | 7 Stored Procedures para inserción de datos |
| **e)** | SP de ingreso vehicular + 3 funciones de validación |
| **f)** | 3 Triggers de auditoría (Usuarios, Vehículos, Pagos) |
| **g)** | Trigger para actualizar estado del espacio de parqueo |
| **h)** | Trigger para calcular total a pagar por infracciones |
| **i)** | Cursor para detectar permanencia excedida (+12h → multa S/20) |

### 🗂️ Tablas

- `Usuarios` — Gestión de usuarios (Estudiante, Docente, Personal Administrativo, Visitante)
- `Vehiculos` — Registro de vehículos (Automóvil, Motocicleta, Bicicleta, Vehículo Eléctrico)
- `ZonasParqueo` — Zonas del campus
- `EspaciosParqueo` — Plazas individuales (Estándar, Discapacitados, Carga Eléctrica)
- `Tickets` — Control de acceso con duración calculada
- `Infracciones` — Registro de infracciones
- `Sanciones` — Multas y suspensiones
- `Pagos` — Registro de pagos de multas
- `Historial_Auditoria` — Auditoría de cambios

### 🚀 Cómo ejecutar

1. Abrir **SQL Server Management Studio (SSMS)**
2. Abrir el archivo `GestionParqueoUPN.sql`
3. Presionar **F5** para ejecutar
4. El script crea automáticamente la BD, tablas, objetos y datos de prueba

### 🛠️ Tecnologías

- SQL Server 2017+
- T-SQL
- SQL Server Management Studio (SSMS)
