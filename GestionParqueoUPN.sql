-- =============================================
-- BASE DE DATOS AVANZADAS Y BIG DATA
-- EVALUACIÓN T1
-- CASO: GESTIÓN DE PARQUEO DE LA UNIVERSIDAD
-- Universidad Privada del Norte
-- =============================================

-- =============================================
-- a) & b) CREAR LA BASE DE DATOS EN T-SQL
-- =============================================
USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'GestionParqueoUPN')
BEGIN
    ALTER DATABASE GestionParqueoUPN SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GestionParqueoUPN;
END
GO

CREATE DATABASE GestionParqueoUPN;
GO

-- Habilitar la creacion de diagramas de base de datos
ALTER AUTHORIZATION ON DATABASE::GestionParqueoUPN TO [sa];
GO

USE GestionParqueoUPN;
GO

-- =============================================
-- c) CREAR TABLAS CON SUS RESTRICCIONES
-- =============================================

-- -----------------------------------------------
-- Tabla 1: USUARIOS (RF-01)
-- -----------------------------------------------
CREATE TABLE Usuarios (
    DNI                  CHAR(8)       NOT NULL,
    NombreCompleto       VARCHAR(150)  NOT NULL,
    CorreoInstitucional  VARCHAR(100)  NOT NULL,
    Telefono             VARCHAR(15)   NULL,
    TipoUsuario          VARCHAR(30)   NOT NULL,
    Estado               VARCHAR(10)   NOT NULL DEFAULT 'Activo',

    CONSTRAINT PK_Usuarios              PRIMARY KEY (DNI),
    CONSTRAINT UQ_Usuarios_Correo       UNIQUE (CorreoInstitucional),
    CONSTRAINT CHK_Usuarios_DNI         CHECK (LEN(DNI) = 8 AND DNI NOT LIKE '%[^0-9]%'),
    CONSTRAINT CHK_Usuarios_Tipo        CHECK (TipoUsuario IN ('Estudiante', 'Docente', 'Personal Administrativo', 'Visitante')),
    CONSTRAINT CHK_Usuarios_Estado      CHECK (Estado IN ('Activo', 'Inactivo'))
);
GO

-- -----------------------------------------------
-- Tabla 2: VEHICULOS (RF-02)
-- -----------------------------------------------
CREATE TABLE Vehiculos (
    Placa           VARCHAR(10)   NOT NULL,
    Marca           VARCHAR(50)   NOT NULL,
    Modelo          VARCHAR(50)   NOT NULL,
    Color           VARCHAR(30)   NOT NULL,
    TipoVehiculo    VARCHAR(25)   NOT NULL,
    DNI_Usuario     CHAR(8)       NOT NULL,

    CONSTRAINT PK_Vehiculos             PRIMARY KEY (Placa),
    CONSTRAINT FK_Vehiculos_Usuario     FOREIGN KEY (DNI_Usuario) REFERENCES Usuarios(DNI),
    CONSTRAINT CHK_Vehiculos_Tipo       CHECK (TipoVehiculo IN ('Automovil', 'Motocicleta', 'Bicicleta', 'Vehiculo Electrico'))
);
GO

-- -----------------------------------------------
-- Tabla 3: ZONAS DE PARQUEO (RF-03)
-- -----------------------------------------------
CREATE TABLE ZonasParqueo (
    IdZona           INT IDENTITY(1,1)  NOT NULL,
    Nombre           VARCHAR(100)       NOT NULL,
    UbicacionFisica  VARCHAR(200)       NOT NULL,
    CapacidadTotal   INT                NOT NULL,

    CONSTRAINT PK_ZonasParqueo              PRIMARY KEY (IdZona),
    CONSTRAINT UQ_ZonasParqueo_Nombre       UNIQUE (Nombre),
    CONSTRAINT CHK_ZonasParqueo_Capacidad   CHECK (CapacidadTotal > 0)
);
GO

-- -----------------------------------------------
-- Tabla 4: ESPACIOS DE PARQUEO (RF-03)
-- -----------------------------------------------
CREATE TABLE EspaciosParqueo (
    IdEspacio       INT IDENTITY(1,1)  NOT NULL,
    CodigoEspacio   VARCHAR(20)        NOT NULL,
    TipoEspacio     VARCHAR(25)        NOT NULL,
    Estado          VARCHAR(20)        NOT NULL DEFAULT 'Disponible',
    IdZona          INT                NOT NULL,

    CONSTRAINT PK_EspaciosParqueo           PRIMARY KEY (IdEspacio),
    CONSTRAINT UQ_EspaciosParqueo_Codigo    UNIQUE (CodigoEspacio),
    CONSTRAINT FK_EspaciosParqueo_Zona      FOREIGN KEY (IdZona) REFERENCES ZonasParqueo(IdZona),
    CONSTRAINT CHK_EspaciosParqueo_Tipo     CHECK (TipoEspacio IN ('Estandar', 'Discapacitados', 'Carga Electrica')),
    CONSTRAINT CHK_EspaciosParqueo_Estado   CHECK (Estado IN ('Disponible', 'Ocupado', 'Mantenimiento'))
);
GO

