USE master;
GO

IF DB_ID(N'SportsBookingStage2') IS NULL
BEGIN
    CREATE DATABASE SportsBookingStage2;
END;
GO

USE SportsBookingStage2;
GO

-- =============================================
-- 1. Bang Roles & Members (Nguoi dung & Phan quyen)
-- =============================================
CREATE TABLE Roles (
    Id   SMALLINT     NOT NULL PRIMARY KEY,
    Name NVARCHAR(20) NOT NULL UNIQUE
);
GO

CREATE TABLE Members (
    Id              UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    RoleId          SMALLINT         NOT NULL REFERENCES Roles(Id),
    GivenName       NVARCHAR(50)     NOT NULL,
    Surname         NVARCHAR(50)     NOT NULL,
    Email           NVARCHAR(254)    NOT NULL,
    NormalizedEmail NVARCHAR(254)    NOT NULL UNIQUE,
    Phone           NVARCHAR(20)     NULL,
    PasswordHash    NVARCHAR(255)    NOT NULL,
    IsLocked        BIT              NOT NULL DEFAULT 0,
    EmailConfirmed  BIT              NOT NULL DEFAULT 0,
    SecurityVersion INT              NOT NULL DEFAULT 0,
    CreatedAt       DATETIME2        NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt       DATETIME2        NULL,
    RowVersion      ROWVERSION       NOT NULL
);
GO

CREATE TABLE AuthSessions (
    Id               UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    MemberId         UNIQUEIDENTIFIER NOT NULL REFERENCES Members(Id),
    RefreshTokenHash VARBINARY(32)    NOT NULL UNIQUE,
    ExpiresAt        DATETIME2        NOT NULL,
    RevokedAt        DATETIME2        NULL,
    CreatedAt        DATETIME2        NOT NULL DEFAULT GETUTCDATE(),
    RowVersion       ROWVERSION       NOT NULL
);
GO

CREATE TABLE EmailChallenges (
    Id             UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    MemberId       UNIQUEIDENTIFIER NOT NULL REFERENCES Members(Id),
    Purpose        NVARCHAR(30)     NOT NULL,
    CodeHash       VARBINARY(32)    NOT NULL,
    ExpiresAt      DATETIME2        NOT NULL,
    ConsumedAt     DATETIME2        NULL,
    FailedAttempts SMALLINT         NOT NULL DEFAULT 0,
    CreatedAt      DATETIME2        NOT NULL DEFAULT GETUTCDATE()
);
GO

-- =============================================
-- 2. Bang Venues, Categories & Products (Co so, Danh muc, San/Dich vu)
-- =============================================
CREATE TABLE Venues (
    Id        INT           NOT NULL PRIMARY KEY IDENTITY(1, 1),
    Name      NVARCHAR(150) NOT NULL,
    Address   NVARCHAR(300) NOT NULL,
    Phone     NVARCHAR(20)  NOT NULL,
    IsActive  BIT           NOT NULL DEFAULT 1,
    CreatedAt DATETIME2     NOT NULL DEFAULT GETUTCDATE()
);
GO

CREATE TABLE Categories (
    Id           INT            NOT NULL PRIMARY KEY IDENTITY(1, 1),
    Name         NVARCHAR(100)  NOT NULL UNIQUE,
    Description  NVARCHAR(1000) NULL,
    ImagePath    NVARCHAR(500)  NULL,
    DisplayOrder INT            NOT NULL DEFAULT 0,
    IsActive     BIT            NOT NULL DEFAULT 1,
    CreatedAt    DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
    RowVersion   ROWVERSION     NOT NULL
);
GO

CREATE TABLE Products (
    Id          INT            NOT NULL PRIMARY KEY IDENTITY(1, 1),
    CategoryId  INT            NOT NULL REFERENCES Categories(Id),
    VenueId     INT            NOT NULL REFERENCES Venues(Id),
    Type        NVARCHAR(10)   NOT NULL CHECK (Type IN ('Court', 'Service')),
    Name        NVARCHAR(150)  NOT NULL,
    Description NVARCHAR(MAX)  NULL,
    ImagePath   NVARCHAR(500)  NULL,
    BasePrice   DECIMAL(18, 2) NOT NULL CHECK (BasePrice >= 0),
    Unit        NVARCHAR(30)   NOT NULL,
    IsActive    BIT            NOT NULL DEFAULT 1,
    CreatedAt   DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt   DATETIME2      NULL,
    RowVersion  ROWVERSION     NOT NULL
);
GO

CREATE TABLE FileDeletionJobs (
    Id            BIGINT         NOT NULL PRIMARY KEY IDENTITY(1, 1),
    RelativePath  NVARCHAR(500)  NOT NULL,
    CreatedAt     DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
    CompletedAt   DATETIME2      NULL,
    Attempts      INT            NOT NULL DEFAULT 0,
    NextAttemptAt DATETIME2      NULL,
    LastError     NVARCHAR(1000) NULL
);
GO

-- =============================================
-- 3. Bang Carts & CartItems (Gio hang)
-- =============================================
CREATE TABLE Carts (
    Id         UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    MemberId   UNIQUEIDENTIFIER NOT NULL UNIQUE REFERENCES Members(Id),
    UpdatedAt  DATETIME2        NOT NULL DEFAULT GETUTCDATE(),
    RowVersion ROWVERSION       NOT NULL
);
GO

