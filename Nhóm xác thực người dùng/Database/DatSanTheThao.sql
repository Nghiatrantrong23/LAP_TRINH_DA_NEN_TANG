-- ============================================================
-- DATABASE: DatSanTheThao (Đặt sân thể thao & Ghép kèo)
-- ============================================================
USE master;
GO

IF DB_ID(N'DatSanTheThao') IS NOT NULL
BEGIN
    ALTER DATABASE DatSanTheThao SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DatSanTheThao;
END
GO

CREATE DATABASE DatSanTheThao;
GO

USE DatSanTheThao;
GO

-- ============================================================
-- A. TÀI KHOẢN VÀ PHÂN QUYỀN
-- ============================================================
CREATE TABLE VaiTro (
    MaVaiTro SMALLINT NOT NULL PRIMARY KEY,
    TenVaiTro VARCHAR(20) NOT NULL UNIQUE -- Admin | Member
);
GO

CREATE TABLE ThanhVien (
    MaThanhVien UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    MaVaiTro SMALLINT NOT NULL REFERENCES VaiTro(MaVaiTro),
    Ten NVARCHAR(50) NOT NULL,
    Ho NVARCHAR(50) NOT NULL,
    Email NVARCHAR(254) NOT NULL,
    EmailChuanHoa NVARCHAR(254) NOT NULL UNIQUE,
    SoDienThoai VARCHAR(20) NULL,
    MatKhauHash VARCHAR(255) NOT NULL,
    BiKhoa BIT NOT NULL DEFAULT 0,
    DaXacThucEmail BIT NOT NULL DEFAULT 0,
    PhienBanBaoMat INT NOT NULL DEFAULT 1,
    NgayTao DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    NgayCapNhat DATETIME2(3) NULL,
    RowVersion ROWVERSION NOT NULL
);
GO