-- -----------------------------------------------
-- Tabla 5: TICKETS DE ACCESO (RF-04)
-- -----------------------------------------------
CREATE TABLE Tickets (
    IdTicket          INT IDENTITY(1,1)  NOT NULL,
    FechaHoraIngreso  DATETIME           NOT NULL DEFAULT GETDATE(),
    FechaHoraSalida   DATETIME           NULL,
    DuracionMinutos   AS DATEDIFF(MINUTE, FechaHoraIngreso, FechaHoraSalida),
    Placa_Vehiculo    VARCHAR(10)        NOT NULL,
    IdEspacio         INT                NOT NULL,

    CONSTRAINT PK_Tickets                PRIMARY KEY (IdTicket),
    CONSTRAINT FK_Tickets_Vehiculo       FOREIGN KEY (Placa_Vehiculo) REFERENCES Vehiculos(Placa),
    CONSTRAINT FK_Tickets_Espacio        FOREIGN KEY (IdEspacio) REFERENCES EspaciosParqueo(IdEspacio),
    CONSTRAINT CHK_Tickets_Fechas        CHECK (FechaHoraSalida IS NULL OR FechaHoraSalida >= FechaHoraIngreso)
);
GO

-- -----------------------------------------------
-- Tabla 6: INFRACCIONES (RF-05)
-- -----------------------------------------------
CREATE TABLE Infracciones (
    IdInfraccion     INT IDENTITY(1,1)  NOT NULL,
    Descripcion      VARCHAR(300)       NOT NULL,
    FechaInfraccion  DATETIME           NOT NULL DEFAULT GETDATE(),
    DNI_Usuario      CHAR(8)            NOT NULL,
    IdTicket         INT                NULL,

    CONSTRAINT PK_Infracciones               PRIMARY KEY (IdInfraccion),
    CONSTRAINT FK_Infracciones_Usuario       FOREIGN KEY (DNI_Usuario) REFERENCES Usuarios(DNI),
    CONSTRAINT FK_Infracciones_Ticket        FOREIGN KEY (IdTicket) REFERENCES Tickets(IdTicket)
);
GO

-- -----------------------------------------------
-- Tabla 7: SANCIONES (RF-05)
-- -----------------------------------------------
CREATE TABLE Sanciones (
    IdSancion      INT IDENTITY(1,1)  NOT NULL,
    TipoSancion    VARCHAR(20)        NOT NULL,
    MontoMulta     DECIMAL(10,2)      NULL,
    FechaInicio    DATETIME           NOT NULL DEFAULT GETDATE(),
    FechaFin       DATETIME           NULL,
    Estado         VARCHAR(20)        NOT NULL DEFAULT 'Pendiente',
    IdInfraccion   INT                NOT NULL,

    CONSTRAINT PK_Sanciones                  PRIMARY KEY (IdSancion),
    CONSTRAINT FK_Sanciones_Infraccion       FOREIGN KEY (IdInfraccion) REFERENCES Infracciones(IdInfraccion),
    CONSTRAINT CHK_Sanciones_Tipo            CHECK (TipoSancion IN ('Multa', 'Suspension')),
    CONSTRAINT CHK_Sanciones_Estado          CHECK (Estado IN ('Pendiente', 'Pagada', 'Cumplida'))
);
GO

-- -----------------------------------------------
-- Tabla 8: PAGOS (RF-05)
-- -----------------------------------------------
CREATE TABLE Pagos (
    IdPago          INT IDENTITY(1,1)  NOT NULL,
    FechaPago       DATETIME           NOT NULL DEFAULT GETDATE(),
    Monto           DECIMAL(10,2)      NOT NULL,
    TipoPago        VARCHAR(30)        NOT NULL,
    PersonalRecibio VARCHAR(150)       NOT NULL,
    IdSancion       INT                NOT NULL,

    CONSTRAINT PK_Pagos                  PRIMARY KEY (IdPago),
    CONSTRAINT FK_Pagos_Sancion          FOREIGN KEY (IdSancion) REFERENCES Sanciones(IdSancion),
    CONSTRAINT CHK_Pagos_Monto           CHECK (Monto > 0),
    CONSTRAINT CHK_Pagos_TipoPago        CHECK (TipoPago IN ('Efectivo', 'Tarjeta', 'Transferencia'))
);
GO

-- -----------------------------------------------
-- Tabla 9: HISTORIAL DE AUDITORIA (para trigger f)
-- -----------------------------------------------
CREATE TABLE Historial_Auditoria (
    IdHistorial      INT IDENTITY(1,1)  NOT NULL,
    TablaAfectada    VARCHAR(50)        NOT NULL,
    Operacion        VARCHAR(10)        NOT NULL,
    DatosAnteriores  NVARCHAR(MAX)      NULL,
    DatosNuevos      NVARCHAR(MAX)      NULL,
    UsuarioSistema   VARCHAR(128)       NOT NULL DEFAULT SYSTEM_USER,
    FechaOperacion   DATETIME           NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_Historial              PRIMARY KEY (IdHistorial),
    CONSTRAINT CHK_Historial_Operacion   CHECK (Operacion IN ('INSERT', 'UPDATE', 'DELETE'))
);
GO

PRINT '========================================';
PRINT 'Tablas creadas exitosamente.';
PRINT '========================================';
GO


-- =============================================
-- d) PROCEDIMIENTOS ALMACENADOS PARA INSERTAR
--    DATOS EN CADA UNA DE LAS TABLAS
-- =============================================

