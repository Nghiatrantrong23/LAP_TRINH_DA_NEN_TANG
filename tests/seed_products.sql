-- 1. Cập nhật 5 sản phẩm ban đầu với đúng hình ảnh và tên
UPDATE Products 
SET Name = N'Sân cầu lông 01', ImagePath = '/uploads/products/sancaulong1.png', BasePrice = 80000, Unit = N'giờ'
WHERE Id = 1;

UPDATE Products 
SET Name = N'Sân Pickleball 01', ImagePath = '/uploads/products/download.png', BasePrice = 120000, Unit = N'giờ'
WHERE Id = 2;

UPDATE Products 
SET Name = N'Sân bóng đá mini 01', ImagePath = '/uploads/products/sandabanh1.png', BasePrice = 250000, Unit = N'giờ'
WHERE Id = 3;

UPDATE Products 
SET Name = N'Nước tăng lực Sting', ImagePath = '/uploads/products/images_8.jpg', BasePrice = 12000, Unit = N'chai', Description = N'Nước tăng lực Sting dâu ướp lạnh'
WHERE Id = 4;

UPDATE Products 
SET Name = N'Mẹt đồ ăn vặt', ImagePath = '/uploads/products/doan1.png', BasePrice = 55000, Unit = N'mẹt', Description = N'Xúc xích, cá viên chiên, khoai tây chiên'
WHERE Id = 5;

-- 2. Thêm các sản phẩm Cầu lông (CategoryId: 1)
IF NOT EXISTS (SELECT 1 FROM Products WHERE Name = N'Sân cầu lông 02')
BEGIN
    INSERT INTO Products (CategoryId, VenueId, Type, Name, Description, ImagePath, BasePrice, Unit, IsActive, CreatedAt)
    VALUES (1, 1, 'Court', N'Sân cầu lông 02', N'Sân trong nhà, thảm cao su chống trượt tiêu chuẩn.', '/uploads/products/sancaulong2.png', 80000, N'giờ', 1, GETUTCDATE());
    DECLARE @id1 INT = SCOPE_IDENTITY();
    INSERT INTO CourtProfiles (ProductId, Capacity, Surface, Indoor, SlotMinutes) VALUES (@id1, 4, N'Thảm cao su', 1, 30);
END

IF NOT EXISTS (SELECT 1 FROM Products WHERE Name = N'Sân cầu lông 03 (VIP)')
BEGIN
    INSERT INTO Products (CategoryId, VenueId, Type, Name, Description, ImagePath, BasePrice, Unit, IsActive, CreatedAt)
    VALUES (1, 1, 'Court', N'Sân cầu lông 03 (VIP)', N'Sân thi đấu thảm BWF, ánh sáng chuẩn quốc tế.', '/uploads/products/sancaulong3.png', 90000, N'giờ', 1, GETUTCDATE());
    DECLARE @id2 INT = SCOPE_IDENTITY();
    INSERT INTO CourtProfiles (ProductId, Capacity, Surface, Indoor, SlotMinutes) VALUES (@id2, 4, N'Thảm BWF', 1, 30);
END

IF NOT EXISTS (SELECT 1 FROM Products WHERE Name = N'Sân cầu lông 04 (Trong nhà)')
BEGIN
    INSERT INTO Products (CategoryId, VenueId, Type, Name, Description, ImagePath, BasePrice, Unit, IsActive, CreatedAt)
    VALUES (1, 1, 'Court', N'Sân cầu lông 04 (Trong nhà)', N'Sân rộng thoáng mát, sàn PVC cao cấp.', '/uploads/products/images_5.png', 85000, N'giờ', 1, GETUTCDATE());
    DECLARE @id3 INT = SCOPE_IDENTITY();
    INSERT INTO CourtProfiles (ProductId, Capacity, Surface, Indoor, SlotMinutes) VALUES (@id3, 4, N'Sàn PVC', 1, 30);
END

-- 3. Thêm các sản phẩm Pickleball (CategoryId: 2)
IF NOT EXISTS (SELECT 1 FROM Products WHERE Name = N'Sân Pickleball 02')
BEGIN
    INSERT INTO Products (CategoryId, VenueId, Type, Name, Description, ImagePath, BasePrice, Unit, IsActive, CreatedAt)
    VALUES (2, 1, 'Court', N'Sân Pickleball 02', N'Sân sơn Acrylic chuyên dụng, độ nảy bóng tốt.', '/uploads/products/download_1.png', 120000, N'giờ', 1, GETUTCDATE());
    DECLARE @id4 INT = SCOPE_IDENTITY();
    INSERT INTO CourtProfiles (ProductId, Capacity, Surface, Indoor, SlotMinutes) VALUES (@id4, 4, N'Sơn Acrylic', 0, 30);