CREATE TABLE PhienDangNhap (
    MaPhien UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    MaThanhVien UNIQUEIDENTIFIER NOT NULL REFERENCES ThanhVien(MaThanhVien),
    RefreshTokenHash BINARY(32) NOT NULL UNIQUE,
    HetHanLuc DATETIME2(3) NOT NULL,
    ThuHoiLuc DATETIME2(3) NULL,
    NgayTao DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE MaXacThucEmail (
    MaYeuCau UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    MaThanhVien UNIQUEIDENTIFIER NOT NULL REFERENCES ThanhVien(MaThanhVien),
    MucDich VARCHAR(30) NOT NULL, -- XacThucEmail | QuenMatKhau
    MaCodeHash BINARY(32) NOT NULL,
    HetHanLuc DATETIME2(3) NOT NULL,
    DaDungLuc DATETIME2(3) NULL,
    SoLanSai SMALLINT NOT NULL DEFAULT 0,
    NgayTao DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- ============================================================
-- B. CƠ SỞ, DANH MỤC VÀ SẢN PHẨM (SÂN & DỊCH VỤ)
-- ============================================================
CREATE TABLE CoSo (
    MaCoSo INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    TenCoSo NVARCHAR(150) NOT NULL,
    DiaChi NVARCHAR(300) NOT NULL,
    SoDienThoai VARCHAR(20) NOT NULL,
    DangHoatDong BIT NOT NULL DEFAULT 1,
    NgayTao DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE DanhMuc (
    MaDanhMuc INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    TenDanhMuc NVARCHAR(100) NOT NULL UNIQUE,
    MoTa NVARCHAR(1000) NULL,
    DuongDanAnh NVARCHAR(500) NULL,
    ThuTuHienThi INT NOT NULL DEFAULT 0,
    DangHoatDong BIT NOT NULL DEFAULT 1,
    NgayTao DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    RowVersion ROWVERSION NOT NULL
);
GO

CREATE TABLE SanPham (
    MaSanPham INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    MaDanhMuc INT NOT NULL REFERENCES DanhMuc(MaDanhMuc),
    MaCoSo INT NOT NULL REFERENCES CoSo(MaCoSo),
    LoaiSanPham VARCHAR(10) NOT NULL CHECK (LoaiSanPham IN ('San', 'DichVu')),
    TenSanPham NVARCHAR(150) NOT NULL,
    MoTa NVARCHAR(MAX) NULL,
    DuongDanAnh NVARCHAR(500) NOT NULL,
    GiaCoBan DECIMAL(18,2) NOT NULL CHECK (GiaCoBan >= 0),
    DonViTinh NVARCHAR(30) NOT NULL,
    DangHoatDong BIT NOT NULL DEFAULT 1,
    NgayTao DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    NgayCapNhat DATETIME2(3) NULL,
    RowVersion ROWVERSION NOT NULL
);
GO

CREATE TABLE ThongTinSan (
    MaSan INT NOT NULL PRIMARY KEY REFERENCES SanPham(MaSanPham),
    SucChua SMALLINT NOT NULL CHECK (SucChua > 1),
    MatSan NVARCHAR(100) NULL,
    TrongNha BIT NOT NULL DEFAULT 1,
    SoPhutMoiO SMALLINT NOT NULL DEFAULT 30 CHECK (SoPhutMoiO = 30)
);
GO

CREATE TABLE LichMoCuaSan (
    MaLichMoCua INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    MaSan INT NOT NULL REFERENCES ThongTinSan(MaSan),
    ThuTrongTuan TINYINT NOT NULL CHECK (ThuTrongTuan BETWEEN 0 AND 6), -- 0 = CN ... 6 = T7
    GioMoCua TIME(0) NOT NULL,
    GioDongCua TIME(0) NOT NULL,
    Nghi BIT NOT NULL DEFAULT 0,
    CONSTRAINT UQ_LichMoCuaSan_San_Thu UNIQUE (MaSan, ThuTrongTuan),
    CONSTRAINT CK_LichMoCuaSan_Gio CHECK (Nghi = 1 OR GioDongCua > GioMoCua)
);
GO

CREATE TABLE QuyTacGiaSan (
    MaQuyTacGia INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    MaSan INT NOT NULL REFERENCES ThongTinSan(MaSan),
    ThuTrongTuan TINYINT NOT NULL CHECK (ThuTrongTuan BETWEEN 0 AND 6),
    GioBatDau TIME(0) NOT NULL,
    GioKetThuc TIME(0) NOT NULL,
    GiaMoiGio DECIMAL(18,2) NOT NULL CHECK (GiaMoiGio >= 0),
    HieuLucTu DATE NOT NULL,
    HieuLucDen DATE NULL,
    DangHoatDong BIT NOT NULL DEFAULT 1,
    RowVersion ROWVERSION NOT NULL,
    CONSTRAINT CK_QuyTacGiaSan_Gio CHECK (GioKetThuc > GioBatDau),
    CONSTRAINT CK_QuyTacGiaSan_Ngay CHECK (HieuLucDen IS NULL OR HieuLucDen >= HieuLucTu)
);
GO

-- ============================================================
-- C. LỊCH SÂN VÀ GIỎ HÀNG
-- ============================================================
CREATE TABLE OLichSan (
    MaOLich BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    MaSan INT NOT NULL REFERENCES ThongTinSan(MaSan),
    NgayChoi DATE NOT NULL,
    GioBatDau TIME(0) NOT NULL,
    GioKetThuc TIME(0) NOT NULL,
    BiKhoa BIT NOT NULL DEFAULT 0,
    LyDoKhoa NVARCHAR(300) NULL,
    RowVersion ROWVERSION NOT NULL,
    CONSTRAINT UQ_OLichSan_San_Ngay_Gio UNIQUE (MaSan, NgayChoi, GioBatDau),
    CONSTRAINT CK_OLichSan_Gio CHECK (GioKetThuc > GioBatDau)
);
GO

CREATE TABLE GioHang (
    MaGioHang UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    MaThanhVien UNIQUEIDENTIFIER NOT NULL UNIQUE REFERENCES ThanhVien(MaThanhVien),
    NgayCapNhat DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    RowVersion ROWVERSION NOT NULL
);
GO

CREATE TABLE ChiTietGioHang (
    MaChiTietGio BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    MaGioHang UNIQUEIDENTIFIER NOT NULL REFERENCES GioHang(MaGioHang) ON DELETE CASCADE,
    MaSanPham INT NOT NULL REFERENCES SanPham(MaSanPham),
    NgayChoi DATE NULL,
    GioBatDau TIME(0) NULL,
    SoOLich SMALLINT NULL CHECK (SoOLich IS NULL OR SoOLich > 0),
    SoLuong INT NOT NULL DEFAULT 1 CHECK (SoLuong > 0),
    NgayTao DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- ============================================================
-- D. ĐƠN HÀNG VÀ CHỐNG ĐẶT TRÙNG KHUNG GIỜ
-- ============================================================
CREATE TABLE DonHang (
    MaDonHang UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    SoDonHang VARCHAR(30) NOT NULL UNIQUE,
    MaThanhVien UNIQUEIDENTIFIER NOT NULL REFERENCES ThanhVien(MaThanhVien),
    MaCoSo INT NOT NULL REFERENCES CoSo(MaCoSo),
    NgayDatChoi DATE NOT NULL,
    TenKhachHang NVARCHAR(120) NOT NULL,
    SoDienThoaiKhach VARCHAR(20) NOT NULL,
    TrangThai VARCHAR(30) NOT NULL CHECK (TrangThai IN ('ChoCoc', 'DaXacNhan', 'DangChoi', 'HoanThanh', 'DaHuy')),
    TongTien DECIMAL(18,2) NOT NULL CHECK (TongTien >= 0),
    TienCoc DECIMAL(18,2) NOT NULL CHECK (TienCoc >= 0),
    GiuChoDen DATETIME2(3) NULL,
    GhiChu NVARCHAR(1000) NULL,
    KhoaChongTrung VARCHAR(64) NOT NULL,
    RequestHash BINARY(32) NOT NULL,
    NgayTao DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    NgayCapNhat DATETIME2(3) NULL,
    RowVersion ROWVERSION NOT NULL,
    CONSTRAINT UQ_DonHang_ThanhVien_ChongTrung UNIQUE (MaThanhVien, KhoaChongTrung),
    CONSTRAINT CK_DonHang_TienCoc CHECK (TienCoc <= TongTien)
);
GO

CREATE TABLE ChiTietDonHang (
    MaChiTietDon BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    MaDonHang UNIQUEIDENTIFIER NOT NULL REFERENCES DonHang(MaDonHang),
    MaSanPham INT NOT NULL REFERENCES SanPham(MaSanPham),
    TenSanPham NVARCHAR(150) NOT NULL,
    LoaiSanPham VARCHAR(10) NOT NULL CHECK (LoaiSanPham IN ('San', 'DichVu')),
    DonViTinh NVARCHAR(30) NOT NULL,
    SoLuong INT NOT NULL CHECK (SoLuong > 0),
    DonGia DECIMAL(18,2) NULL CHECK (DonGia IS NULL OR DonGia >= 0),
    ThanhTien DECIMAL(18,2) NOT NULL CHECK (ThanhTien >= 0)
);
GO

CREATE TABLE ChiTietOLichDonHang (
    MaChiTietDon BIGINT NOT NULL REFERENCES ChiTietDonHang(MaChiTietDon),
    MaOLich BIGINT NOT NULL REFERENCES OLichSan(MaOLich),
    DonGia DECIMAL(18,2) NOT NULL CHECK (DonGia >= 0),
    CONSTRAINT PK_ChiTietOLichDonHang PRIMARY KEY (MaChiTietDon, MaOLich)
);
GO

CREATE TABLE GiuChoOLich (
    MaOLich BIGINT NOT NULL PRIMARY KEY REFERENCES OLichSan(MaOLich),
    MaChiTietDon BIGINT NOT NULL,
    CONSTRAINT FK_GiuChoOLich_ChiTietOLichDonHang
        FOREIGN KEY (MaChiTietDon, MaOLich) REFERENCES ChiTietOLichDonHang(MaChiTietDon, MaOLich)
);
GO

CREATE TABLE LichSuTrangThaiDon (
    MaLichSu BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    MaDonHang UNIQUEIDENTIFIER NOT NULL REFERENCES DonHang(MaDonHang),
    TrangThaiCu VARCHAR(30) NULL,
    TrangThaiMoi VARCHAR(30) NOT NULL,
    NguoiThayDoi UNIQUEIDENTIFIER NULL REFERENCES ThanhVien(MaThanhVien),
    LyDo NVARCHAR(500) NULL,
    NgayTao DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE MaCheckIn (
    MaToken UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    MaDonHang UNIQUEIDENTIFIER NOT NULL REFERENCES DonHang(MaDonHang),
    TokenHash BINARY(32) NOT NULL UNIQUE,
    HetHanLuc DATETIME2(3) NOT NULL,
    DaDungLuc DATETIME2(3) NULL,
    ThuHoiLuc DATETIME2(3) NULL,
    NguoiQuet UNIQUEIDENTIFIER NULL REFERENCES ThanhVien(MaThanhVien)
);
GO

-- ============================================================
-- E. THANH TOÁN VÀ DOANH THU
-- ============================================================
CREATE TABLE ThanhToan (
    MaThanhToan UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    MaDonHang UNIQUEIDENTIFIER NOT NULL REFERENCES DonHang(MaDonHang),
    LoaiGiaoDich VARCHAR(20) NOT NULL CHECK (LoaiGiaoDich IN ('TienCoc', 'ThanhToanConLai', 'HoanTien')),
    PhuongThuc VARCHAR(20) NOT NULL CHECK (PhuongThuc IN ('ChuyenKhoan', 'TienMat')),
    SoTien DECIMAL(18,2) NOT NULL CHECK (SoTien > 0),
    TrangThai VARCHAR(20) NOT NULL CHECK (TrangThai IN ('ChoDuyet', 'DaXacNhan', 'TuChoi')),
    NoiDungChuyenKhoan VARCHAR(100) NOT NULL,
    MaThamChieuNgoai VARCHAR(100) NULL,
    NguoiXacNhan UNIQUEIDENTIFIER NULL REFERENCES ThanhVien(MaThanhVien),
    XacNhanLuc DATETIME2(3) NULL,
    NgayTao DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    RowVersion ROWVERSION NOT NULL
);
GO

CREATE UNIQUE INDEX UX_ThanhToan_MaThamChieuNgoai
    ON ThanhToan(MaThamChieuNgoai)
    WHERE MaThamChieuNgoai IS NOT NULL;
GO

-- ============================================================
-- F. GHÉP KÈO VÃNG LAI
-- ============================================================
CREATE TABLE PhongGhepKeo (
    MaPhong UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    MaChiTietDon BIGINT NOT NULL REFERENCES ChiTietDonHang(MaChiTietDon),
    ChuPhong UNIQUEIDENTIFIER NOT NULL REFERENCES ThanhVien(MaThanhVien),
    TieuDe NVARCHAR(150) NOT NULL,
    TrinhDoYeuCau NVARCHAR(30) NOT NULL, -- MoiChoi | TrungBinh | KhaGioi
    SoNguoiCanTim SMALLINT NOT NULL CHECK (SoNguoiCanTim > 0),
    ChiPhiMoiNguoi DECIMAL(18,2) NOT NULL CHECK (ChiPhiMoiNguoi >= 0),
    MoTa NVARCHAR(1000) NULL,
    TrangThai VARCHAR(20) NOT NULL CHECK (TrangThai IN ('DangMo', 'DaDu', 'DaDong', 'DaHuy')),
    NgayTao DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    RowVersion ROWVERSION NOT NULL
);
GO

CREATE UNIQUE INDEX UX_PhongGhepKeo_DangHoatDong
    ON PhongGhepKeo(MaChiTietDon)
    WHERE TrangThai IN ('DangMo', 'DaDu');
GO

CREATE TABLE YeuCauGhepKeo (
    MaYeuCau UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    MaPhong UNIQUEIDENTIFIER NOT NULL REFERENCES PhongGhepKeo(MaPhong),
    MaThanhVien UNIQUEIDENTIFIER NOT NULL REFERENCES ThanhVien(MaThanhVien),
    TrangThai VARCHAR(20) NOT NULL CHECK (TrangThai IN ('ChoDuyet', 'DaDuyet', 'TuChoi', 'DaHuy')),
    LoiNhan NVARCHAR(500) NULL,
    NguoiDuyet UNIQUEIDENTIFIER NULL REFERENCES ThanhVien(MaThanhVien),
    DuyetLuc DATETIME2(3) NULL,
    NgayTao DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    RowVersion ROWVERSION NOT NULL,
    CONSTRAINT UQ_YeuCauGhepKeo_Phong_ThanhVien UNIQUE (MaPhong, MaThanhVien)
);
GO

-- ============================================================
-- G. ĐỒNG BỘ XÓA FILE ẢNH
-- ============================================================
CREATE TABLE TacVuXoaAnh (
    MaTacVu BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    DuongDanTuongDoi NVARCHAR(500) NOT NULL,
    NgayTao DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    HoanThanhLuc DATETIME2(3) NULL,
    SoLanThu INT NOT NULL DEFAULT 0,
    LanThuTiepTheo DATETIME2(3) NULL,
    LoiCuoi NVARCHAR(1000) NULL
);
GO

-- ============================================================
-- H. INDEX PHỤC VỤ TRUY VẤN & PHÂN TRANG
-- ============================================================
CREATE INDEX IX_SanPham_DanhMuc_HoatDong_NgayTao ON SanPham(MaDanhMuc, DangHoatDong, NgayTao DESC, MaSanPham DESC);
CREATE INDEX IX_SanPham_CoSo_Loai_HoatDong ON SanPham(MaCoSo, LoaiSanPham, DangHoatDong);
CREATE INDEX IX_DonHang_ThanhVien_NgayTao ON DonHang(MaThanhVien, NgayTao DESC, MaDonHang DESC);
CREATE INDEX IX_DonHang_TrangThai_GiuChoDen ON DonHang(TrangThai, GiuChoDen);
CREATE INDEX IX_DonHang_NgayDatChoi_CoSo ON DonHang(NgayDatChoi, MaCoSo);
CREATE INDEX IX_ThanhToan_TrangThai_XacNhanLuc ON ThanhToan(TrangThai, XacNhanLuc);
CREATE INDEX IX_PhongGhepKeo_TrangThai_NgayTao ON PhongGhepKeo(TrangThai, NgayTao DESC, MaPhong DESC);
CREATE INDEX IX_YeuCauGhepKeo_Phong_TrangThai ON YeuCauGhepKeo(MaPhong, TrangThai);
CREATE INDEX IX_TacVuXoaAnh_ChoXuLy ON TacVuXoaAnh(HoanThanhLuc, LanThuTiepTheo);
GO

-- ============================================================
-- I. STORED PROCEDURE SINH Ô LỊCH 30 PHÚT (CHẠY LẶP AN TOÀN)
-- ============================================================
DROP PROC IF EXISTS sp_TaoOLichSan;
GO

CREATE PROC sp_TaoOLichSan
    @NgayBatDau DATE,
    @SoNgayToi INT = 14
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NgayHienTai DATE = @NgayBatDau;
    DECLARE @NgayKetThuc DATE = DATEADD(DAY, @SoNgayToi - 1, @NgayBatDau);

    WHILE @NgayHienTai <= @NgayKetThuc
    BEGIN
        DECLARE @Thu TINYINT = (DATEPART(WEEKDAY, @NgayHienTai) + @@DATEFIRST - 1) % 7;

        ;WITH CTE_OLich AS (
            SELECT
                lm.MaSan,
                @NgayHienTai AS NgayChoi,
                lm.GioMoCua AS GioBatDau,
                DATEADD(MINUTE, 30, lm.GioMoCua) AS GioKetThuc,
                lm.GioDongCua
            FROM LichMoCuaSan lm
            WHERE lm.ThuTrongTuan = @Thu
              AND lm.Nghi = 0
              AND DATEADD(MINUTE, 30, lm.GioMoCua) <= lm.GioDongCua

            UNION ALL

            SELECT
                MaSan,
                NgayChoi,
                GioKetThuc AS GioBatDau,
                DATEADD(MINUTE, 30, GioKetThuc) AS GioKetThuc,
                GioDongCua
            FROM CTE_OLich
            WHERE DATEADD(MINUTE, 30, GioKetThuc) <= GioDongCua
        )
        INSERT INTO OLichSan (MaSan, NgayChoi, GioBatDau, GioKetThuc)
        SELECT s.MaSan, s.NgayChoi, s.GioBatDau, s.GioKetThuc
        FROM CTE_OLich s
        WHERE NOT EXISTS (
            SELECT 1 FROM OLichSan daCo
            WHERE daCo.MaSan = s.MaSan
              AND daCo.NgayChoi = s.NgayChoi
              AND daCo.GioBatDau = s.GioBatDau
        )
        OPTION (MAXRECURSION 100);

        SET @NgayHienTai = DATEADD(DAY, 1, @NgayHienTai);
    END
END
GO

-- ============================================================
-- J. DỮ LIỆU MẪU (SEED DATA)
-- ============================================================
INSERT INTO VaiTro (MaVaiTro, TenVaiTro) VALUES
    (1, 'Admin'),
    (2, 'Member');
GO

-- Thêm tài khoản mẫu: Mật khẩu mặc định là Password123@
-- Hash BCrypt: $2a$11$0nJzD3z0yW09tN3k0gVZZuVj5K9L1IeR5Gk7N6J8M9L0K1J2H3G4F
INSERT INTO ThanhVien (MaThanhVien, MaVaiTro, Ten, Ho, Email, EmailChuanHoa, SoDienThoai, MatKhauHash, BiKhoa, DaXacThucEmail) VALUES
    ('A0000000-0000-0000-0000-000000000001', 1, N'Quản Trị', N'Hệ Thống', 'admin@datsanthethao.com', 'ADMIN@DATSANTHETHAO.COM', '0901234567', '$2a$11$0nJzD3z0yW09tN3k0gVZZuVj5K9L1IeR5Gk7N6J8M9L0K1J2H3G4F', 0, 1),
    ('B0000000-0000-0000-0000-000000000001', 2, N'Văn A', N'Nguyễn', 'member@datsanthethao.com', 'MEMBER@DATSANTHETHAO.COM', '0987654321', '$2a$11$0nJzD3z0yW09tN3k0gVZZuVj5K9L1IeR5Gk7N6J8M9L0K1J2H3G4F', 0, 1);
GO

INSERT INTO CoSo (TenCoSo, DiaChi, SoDienThoai) VALUES
    (N'Cụm Sân Thể Thao SportHub Quận 10', N'268 Lý Thường Kiệt, Quận 10, TP.HCM', '0901234567');
GO

INSERT INTO DanhMuc (TenDanhMuc, MoTa, DuongDanAnh, ThuTuHienThi) VALUES
    (N'Cầu lông', N'Sân cầu lông thảm PVC tiêu chuẩn thi đấu, có mái che', '/uploads/categories/badminton.webp', 1),
    (N'Pickleball', N'Sân Pickleball mặt nhựa chuẩn quốc tế', '/uploads/categories/pickleball.webp', 2),
    (N'Bóng đá mini', N'Sân cỏ nhân tạo 5 người và 7 người', '/uploads/categories/football.webp', 3),
    (N'Dịch vụ & Phụ kiện', N'Thuê vợt, ống cầu, nước giải khát tại sân', '/uploads/categories/services.webp', 4);
GO

-- Thêm Sản phẩm mẫu (3 Sân + 3 Dịch vụ)
INSERT INTO SanPham (MaDanhMuc, MaCoSo, LoaiSanPham, TenSanPham, MoTa, DuongDanAnh, GiaCoBan, DonViTinh) VALUES
    (1, 1, 'San',    N'Sân Cầu Lông 01',        N'Sân thảm xanh trong nhà, đèn chống chói', '/uploads/products/badminton-01.webp',  80000, N'giờ'),
    (2, 1, 'San',    N'Sân Pickleball VIP 01',  N'Sân có mái che, khu vực nghỉ rộng',       '/uploads/products/pickleball-01.webp', 120000, N'giờ'),
    (3, 1, 'San',    N'Sân Bóng Đá 5 Người A1', N'Cỏ nhân tạo mới thay, lưới bao kín',      '/uploads/products/football-01.webp',  250000, N'giờ'),
    (4, 1, 'DichVu', N'Thuê vợt cầu lông',      N'Vợt carbon kèm quấn cán mới',             '/uploads/products/racket.webp',        30000, N'cây'),
    (4, 1, 'DichVu', N'Ống cầu lông Hải Yến',   N'Hộp 12 trái tốc độ chuẩn',                '/uploads/products/shuttlecock.webp',  220000, N'ống'),
    (4, 1, 'DichVu', N'Nước suối / Revive',     N'Ướp lạnh sẵn tại quầy',                   '/uploads/products/drink.webp',         15000, N'chai');
GO

-- Cấu hình ThongTinSan cho 3 sân (MaSan = 1, 2, 3)
INSERT INTO ThongTinSan (MaSan, SucChua, MatSan, TrongNha, SoPhutMoiO) VALUES
    (1, 4,  N'Thảm PVC',    1, 30),
    (2, 4,  N'Sơn Acrylic', 1, 30),
    (3, 10, N'Cỏ nhân tạo', 0, 30);
GO

-- Cấu hình giờ mở cửa 06:00 - 22:00 cả tuần (0..6) cho cả 3 sân
INSERT INTO LichMoCuaSan (MaSan, ThuTrongTuan, GioMoCua, GioDongCua, Nghi)
SELECT s.MaSan, t.ThuTrongTuan, '06:00', '22:00', 0
FROM ThongTinSan s
CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6)) AS t(ThuTrongTuan);
GO

-- Cấu hình giá giờ vàng (17:00 - 21:00) cho Sân Cầu lông 01 và Pickleball VIP 01
INSERT INTO QuyTacGiaSan (MaSan, ThuTrongTuan, GioBatDau, GioKetThuc, GiaMoiGio, HieuLucTu)
SELECT 1, t.ThuTrongTuan, '17:00', '21:00', 110000, CAST(GETDATE() AS DATE)
FROM (VALUES (0),(1),(2),(3),(4),(5),(6)) AS t(ThuTrongTuan);

INSERT INTO QuyTacGiaSan (MaSan, ThuTrongTuan, GioBatDau, GioKetThuc, GiaMoiGio, HieuLucTu)
SELECT 2, t.ThuTrongTuan, '17:00', '21:00', 180000, CAST(GETDATE() AS DATE)
FROM (VALUES (0),(1),(2),(3),(4),(5),(6)) AS t(ThuTrongTuan);
GO

-- Sinh sẵn ô lịch 30 phút cho 14 ngày tới tính từ hôm nay
DECLARE @HomNay DATE = CAST(GETDATE() AS DATE);
EXEC sp_TaoOLichSan @NgayBatDau = @HomNay, @SoNgayToi = 14;
GO