-- -----------------------------------------------
-- SP 1: Insertar Usuario
-- -----------------------------------------------
CREATE PROCEDURE sp_InsertarUsuario
    @DNI                 CHAR(8),
    @NombreCompleto      VARCHAR(150),
    @CorreoInstitucional VARCHAR(100),
    @Telefono            VARCHAR(15) = NULL,
    @TipoUsuario         VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM Usuarios WHERE DNI = @DNI)
        BEGIN
            RAISERROR('El usuario con DNI %s ya existe.', 16, 1, @DNI);
            RETURN;
        END

        INSERT INTO Usuarios (DNI, NombreCompleto, CorreoInstitucional, Telefono, TipoUsuario)
        VALUES (@DNI, @NombreCompleto, @CorreoInstitucional, @Telefono, @TipoUsuario);

        PRINT 'Usuario registrado exitosamente: ' + @NombreCompleto;
    END TRY
    BEGIN CATCH
        PRINT 'Error al registrar usuario: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- -----------------------------------------------
-- SP 2: Insertar Vehiculo
-- -----------------------------------------------
CREATE PROCEDURE sp_InsertarVehiculo
    @Placa        VARCHAR(10),
    @Marca        VARCHAR(50),
    @Modelo       VARCHAR(50),
    @Color        VARCHAR(30),
    @TipoVehiculo VARCHAR(25),
    @DNI_Usuario  CHAR(8)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Usuarios WHERE DNI = @DNI_Usuario)
        BEGIN
            RAISERROR('El usuario con DNI %s no existe.', 16, 1, @DNI_Usuario);
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM Vehiculos WHERE Placa = @Placa)
        BEGIN
            RAISERROR('El vehiculo con placa %s ya existe.', 16, 1, @Placa);
            RETURN;
        END

        INSERT INTO Vehiculos (Placa, Marca, Modelo, Color, TipoVehiculo, DNI_Usuario)
        VALUES (@Placa, @Marca, @Modelo, @Color, @TipoVehiculo, @DNI_Usuario);

        PRINT 'Vehiculo registrado exitosamente: ' + @Placa;
    END TRY
    BEGIN CATCH
        PRINT 'Error al registrar vehiculo: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- -----------------------------------------------
-- SP 3: Insertar Zona de Parqueo
-- -----------------------------------------------
CREATE PROCEDURE sp_InsertarZonaParqueo
    @Nombre          VARCHAR(100),
    @UbicacionFisica VARCHAR(200),
    @CapacidadTotal  INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO ZonasParqueo (Nombre, UbicacionFisica, CapacidadTotal)
        VALUES (@Nombre, @UbicacionFisica, @CapacidadTotal);

        PRINT 'Zona de parqueo registrada: ' + @Nombre;
    END TRY
    BEGIN CATCH
        PRINT 'Error al registrar zona: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- -----------------------------------------------
-- SP 4: Insertar Espacio de Parqueo
-- -----------------------------------------------
CREATE PROCEDURE sp_InsertarEspacioParqueo
    @CodigoEspacio VARCHAR(20),
    @TipoEspacio   VARCHAR(25),
    @IdZona        INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM ZonasParqueo WHERE IdZona = @IdZona)
        BEGIN
            RAISERROR('La zona de parqueo con Id %d no existe.', 16, 1, @IdZona);
            RETURN;
        END

        INSERT INTO EspaciosParqueo (CodigoEspacio, TipoEspacio, IdZona)
        VALUES (@CodigoEspacio, @TipoEspacio, @IdZona);

        PRINT 'Espacio de parqueo registrado: ' + @CodigoEspacio;
    END TRY
    BEGIN CATCH
        PRINT 'Error al registrar espacio: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- -----------------------------------------------
-- SP 5: Insertar Infraccion
-- -----------------------------------------------
CREATE PROCEDURE sp_InsertarInfraccion
    @Descripcion  VARCHAR(300),
    @DNI_Usuario  CHAR(8),
    @IdTicket     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Usuarios WHERE DNI = @DNI_Usuario)
        BEGIN
            RAISERROR('El usuario con DNI %s no existe.', 16, 1, @DNI_Usuario);
            RETURN;
        END

        INSERT INTO Infracciones (Descripcion, FechaInfraccion, DNI_Usuario, IdTicket)
        VALUES (@Descripcion, GETDATE(), @DNI_Usuario, @IdTicket);

        PRINT 'Infraccion registrada para usuario: ' + @DNI_Usuario;
    END TRY
    BEGIN CATCH
        PRINT 'Error al registrar infraccion: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- -----------------------------------------------
-- SP 6: Insertar Sancion
-- -----------------------------------------------
CREATE PROCEDURE sp_InsertarSancion
    @TipoSancion   VARCHAR(20),
    @MontoMulta     DECIMAL(10,2) = NULL,
    @IdInfraccion   INT,
    @FechaFin       DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Infracciones WHERE IdInfraccion = @IdInfraccion)
        BEGIN
            RAISERROR('La infraccion con Id %d no existe.', 16, 1, @IdInfraccion);
            RETURN;
        END

        INSERT INTO Sanciones (TipoSancion, MontoMulta, FechaInicio, FechaFin, Estado, IdInfraccion)
        VALUES (@TipoSancion, @MontoMulta, GETDATE(), @FechaFin, 'Pendiente', @IdInfraccion);

        PRINT 'Sancion registrada exitosamente.';
    END TRY
    BEGIN CATCH
        PRINT 'Error al registrar sancion: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- -----------------------------------------------