END

IF NOT EXISTS (SELECT 1 FROM Products WHERE Name = N'Sân Pickleball 03 (Đèn đêm)')
BEGIN
    INSERT INTO Products (CategoryId, VenueId, Type, Name, Description, ImagePath, BasePrice, Unit, IsActive, CreatedAt)
    VALUES (2, 1, 'Court', N'Sân Pickleball 03 (Đèn đêm)', N'Sân có hệ thống đèn LED chiếu sáng hiện đại ban đêm.', '/uploads/products/images.png', 140000, N'giờ', 1, GETUTCDATE());
    DECLARE @id5 INT = SCOPE_IDENTITY();
    INSERT INTO CourtProfiles (ProductId, Capacity, Surface, Indoor, SlotMinutes) VALUES (@id5, 4, N'Sân tiêu chuẩn', 0, 30);
END

IF NOT EXISTS (SELECT 1 FROM Products WHERE Name = N'Sân Pickleball 04 (Mái che)')
BEGIN
    INSERT INTO Products (CategoryId, VenueId, Type, Name, Description, ImagePath, BasePrice, Unit, IsActive, CreatedAt)
    VALUES (2, 1, 'Court', N'Sân Pickleball 04 (Mái che)', N'Sân Pickleball ngoài trời có mái che tiện lợi.', '/uploads/products/download.jpg', 120000, N'giờ', 1, GETUTCDATE());
    DECLARE @id6 INT = SCOPE_IDENTITY();
    INSERT INTO CourtProfiles (ProductId, Capacity, Surface, Indoor, SlotMinutes) VALUES (@id6, 4, N'Sơn Acrylic', 1, 30);
END

-- 4. Thêm các sản phẩm Bóng đá mini (CategoryId: 3)
IF NOT EXISTS (SELECT 1 FROM Products WHERE Name = N'Sân bóng đá mini 02')
BEGIN
    INSERT INTO Products (CategoryId, VenueId, Type, Name, Description, ImagePath, BasePrice, Unit, IsActive, CreatedAt)
    VALUES (3, 1, 'Court', N'Sân bóng đá mini 02', N'Sân cỏ nhân tạo 5 người, hệ thống thoát nước tốt.', '/uploads/products/sandabanh2.png', 250000, N'giờ', 1, GETUTCDATE());
    DECLARE @id7 INT = SCOPE_IDENTITY();
    INSERT INTO CourtProfiles (ProductId, Capacity, Surface, Indoor, SlotMinutes) VALUES (@id7, 10, N'Cỏ nhân tạo', 0, 30);
END

IF NOT EXISTS (SELECT 1 FROM Products WHERE Name = N'Sân bóng đá mini 03 (Sân 7)')
BEGIN
    INSERT INTO Products (CategoryId, VenueId, Type, Name, Description, ImagePath, BasePrice, Unit, IsActive, CreatedAt)
    VALUES (3, 1, 'Court', N'Sân bóng đá mini 03 (Sân 7)', N'Sân thi đấu 7 người, cỏ nhân tạo chuẩn FIFA.', '/uploads/products/sandabanh3.png', 350000, N'giờ', 1, GETUTCDATE());
    DECLARE @id8 INT = SCOPE_IDENTITY();
    INSERT INTO CourtProfiles (ProductId, Capacity, Surface, Indoor, SlotMinutes) VALUES (@id8, 14, N'Cỏ nhân tạo FIFA', 0, 30);
END

IF NOT EXISTS (SELECT 1 FROM Products WHERE Name = N'Sân bóng đá mini 04')
BEGIN
    INSERT INTO Products (CategoryId, VenueId, Type, Name, Description, ImagePath, BasePrice, Unit, IsActive, CreatedAt)
    VALUES (3, 1, 'Court', N'Sân bóng đá mini 04', N'Sân cỏ nhân tạo mới thay sợi mềm, đèn sáng rực.', '/uploads/products/images_1.png', 260000, N'giờ', 1, GETUTCDATE());
    DECLARE @id9 INT = SCOPE_IDENTITY();
    INSERT INTO CourtProfiles (ProductId, Capacity, Surface, Indoor, SlotMinutes) VALUES (@id9, 10, N'Cỏ nhân tạo', 0, 30);
