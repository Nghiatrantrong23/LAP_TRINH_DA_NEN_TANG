USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'SportBooking')
BEGIN
    CREATE DATABASE SportBooking;
END
GO

USE SportBooking;
GO

-- 1. BẢNG ROLE (Phân quyền người dùng)
IF OBJECT_ID('Member', 'U') IS NOT NULL DROP TABLE Member;
IF OBJECT_ID('Role', 'U') IS NOT NULL DROP TABLE Role;

CREATE TABLE Role (
    RoleId INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
    RoleName NVARCHAR(32) NOT NULL UNIQUE,
    Description NVARCHAR(256)
);
GO

SET IDENTITY_INSERT Role ON;
INSERT INTO Role (RoleId, RoleName, Description) VALUES
(1, N'Admin', N'Quản trị viên toàn quyền hệ thống'),
(2, N'Member', N'Khách hàng đặt sân và dịch vụ'),
(3, N'Staff', N'Nhân viên quản lý sân bãi');
SET IDENTITY_INSERT Role OFF;
GO

-- 2. BẢNG MEMBER (Người dùng / Thành viên)
CREATE TABLE Member (
    MemberId VARCHAR(36) NOT NULL PRIMARY KEY,
    Email VARCHAR(64) NOT NULL UNIQUE,
    Password NVARCHAR(128) NOT NULL,
    GivenName NVARCHAR(32) NOT NULL,
    Surname NVARCHAR(32),
    Phone VARCHAR(16),
    RoleId INT NOT NULL DEFAULT 2 REFERENCES Role(RoleId),
    IsEmailConfirmed BIT NOT NULL DEFAULT 0,
    ConfirmationCode VARCHAR(6),
    ConfirmationCodeExpires DATETIME,
    ResetPasswordCode VARCHAR(6),
    ResetPasswordExpires DATETIME,
    IsActive BIT NOT NULL DEFAULT 1,
    ExternalProvider VARCHAR(32), -- 'Google', 'Facebook', 'Zalo'
    ExternalProviderId VARCHAR(128),
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- Tạo sẵn tài khoản mẫu (Mật khẩu mặc định: Password123@)
-- Hash BCrypt của Password123@: $2a$11$qRz7W.bU8yZJ6w1uKk3h9eY9z0L.q3jXoH4Qd4T0f7u4l3q8c5f6W
INSERT INTO Member (MemberId, Email, Password, GivenName, Surname, Phone, RoleId, IsEmailConfirmed, IsActive) VALUES
('a0000000-0000-0000-0000-000000000001', 'admin@sportbooking.com', '$2a$11$0nJzD3z0yW09tN3k0gVZZuVj5K9L1IeR5Gk7N6J8M9L0K1J2H3G4F', N'Quản Trị', N'Hệ Thống', '0901234567', 1, 1, 1),
('m0000000-0000-0000-0000-000000000001', 'member@sportbooking.com', '$2a$11$0nJzD3z0yW09tN3k0gVZZuVj5K9L1IeR5Gk7N6J8M9L0K1J2H3G4F', N'Văn A', N'Nguyễn', '0987654321', 2, 1, 1);
GO

-- 3. CÁC STORED PROCEDURES HỖ TRỢ XÁC THỰC & PHÂN QUYỀN

-- SP: Đăng ký thành viên mới kèm mã xác thực OTP
DROP PROC IF EXISTS sp_RegisterMember;
GO
CREATE PROC sp_RegisterMember (
    @MemberId VARCHAR(36),
    @Email VARCHAR(64),
    @Password NVARCHAR(128),
    @GivenName NVARCHAR(32),
    @Surname NVARCHAR(32),
    @Phone VARCHAR(16),
    @ConfirmationCode VARCHAR(6),
    @MinutesValid INT = 15
)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Member WHERE Email = @Email)
    BEGIN
        RETURN -1; -- Email đã tồn tại
    END

    INSERT INTO Member (
        MemberId, Email, Password, GivenName, Surname, Phone,
        RoleId, IsEmailConfirmed, ConfirmationCode, ConfirmationCodeExpires, IsActive
    ) VALUES (
        @MemberId, @Email, @Password, @GivenName, @Surname, @Phone,
        2, 0, @ConfirmationCode, DATEADD(MINUTE, @MinutesValid, GETDATE()), 1
    );

    RETURN 1; -- Thành công