-- SP 7: Insertar Pago
-- -----------------------------------------------
CREATE PROCEDURE sp_InsertarPago
    @Monto           DECIMAL(10,2),
    @TipoPago         VARCHAR(30),
    @PersonalRecibio  VARCHAR(150),
    @IdSancion        INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Sanciones WHERE IdSancion = @IdSancion AND TipoSancion = 'Multa')
        BEGIN
            RAISERROR('La sancion con Id %d no existe o no es de tipo Multa.', 16, 1, @IdSancion);
            RETURN;
        END

        INSERT INTO Pagos (FechaPago, Monto, TipoPago, PersonalRecibio, IdSancion)
        VALUES (GETDATE(), @Monto, @TipoPago, @PersonalRecibio, @IdSancion);

        -- Actualizar estado de la sancion a Pagada
        UPDATE Sanciones SET Estado = 'Pagada' WHERE IdSancion = @IdSancion;

        PRINT 'Pago registrado exitosamente por S/ ' + CAST(@Monto AS VARCHAR);
    END TRY
    BEGIN CATCH
        PRINT 'Error al registrar pago: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

PRINT '========================================';
PRINT 'Stored Procedures de insercion creados.';
PRINT '========================================';
GO


-- =============================================
-- e) PROCEDIMIENTO ALMACENADO PARA REGISTRAR
--    INGRESO VEHICULAR A LA COCHERA
--    (con funciones para evaluar deudas y montos)
-- =============================================

-- -----------------------------------------------
-- FUNCION 1: Verificar si el usuario tiene deudas
-- -----------------------------------------------
CREATE FUNCTION fn_TieneDeudas (@DNI CHAR(8))
RETURNS BIT
AS
BEGIN
    DECLARE @Resultado BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Sanciones s
        INNER JOIN Infracciones i ON s.IdInfraccion = i.IdInfraccion
        WHERE i.DNI_Usuario = @DNI
          AND s.TipoSancion = 'Multa'
          AND s.Estado = 'Pendiente'
    )
        SET @Resultado = 1;

    RETURN @Resultado;
END;
GO

-- -----------------------------------------------
-- FUNCION 2: Calcular monto total de deudas
-- -----------------------------------------------
CREATE FUNCTION fn_MontoDeudas (@DNI CHAR(8))
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Total DECIMAL(10,2);

    SELECT @Total = ISNULL(SUM(s.MontoMulta), 0)
    FROM Sanciones s
    INNER JOIN Infracciones i ON s.IdInfraccion = i.IdInfraccion
    WHERE i.DNI_Usuario = @DNI
      AND s.TipoSancion = 'Multa'
      AND s.Estado = 'Pendiente';

    RETURN @Total;
END;
GO

-- -----------------------------------------------
-- FUNCION 3: Verificar suspension activa
-- -----------------------------------------------
CREATE FUNCTION fn_TieneSuspension (@DNI CHAR(8))
RETURNS BIT
AS
BEGIN
    DECLARE @Resultado BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Sanciones s
        INNER JOIN Infracciones i ON s.IdInfraccion = i.IdInfraccion
        WHERE i.DNI_Usuario = @DNI
          AND s.TipoSancion = 'Suspension'
          AND s.Estado = 'Pendiente'
    )
        SET @Resultado = 1;

    RETURN @Resultado;
END;
GO