END

IF NOT EXISTS (SELECT 1 FROM Products WHERE Name = N'Sân bóng đá mini 05')
BEGIN
    INSERT INTO Products (CategoryId, VenueId, Type, Name, Description, ImagePath, BasePrice, Unit, IsActive, CreatedAt)
    VALUES (3, 1, 'Court', N'Sân bóng đá mini 05', N'Sân thoáng mát, thích hợp giao lưu văn nghệ thể thao.', '/uploads/products/images_2.png', 240000, N'giờ', 1, GETUTCDATE());
    DECLARE @id10 INT = SCOPE_IDENTITY();
    INSERT INTO CourtProfiles (ProductId, Capacity, Surface, Indoor, SlotMinutes) VALUES (@id10, 10, N'Cỏ nhân tạo', 0, 30);
END

-- 5. Thêm các sản phẩm Dịch vụ (CategoryId: 4)
IF NOT EXISTS (SELECT 1 FROM Products WHERE Name = N'Nước tăng lực Red Bull')
BEGIN
    INSERT INTO Products (CategoryId, VenueId, Type, Name, Description, ImagePath, BasePrice, Unit, IsActive, CreatedAt)
    VALUES (4, 1, 'Service', N'Nước tăng lực Red Bull', N'Bò húc Red Bull lon vàng nhập khẩu.', '/uploads/products/images_9.jpg', 15000, N'lon', 1, GETUTCDATE());
END

IF NOT EXISTS (SELECT 1 FROM Products WHERE Name = N'Gà rán & Khoai tây giòn')
BEGIN
    INSERT INTO Products (CategoryId, VenueId, Type, Name, Description, ImagePath, BasePrice, Unit, IsActive, CreatedAt)
    VALUES (4, 1, 'Service', N'Gà rán & Khoai tây giòn', N'Gà rán giòn rụm kèm sốt tương cà đậm đà.', '/uploads/products/doan3.png', 45000, N'phần', 1, GETUTCDATE());
END

IF NOT EXISTS (SELECT 1 FROM Products WHERE Name = N'Mì trứng xúc xích')
BEGIN
    INSERT INTO Products (CategoryId, VenueId, Type, Name, Description, ImagePath, BasePrice, Unit, IsActive, CreatedAt)
    VALUES (4, 1, 'Service', N'Mì trứng xúc xích', N'Tô mì tôm nóng hổi kèm trứng ốp la và xúc xích.', '/uploads/products/images_10.png', 30000, N'tô', 1, GETUTCDATE());
END

IF NOT EXISTS (SELECT 1 FROM Products WHERE Name = N'Mì xào bò thể thao')
BEGIN
    INSERT INTO Products (CategoryId, VenueId, Type, Name, Description, ImagePath, BasePrice, Unit, IsActive, CreatedAt)
    VALUES (4, 1, 'Service', N'Mì xào bò thể thao', N'Mì xào thịt bò nhiều đạm bổ sung năng lượng.', '/uploads/products/images_11.png', 35000, N'đĩa', 1, GETUTCDATE());
END

IF NOT EXISTS (SELECT 1 FROM Products WHERE Name = N'Set ăn nhẹ vận động viên')
BEGIN
    INSERT INTO Products (CategoryId, VenueId, Type, Name, Description, ImagePath, BasePrice, Unit, IsActive, CreatedAt)
    VALUES (4, 1, 'Service', N'Set ăn nhẹ vận động viên', N'Bữa ăn nhẹ nhanh gọn tiếp sức sau giờ tập luyện.', '/uploads/products/doan2.png', 40000, N'phần', 1, GETUTCDATE());
END

-- Đảm bảo tất cả Court đều có CourtSchedules
INSERT INTO CourtSchedules (CourtId, DayOfWeek, OpenTime, CloseTime)
SELECT p.Id, d.DayOfWeek, '06:00:00', '22:00:00'
FROM Products p
CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6)) AS d(DayOfWeek)
WHERE p.Type = 'Court'
  AND NOT EXISTS (
      SELECT 1 FROM CourtSchedules cs WHERE cs.CourtId = p.Id AND cs.DayOfWeek = d.DayOfWeek
  );
