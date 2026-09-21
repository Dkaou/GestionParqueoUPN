# 🅿️ Gestión de Parqueo UPN — Guía de Exposición (Evaluación T1)

Esta guía resume todo el proyecto para que puedas **exponerlo y explicarlo paso a paso** a tu profesor. 

---

## 1. El Diagrama de la Base de Datos (Punto A)

El sistema está diseñado en **8 tablas principales** enfocadas en registrar quién entra, con qué vehículo, dónde se cuadra y qué pasa si comete una infracción.

* **El Núcleo:** `Usuarios` y `Vehiculos`. Un usuario puede tener varios vehículos.
* **El Estacionamiento:** `ZonasParqueo` y `EspaciosParqueo`. Las zonas (ej. "Norte") tienen espacios específicos (ej. "N-01").
* **La Transacción (El Ticket):** Cuando un vehículo entra a un espacio, se genera un `Ticket`. El ticket une al vehículo con el espacio y registra su hora de entrada/salida.
* **Las Penalidades:** Si alguien incumple, el ticket se asocia a `Infracciones`. Estas infracciones generan `Sanciones` (multas o suspensiones) que luego se cancelan mediante `Pagos`.

---

## 2. Creación de la BD y Tablas (Puntos B y C)

Diseñamos la base de datos con **integridad referencial (PKs y FKs)** y **restricciones lógicas (CHECK y UNIQUE)**.

* **Ejemplos clave a mencionar:**
  * **Usuarios:** El DNI es CHAR(8) y es la Llave Primaria (PK). El correo tiene restricción `UNIQUE` (no se repite).
  * **Tickets:** Tiene una columna computada (`DuracionMinutos`) que calcula automáticamente el tiempo usando `DATEDIFF` entre el ingreso y la salida.
  * **Espacios:** Tiene restricción `CHECK` para que el estado solo sea "Disponible", "Ocupado" o "Mantenimiento".

---

## 3. Stored Procedures de Inserción (Punto D)

Se crearon **7 Procedimientos Almacenados (SP)** para insertar datos en las tablas base.
* **Por qué son importantes:** No insertamos datos a ciegas. Por ejemplo, `sp_InsertarUsuario` verifica primero si el DNI ya existe; si existe, lanza un error personalizado en vez de que el sistema "reviente". Lo mismo con vehículos (revisa que la placa no exista).
* **Control de Errores:** Todos usan bloques `TRY...CATCH` para manejar las excepciones de forma elegante.

---

## 4. El SP Estrella: Registro de Ingreso (Punto E)

Este es el proceso más complejo. El SP `sp_RegistrarIngresoVehicular` usa **3 Funciones Escalares** para hacer 5 validaciones antes de dejar entrar a un carro:

1. **¿Existe el carro?** Verifica que la placa esté registrada.
2. **¿Ya está adentro?** Revisa que no tenga un ticket abierto sin salida.
3. **¿Tiene deuda?** Llama a las funciones `fn_TieneDeudas` y `fn_MontoDeudas`. Si debe, **NO ENTRA**.
4. **¿Está suspendido?** Llama a `fn_TieneSuspension`. Si está suspendido, **NO ENTRA**.
5. **¿Hay espacio?** Busca el primer espacio disponible que coincida con su tipo de vehículo (Auto/Moto). Si no hay, avisa que está lleno.
6. Si pasa todo, le genera el Ticket.

---

## 5. Triggers de Auditoría (Punto F)

El sistema vigila lo que pasa. Tenemos triggers en `Usuarios`, `Vehiculos` y `Pagos` que escuchan eventos `INSERT`, `UPDATE` y `DELETE`.
* **Cómo funcionan:** Cuando algo cambia, el trigger guarda un registro en la tabla `Historial_Auditoria`. Guarda la tabla afectada, la operación, y **transforma los datos viejos y nuevos a formato XML** para tener la foto exacta de qué cambió, quién lo hizo y a qué hora.

---

## 6. Trigger: Estado del Espacio Automático (Punto G)

El usuario del sistema no debe cambiar manualmente si el espacio está ocupado o no.
* **Cómo funciona:** El trigger `trg_ActualizarEstadoEspacio` se activa cuando se inserta o actualiza un Ticket. 
  * Si se inserta (entra carro) ➡️ Cambia el espacio a "Ocupado".
  * Si se actualiza con FechaHoraSalida (sale carro) ➡️ Cambia el espacio a "Disponible".

---

## 7. Trigger: Total a Pagar (Punto H)

Cuando a un alumno le ponen una infracción, el trigger `trg_CalcularTotalPagar` salta inmediatamente.
* **Cómo funciona:** Suma todas las deudas activas que tiene ese alumno por multas impagas y lanza un `PRINT` que notifica el total de la deuda acumulada actual.

---

## 8. El Cursor: Permanencia Excedida (Punto I)

A veces los alumnos dejan el carro más de 12 horas.
* **Cómo funciona:** El SP `sp_ProcesarPermanenciaExcedida` usa un **CURSOR**. Este cursor recorre (fila por fila) todos los tickets que no tienen hora de salida. Calcula las horas y, si son más de 12, automáticamente le inserta una Infracción por "Permanencia excedida" de S/ 20.00. (Además, verifica no cobrarle dos veces por el mismo ticket).

---

## 🚀 Resumen para impresionar al profesor
> *"Profesor, el sistema no es solo un registro de datos. Es un sistema reactivo. Usa **Procedimientos Almacenados** para validar la integridad antes de insertar, usa **Funciones** modulares para consultar deudas y suspensiones que alimentan el SP principal de ingreso, y usa **Triggers** y **Cursores** para automatizar el estado de los espacios, la auditoría en XML y la penalización automática, garantizando que todo el proceso del estacionamiento funcione por sí solo."*