-- -----------------------------------------------
-- SP PRINCIPAL: Registrar Ingreso Vehicular
-- -----------------------------------------------
CREATE PROCEDURE sp_RegistrarIngresoVehicular
    @Placa VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @DNI_Usuario   CHAR(8);
        DECLARE @TipoVehiculo  VARCHAR(25);
        DECLARE @IdEspacio     INT;
        DECLARE @MontoDeuda    DECIMAL(10,2);

        -- ====== VALIDACION 1: Verificar que el vehiculo existe ======
        SELECT @DNI_Usuario = DNI_Usuario, @TipoVehiculo = TipoVehiculo
        FROM Vehiculos
        WHERE Placa = @Placa;

        IF @DNI_Usuario IS NULL
        BEGIN
            RAISERROR('ERROR: El vehiculo con placa %s no esta registrado en el sistema.', 16, 1, @Placa);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- ====== VALIDACION 2: El usuario solo puede tener UN vehiculo ingresado ======
        IF EXISTS (
            SELECT 1
            FROM Tickets t
            INNER JOIN Vehiculos v ON t.Placa_Vehiculo = v.Placa
            WHERE v.DNI_Usuario = @DNI_Usuario
              AND t.FechaHoraSalida IS NULL  -- Ticket abierto = vehiculo dentro
        )
        BEGIN
            RAISERROR('ERROR: El usuario con DNI %s ya tiene un vehiculo ingresado. No puede ingresar mas de uno.', 16, 1, @DNI_Usuario);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- ====== VALIDACION 3: Verificar deudas pendientes (usando FUNCIONES) ======
        IF dbo.fn_TieneDeudas(@DNI_Usuario) = 1
        BEGIN
            SET @MontoDeuda = dbo.fn_MontoDeudas(@DNI_Usuario);
            DECLARE @MsgDeuda VARCHAR(200) = 'ERROR: El usuario tiene deudas pendientes por S/ ' + CAST(@MontoDeuda AS VARCHAR(20)) + '. No se permite el ingreso.';
            RAISERROR(@MsgDeuda, 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- ====== VALIDACION 4: Verificar suspensiones activas (usando FUNCION) ======
        IF dbo.fn_TieneSuspension(@DNI_Usuario) = 1
        BEGIN
            RAISERROR('ERROR: El usuario con DNI %s tiene una suspension activa del servicio de parqueo.', 16, 1, @DNI_Usuario);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- ====== VALIDACION 5: Buscar espacio disponible segun tipo de vehiculo ======
        SELECT TOP 1 @IdEspacio = e.IdEspacio
        FROM EspaciosParqueo e
        INNER JOIN ZonasParqueo z ON e.IdZona = z.IdZona
        WHERE e.Estado = 'Disponible'
          AND (
              (@TipoVehiculo = 'Automovil'          AND z.Nombre LIKE '%vehiculo%')
           OR (@TipoVehiculo = 'Motocicleta'        AND z.Nombre LIKE '%moto%')
           OR (@TipoVehiculo = 'Bicicleta'          AND z.Nombre LIKE '%bicicleta%')
           OR (@TipoVehiculo = 'Vehiculo Electrico' AND e.TipoEspacio = 'Carga Electrica')
          )
        ORDER BY e.IdEspacio;

        -- Si no hay espacio en zona especifica, buscar en cualquier zona disponible
        IF @IdEspacio IS NULL
        BEGIN
            SELECT TOP 1 @IdEspacio = IdEspacio
            FROM EspaciosParqueo
            WHERE Estado = 'Disponible'
            ORDER BY IdEspacio;
        END

        -- Si aun no hay espacio -> ALERTA
        IF @IdEspacio IS NULL
        BEGIN
            DECLARE @MsgEspacio VARCHAR(200) = 'ALERTA: No hay espacios disponibles para el tipo de vehiculo: ' + @TipoVehiculo + '.';
            RAISERROR(@MsgEspacio, 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- ====== REGISTRAR EL TICKET DE INGRESO ======
        INSERT INTO Tickets (FechaHoraIngreso, Placa_Vehiculo, IdEspacio)
        VALUES (GETDATE(), @Placa, @IdEspacio);

        -- Nota: El TRIGGER trg_ActualizarEstadoEspacio (punto g) se encargara
        -- de cambiar el estado del espacio a 'Ocupado' automaticamente.

        COMMIT TRANSACTION;

        PRINT '========================================';
        PRINT 'INGRESO VEHICULAR REGISTRADO CON EXITO';
        PRINT 'Placa: ' + @Placa;
        PRINT 'Espacio asignado: ' + CAST(@IdEspacio AS VARCHAR);
        PRINT 'Fecha/Hora: ' + CONVERT(VARCHAR, GETDATE(), 120);
        PRINT '========================================';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error en ingreso vehicular: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

PRINT '========================================';
PRINT 'SP de ingreso vehicular y funciones creados.';
PRINT '========================================';
GO


-- =============================================
-- f) TRIGGER DE AUDITORIA / HISTORIAL
--    Guarda historial de INSERT, UPDATE, DELETE
--    en tablas: Usuarios, Vehiculos y Pagos
-- =============================================

-- -----------------------------------------------
-- Trigger Auditoria en USUARIOS
-- -----------------------------------------------
CREATE TRIGGER trg_Auditoria_Usuarios
ON Usuarios
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Operacion VARCHAR(10);
    DECLARE @DatosAnteriores NVARCHAR(MAX) = NULL;
    DECLARE @DatosNuevos NVARCHAR(MAX) = NULL;

    -- Determinar tipo de operacion
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        SET @Operacion = 'UPDATE';
    ELSE IF EXISTS (SELECT 1 FROM inserted)
        SET @Operacion = 'INSERT';
    ELSE
        SET @Operacion = 'DELETE';

    -- Capturar datos anteriores (UPDATE o DELETE)
    IF @Operacion IN ('UPDATE', 'DELETE')
    BEGIN
        SELECT @DatosAnteriores = (
            SELECT DNI, NombreCompleto, CorreoInstitucional, Telefono, TipoUsuario, Estado
            FROM deleted
            FOR XML PATH('Usuario'), ROOT('Datos')
        );
    END

    -- Capturar datos nuevos (INSERT o UPDATE)
    IF @Operacion IN ('INSERT', 'UPDATE')
    BEGIN
        SELECT @DatosNuevos = (
            SELECT DNI, NombreCompleto, CorreoInstitucional, Telefono, TipoUsuario, Estado
            FROM inserted
            FOR XML PATH('Usuario'), ROOT('Datos')
        );
    END

    INSERT INTO Historial_Auditoria (TablaAfectada, Operacion, DatosAnteriores, DatosNuevos)
    VALUES ('Usuarios', @Operacion, @DatosAnteriores, @DatosNuevos);
END;
GO

-- -----------------------------------------------
-- Trigger Auditoria en VEHICULOS
-- -----------------------------------------------
CREATE TRIGGER trg_Auditoria_Vehiculos
ON Vehiculos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Operacion VARCHAR(10);
    DECLARE @DatosAnteriores NVARCHAR(MAX) = NULL;
    DECLARE @DatosNuevos NVARCHAR(MAX) = NULL;

    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        SET @Operacion = 'UPDATE';
    ELSE IF EXISTS (SELECT 1 FROM inserted)
        SET @Operacion = 'INSERT';
    ELSE
        SET @Operacion = 'DELETE';

    IF @Operacion IN ('UPDATE', 'DELETE')
    BEGIN
        SELECT @DatosAnteriores = (
            SELECT Placa, Marca, Modelo, Color, TipoVehiculo, DNI_Usuario
            FROM deleted
            FOR XML PATH('Vehiculo'), ROOT('Datos')
        );
    END

    IF @Operacion IN ('INSERT', 'UPDATE')
    BEGIN
        SELECT @DatosNuevos = (
            SELECT Placa, Marca, Modelo, Color, TipoVehiculo, DNI_Usuario
            FROM inserted
            FOR XML PATH('Vehiculo'), ROOT('Datos')
        );
    END

    INSERT INTO Historial_Auditoria (TablaAfectada, Operacion, DatosAnteriores, DatosNuevos)
    VALUES ('Vehiculos', @Operacion, @DatosAnteriores, @DatosNuevos);
END;
GO

-- -----------------------------------------------
-- Trigger Auditoria en PAGOS
-- -----------------------------------------------
CREATE TRIGGER trg_Auditoria_Pagos
ON Pagos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Operacion VARCHAR(10);
    DECLARE @DatosAnteriores NVARCHAR(MAX) = NULL;
    DECLARE @DatosNuevos NVARCHAR(MAX) = NULL;

    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        SET @Operacion = 'UPDATE';
    ELSE IF EXISTS (SELECT 1 FROM inserted)
        SET @Operacion = 'INSERT';
    ELSE
        SET @Operacion = 'DELETE';

    IF @Operacion IN ('UPDATE', 'DELETE')
    BEGIN
        SELECT @DatosAnteriores = (
            SELECT IdPago, FechaPago, Monto, TipoPago, PersonalRecibio, IdSancion
            FROM deleted
            FOR XML PATH('Pago'), ROOT('Datos')
        );
    END

    IF @Operacion IN ('INSERT', 'UPDATE')
    BEGIN
        SELECT @DatosNuevos = (
            SELECT IdPago, FechaPago, Monto, TipoPago, PersonalRecibio, IdSancion
            FROM inserted
            FOR XML PATH('Pago'), ROOT('Datos')
        );
    END

    INSERT INTO Historial_Auditoria (TablaAfectada, Operacion, DatosAnteriores, DatosNuevos)
    VALUES ('Pagos', @Operacion, @DatosAnteriores, @DatosNuevos);
END;
GO

PRINT '========================================';
PRINT 'Triggers de auditoria creados.';
PRINT '========================================';
GO


-- =============================================
-- g) TRIGGER PARA MODIFICAR ESTADO DEL ESPACIO
--    DE PARQUEO AL INGRESAR UN VEHICULO
-- =============================================
CREATE TRIGGER trg_ActualizarEstadoEspacio
ON Tickets
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Cuando se INSERTA un ticket (ingreso) -> Espacio = 'Ocupado'
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        UPDATE e
        SET e.Estado = 'Ocupado'
        FROM EspaciosParqueo e
        INNER JOIN inserted i ON e.IdEspacio = i.IdEspacio
        WHERE i.FechaHoraSalida IS NULL;
    END

    -- Cuando se ACTUALIZA un ticket con FechaHoraSalida (salida) -> Espacio = 'Disponible'
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        UPDATE e
        SET e.Estado = 'Disponible'
        FROM EspaciosParqueo e
        INNER JOIN inserted i ON e.IdEspacio = i.IdEspacio
        INNER JOIN deleted d ON d.IdTicket = i.IdTicket
        WHERE d.FechaHoraSalida IS NULL       -- Antes no tenia salida
          AND i.FechaHoraSalida IS NOT NULL;   -- Ahora si tiene salida
    END