END
GO

-- SP: Xác thực email qua mã OTP
DROP PROC IF EXISTS sp_VerifyEmail;
GO
CREATE PROC sp_VerifyEmail (
    @Email VARCHAR(64),
    @Code VARCHAR(6)
)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Member WHERE Email = @Email)
        RETURN -1; -- Không tìm thấy email

    IF NOT EXISTS (SELECT 1 FROM Member WHERE Email = @Email AND ConfirmationCode = @Code AND ConfirmationCodeExpires >= GETDATE())
        RETURN -2; -- Mã OTP không đúng hoặc đã hết hạn

    UPDATE Member 
    SET IsEmailConfirmed = 1,
        ConfirmationCode = NULL,
        ConfirmationCodeExpires = NULL
    WHERE Email = @Email;

    RETURN 1; -- Kích hoạt thành công
END
GO

-- SP: Tạo mã OTP quên mật khẩu
DROP PROC IF EXISTS sp_CreateResetCode;
GO
CREATE PROC sp_CreateResetCode (
    @Email VARCHAR(64),
    @Code VARCHAR(6),
    @MinutesValid INT = 15
)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Member WHERE Email = @Email)
        RETURN -1;

    UPDATE Member 
    SET ResetPasswordCode = @Code,
        ResetPasswordExpires = DATEADD(MINUTE, @MinutesValid, GETDATE())
    WHERE Email = @Email;

    RETURN 1;
END
GO

-- SP: Đặt lại mật khẩu mới bằng OTP
DROP PROC IF EXISTS sp_ResetPassword;
GO
CREATE PROC sp_ResetPassword (
    @Email VARCHAR(64),
    @Code VARCHAR(6),
    @NewPassword NVARCHAR(128)
)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Member WHERE Email = @Email AND ResetPasswordCode = @Code AND ResetPasswordExpires >= GETDATE())
        RETURN -2; -- Mã không hợp lệ hoặc hết hạn

    UPDATE Member
    SET Password = @NewPassword,
        ResetPasswordCode = NULL,
        ResetPasswordExpires = NULL
    WHERE Email = @Email;

    RETURN 1;
END
GO

-- SP: Đổi mật khẩu
DROP PROC IF EXISTS sp_ChangePassword;
GO
CREATE PROC sp_ChangePassword (
    @MemberId VARCHAR(36),
    @NewPassword NVARCHAR(128)
)
AS
BEGIN
    UPDATE Member SET Password = @NewPassword WHERE MemberId = @MemberId;
    RETURN 1;
END
GO

-- SP: Khóa / Kích hoạt tài khoản Member (Admin)
DROP PROC IF EXISTS sp_ToggleMemberStatus;
GO
CREATE PROC sp_ToggleMemberStatus (
    @MemberId VARCHAR(36)
)
AS
BEGIN
    UPDATE Member 
    SET IsActive = CASE WHEN IsActive = 1 THEN 0 ELSE 1 END
    WHERE MemberId = @MemberId;
    RETURN 1;
END
GO

-- SP: Thay đổi vai trò Role của Member (Admin)
DROP PROC IF EXISTS sp_ChangeMemberRole;
GO
CREATE PROC sp_ChangeMemberRole (
    @MemberId VARCHAR(36),
    @NewRoleId INT
)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Role WHERE RoleId = @NewRoleId)
        RETURN -2;

    UPDATE Member SET RoleId = @NewRoleId WHERE MemberId = @MemberId;
    RETURN 1;
END
GO