CREATE TABLE CartItems (
    Id        BIGINT           NOT NULL PRIMARY KEY IDENTITY(1, 1),
    CartId    UNIQUEIDENTIFIER NOT NULL REFERENCES Carts(Id),
    ProductId INT              NOT NULL REFERENCES Products(Id),
    PlayDate  DATE             NULL,
    StartTime TIME(0)          NULL,
    SlotCount SMALLINT         NULL,
    Quantity  INT              NOT NULL CHECK (Quantity > 0),
    CreatedAt DATETIME2        NOT NULL DEFAULT GETUTCDATE()
);
GO

-- =============================================
-- 4. Bang Orders & OrderItems (Don dat san & Chi tiet don)
-- =============================================
CREATE TABLE Orders (
    Id             UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    OrderCode      NVARCHAR(40)     NOT NULL UNIQUE,
    MemberId       UNIQUEIDENTIFIER NOT NULL REFERENCES Members(Id),
    VenueId        INT              NOT NULL REFERENCES Venues(Id),
    BookingDate    DATE             NOT NULL,
    CustomerName   NVARCHAR(120)    NOT NULL,
    CustomerPhone  NVARCHAR(20)     NOT NULL,
    Status         NVARCHAR(30)     NOT NULL CHECK (Status IN ('PendingDeposit', 'Confirmed', 'Playing', 'Completed', 'Cancelled')),
    TotalAmount    DECIMAL(18, 2)   NOT NULL CHECK (TotalAmount >= 0),
    DepositAmount  DECIMAL(18, 2)   NOT NULL CHECK (DepositAmount >= 0),
    HoldExpiresAt  DATETIME2        NULL,
    Note           NVARCHAR(1000)   NULL,
    IdempotencyKey NVARCHAR(64)     NOT NULL,
    RequestHash    VARBINARY(32)    NOT NULL,
    CreatedAt      DATETIME2        NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt      DATETIME2        NULL,
    RowVersion     ROWVERSION       NOT NULL,
    CONSTRAINT UQ_Orders_Member_Idempotency UNIQUE (MemberId, IdempotencyKey)
);
GO

CREATE TABLE OrderItems (
    Id          BIGINT           NOT NULL PRIMARY KEY IDENTITY(1, 1),
    OrderId     UNIQUEIDENTIFIER NOT NULL REFERENCES Orders(Id),
    ProductId   INT              NOT NULL REFERENCES Products(Id),
    ProductName NVARCHAR(150)    NOT NULL,
    ProductType NVARCHAR(10)     NOT NULL,
    Unit        NVARCHAR(30)     NOT NULL,
    Quantity    INT              NOT NULL CHECK (Quantity > 0),
    UnitPrice   DECIMAL(18, 2)   NULL,
    LineTotal   DECIMAL(18, 2)   NOT NULL CHECK (LineTotal >= 0)
);
GO

CREATE TABLE OrderStatusHistories (
    Id                BIGINT           NOT NULL PRIMARY KEY IDENTITY(1, 1),
    OrderId           UNIQUEIDENTIFIER NOT NULL REFERENCES Orders(Id),
    FromStatus        NVARCHAR(30)     NULL,
    ToStatus          NVARCHAR(30)     NOT NULL,
    ChangedByMemberId UNIQUEIDENTIFIER NULL REFERENCES Members(Id),
    Reason            NVARCHAR(500)    NULL,
    CreatedAt         DATETIME2        NOT NULL DEFAULT GETUTCDATE()
);
GO


INSERT INTO Roles (Id, Name) VALUES
(1, N'Member'),
(2, N'Admin');
GO

SET IDENTITY_INSERT Venues ON;
INSERT INTO Venues (Id, Name, Address, Phone, IsActive, CreatedAt) VALUES
(1, N'SportBooking Demo', N'123 Đường Thể Thao, TP.HCM', N'0900000001', 1, GETUTCDATE());
SET IDENTITY_INSERT Venues OFF;
GO

SET IDENTITY_INSERT Categories ON;
INSERT INTO Categories (Id, Name, Description, DisplayOrder, IsActive, CreatedAt) VALUES
(1, N'Cầu lông',     N'Sân cầu lông trong nhà tiêu chuẩn', 1, 1, GETUTCDATE()),
(2, N'Pickleball',   N'Sân Pickleball chuyên dụng',        2, 1, GETUTCDATE()),
(3, N'Bóng đá mini', N'Sân cỏ nhân tạo 5 người, 7 người',  3, 1, GETUTCDATE()),
(4, N'Dịch vụ',      N'Nước uống, đồ ăn nhẹ và thuê vợt',  4, 1, GETUTCDATE());
SET IDENTITY_INSERT Categories OFF;
GO

SET IDENTITY_INSERT Products ON;
INSERT INTO Products (Id, CategoryId, VenueId, Type, Name, Description, BasePrice, Unit, IsActive, CreatedAt) VALUES
(1, 1, 1, 'Court',   N'Sân cầu lông 01',         N'Sân trong nhà, thảm tiêu chuẩn.',           80000,  N'giờ',  1, GETUTCDATE()),
(2, 2, 1, 'Court',   N'Sân Pickleball 01',       N'Sân có mái che.',                            100000, N'giờ',  1, GETUTCDATE()),
(3, 3, 1, 'Court',   N'Sân bóng đá mini 01',     N'Sân cỏ nhân tạo 5 người.',                   200000, N'giờ',  1, GETUTCDATE()),
(4, 4, 1, 'Service', N'Nước tăng lực Sting',     N'Nước tăng lực Sting dâu ướp lạnh.',          15000,  N'chai', 1, GETUTCDATE()),
(5, 4, 1, 'Service', N'Gà rán & Khoai tây giòn', N'Gà rán giòn rụm kèm khoai tây chiên.',       45000,  N'phần', 1, GETUTCDATE());
SET IDENTITY_INSERT Products OFF;
GO