END;
GO

PRINT '========================================';
PRINT 'Trigger de estado de espacio creado.';
PRINT '========================================';
GO


-- =============================================
-- h) TRIGGER PARA CALCULAR TOTAL A PAGAR
--    CUANDO SE REGISTRA UNA INFRACCION
-- =============================================
CREATE TRIGGER trg_CalcularTotalPagar
ON Infracciones
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DNI CHAR(8);
    DECLARE @TotalInfracciones INT;
    DECLARE @TotalDeudaPendiente DECIMAL(10,2);

    -- Recorrer cada usuario afectado por las nuevas infracciones
    DECLARE cur_usuarios CURSOR FOR
        SELECT DISTINCT DNI_Usuario FROM inserted;

    OPEN cur_usuarios;
    FETCH NEXT FROM cur_usuarios INTO @DNI;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Contar total de infracciones del usuario
        SELECT @TotalInfracciones = COUNT(*)
        FROM Infracciones
        WHERE DNI_Usuario = @DNI;

        -- Calcular total de deudas pendientes
        SELECT @TotalDeudaPendiente = ISNULL(SUM(s.MontoMulta), 0)
        FROM Sanciones s
        INNER JOIN Infracciones i ON s.IdInfraccion = i.IdInfraccion
        WHERE i.DNI_Usuario = @DNI
          AND s.Estado = 'Pendiente';

        -- Mostrar el total acumulado
        PRINT '--- CALCULO DE DEUDA ---';
        PRINT 'Usuario DNI: ' + @DNI;
        PRINT 'Total de infracciones registradas: ' + CAST(@TotalInfracciones AS VARCHAR);
        PRINT 'Deuda pendiente acumulada: S/ ' + CAST(@TotalDeudaPendiente AS VARCHAR);
        PRINT '------------------------';

        FETCH NEXT FROM cur_usuarios INTO @DNI;
    END

    CLOSE cur_usuarios;
    DEALLOCATE cur_usuarios;
END;
GO

PRINT '========================================';
PRINT 'Trigger de calculo de total creado.';
PRINT '========================================';
GO


-- =============================================
-- i) CURSOR PARA RECORRER TICKETS ABIERTOS
--    CON PERMANENCIA > 12 HORAS
--    Registra infraccion "Permanencia excedida"
--    y multa de S/ 20.00
-- =============================================
CREATE PROCEDURE sp_ProcesarPermanenciaExcedida
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdTicket         INT;
    DECLARE @Placa            VARCHAR(10);
    DECLARE @DNI_Usuario      CHAR(8);
    DECLARE @FechaIngreso     DATETIME;
    DECLARE @HorasTranscurridas DECIMAL(10,2);
    DECLARE @IdInfraccion     INT;
    DECLARE @Contador         INT = 0;

    PRINT '========================================';
    PRINT 'PROCESO: Verificacion de permanencia excedida';
    PRINT 'Fecha de ejecucion: ' + CONVERT(VARCHAR, GETDATE(), 120);
    PRINT '========================================';

    -- Declarar cursor para tickets abiertos con mas de 12 horas
    DECLARE cur_Tickets CURSOR FOR
        SELECT t.IdTicket, t.Placa_Vehiculo, v.DNI_Usuario, t.FechaHoraIngreso,
               CAST(DATEDIFF(MINUTE, t.FechaHoraIngreso, GETDATE()) / 60.0 AS DECIMAL(10,2)) AS HorasTranscurridas
        FROM Tickets t
        INNER JOIN Vehiculos v ON t.Placa_Vehiculo = v.Placa
        WHERE t.FechaHoraSalida IS NULL  -- Ticket abierto (vehiculo aun dentro)
          AND DATEDIFF(HOUR, t.FechaHoraIngreso, GETDATE()) > 12  -- Mas de 12 horas
          AND NOT EXISTS (  -- Evitar duplicar infraccion por permanencia excedida en el mismo ticket
              SELECT 1 FROM Infracciones i
              WHERE i.IdTicket = t.IdTicket
                AND i.Descripcion = 'Permanencia excedida'
          );

    OPEN cur_Tickets;
    FETCH NEXT FROM cur_Tickets INTO @IdTicket, @Placa, @DNI_Usuario, @FechaIngreso, @HorasTranscurridas;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            -- 1. Registrar la infraccion
            INSERT INTO Infracciones (Descripcion, FechaInfraccion, DNI_Usuario, IdTicket)
            VALUES ('Permanencia excedida', GETDATE(), @DNI_Usuario, @IdTicket);

            SET @IdInfraccion = SCOPE_IDENTITY();

            -- 2. Registrar la sancion (multa de S/ 20.00)
            INSERT INTO Sanciones (TipoSancion, MontoMulta, FechaInicio, Estado, IdInfraccion)
            VALUES ('Multa', 20.00, GETDATE(), 'Pendiente', @IdInfraccion);

            SET @Contador = @Contador + 1;

            PRINT 'Infraccion registrada - Ticket #' + CAST(@IdTicket AS VARCHAR)
                + ' | Placa: ' + @Placa
                + ' | DNI: ' + @DNI_Usuario
                + ' | Horas: ' + CAST(@HorasTranscurridas AS VARCHAR)
                + ' | Multa: S/ 20.00';

        END TRY
        BEGIN CATCH
            PRINT 'Error procesando ticket #' + CAST(@IdTicket AS VARCHAR) + ': ' + ERROR_MESSAGE();
        END CATCH

        FETCH NEXT FROM cur_Tickets INTO @IdTicket, @Placa, @DNI_Usuario, @FechaIngreso, @HorasTranscurridas;
    END

    CLOSE cur_Tickets;
    DEALLOCATE cur_Tickets;

    PRINT '========================================';
    PRINT 'Proceso finalizado. Total de infracciones registradas: ' + CAST(@Contador AS VARCHAR);
    PRINT '========================================';
END;
GO

PRINT '========================================';
PRINT 'Cursor de permanencia excedida creado.';
PRINT '========================================';
GO


-- =============================================
-- DATOS DE PRUEBA
-- =============================================
PRINT '';
PRINT '========================================';
PRINT 'INSERTANDO DATOS DE PRUEBA...';
PRINT '========================================';

-- Insertar usuarios
EXEC sp_InsertarUsuario '70123456', 'Carlos Ramirez Lopez',       'carlos.ramirez@upn.edu.pe',   '987654321', 'Estudiante';
EXEC sp_InsertarUsuario '70234567', 'Maria Fernanda Torres',      'maria.torres@upn.edu.pe',     '976543210', 'Docente';
EXEC sp_InsertarUsuario '70345678', 'Jose Luis Paredes',          'jose.paredes@upn.edu.pe',     '965432109', 'Personal Administrativo';
EXEC sp_InsertarUsuario '70456789', 'Ana Lucia Mendoza',          'ana.mendoza@upn.edu.pe',      '954321098', 'Estudiante';
EXEC sp_InsertarUsuario '70567890', 'Pedro Miguel Castillo',      'pedro.castillo@upn.edu.pe',   '943210987', 'Visitante';
GO

-- Insertar vehiculos
EXEC sp_InsertarVehiculo 'ABC-123', 'Toyota',   'Corolla',    'Blanco',   'Automovil',          '70123456';
EXEC sp_InsertarVehiculo 'DEF-456', 'Honda',    'Civic',      'Negro',    'Automovil',          '70234567';
EXEC sp_InsertarVehiculo 'GHI-789', 'Yamaha',   'FZ25',       'Azul',     'Motocicleta',        '70345678';
EXEC sp_InsertarVehiculo 'JKL-012', 'Trek',     'Marlin 7',   'Rojo',     'Bicicleta',          '70456789';
EXEC sp_InsertarVehiculo 'MNO-345', 'Tesla',    'Model 3',    'Gris',     'Vehiculo Electrico', '70567890';
EXEC sp_InsertarVehiculo 'PQR-678', 'Kia',      'Rio',        'Plata',    'Automovil',          '70123456';
GO

-- Insertar zonas de parqueo
EXEC sp_InsertarZonaParqueo 'Zona de vehiculos A',    'Edificio Principal - Sotano 1',  50;
EXEC sp_InsertarZonaParqueo 'Zona de motos B',        'Edificio Principal - Sotano 1',  30;
EXEC sp_InsertarZonaParqueo 'Zona de bicicletas C',   'Patio Central',                  40;
EXEC sp_InsertarZonaParqueo 'Zona electrica D',       'Edificio Nuevo - Planta Baja',   10;
GO

-- Insertar espacios de parqueo
EXEC sp_InsertarEspacioParqueo 'A-001', 'Estandar',         1;
EXEC sp_InsertarEspacioParqueo 'A-002', 'Estandar',         1;
EXEC sp_InsertarEspacioParqueo 'A-003', 'Discapacitados',   1;
EXEC sp_InsertarEspacioParqueo 'A-004', 'Estandar',         1;
EXEC sp_InsertarEspacioParqueo 'B-001', 'Estandar',         2;
EXEC sp_InsertarEspacioParqueo 'B-002', 'Estandar',         2;
EXEC sp_InsertarEspacioParqueo 'C-001', 'Estandar',         3;
EXEC sp_InsertarEspacioParqueo 'C-002', 'Estandar',         3;
EXEC sp_InsertarEspacioParqueo 'D-001', 'Carga Electrica',  4;
EXEC sp_InsertarEspacioParqueo 'D-002', 'Carga Electrica',  4;
GO

PRINT '';
PRINT '========================================';
PRINT 'PROBANDO INGRESO VEHICULAR...';
PRINT '========================================';

-- Prueba 1: Ingreso normal
EXEC sp_RegistrarIngresoVehicular 'ABC-123';
GO

-- Prueba 2: Intentar ingresar otro vehiculo del mismo usuario (debe fallar)
EXEC sp_RegistrarIngresoVehicular 'PQR-678';
GO

-- Prueba 3: Ingreso de otro usuario
EXEC sp_RegistrarIngresoVehicular 'DEF-456';
GO

-- Prueba 4: Ingreso de moto
EXEC sp_RegistrarIngresoVehicular 'GHI-789';
GO

-- Simular un ticket abierto con mas de 12 horas (para probar el cursor)
-- Actualizamos la fecha de ingreso de un ticket existente
UPDATE Tickets
SET FechaHoraIngreso = DATEADD(HOUR, -15, GETDATE())
WHERE Placa_Vehiculo = 'ABC-123';
GO

PRINT '';
PRINT '========================================';
PRINT 'PROBANDO CURSOR DE PERMANENCIA EXCEDIDA...';
PRINT '========================================';

EXEC sp_ProcesarPermanenciaExcedida;
GO

-- Verificar resultados
PRINT '';
PRINT '========================================';
PRINT 'VERIFICACION DE DATOS';
PRINT '========================================';

SELECT 'USUARIOS' AS Tabla;
SELECT * FROM Usuarios;

SELECT 'VEHICULOS' AS Tabla;
SELECT * FROM Vehiculos;

SELECT 'ZONAS DE PARQUEO' AS Tabla;
SELECT * FROM ZonasParqueo;

SELECT 'ESPACIOS DE PARQUEO' AS Tabla;
SELECT * FROM EspaciosParqueo;

SELECT 'TICKETS' AS Tabla;
SELECT * FROM Tickets;

SELECT 'INFRACCIONES' AS Tabla;
SELECT * FROM Infracciones;

SELECT 'SANCIONES' AS Tabla;
SELECT * FROM Sanciones;

SELECT 'HISTORIAL DE AUDITORIA' AS Tabla;
SELECT * FROM Historial_Auditoria;
GO

PRINT '';
PRINT '============================================';
PRINT ' SCRIPT COMPLETADO EXITOSAMENTE';
PRINT ' Base de Datos: GestionParqueoUPN';
PRINT '============================================';
GO
