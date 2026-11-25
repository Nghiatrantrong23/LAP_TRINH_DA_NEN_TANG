import pyodbc
import datetime

# Kết nối SQL Server
conn_str = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=SportsBookingStage2;"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
)

conn = pyodbc.connect(conn_str, autocommit=True)
cursor = conn.cursor()

print("Dang cap nhat hinh anh va them san pham...")

# 1. Cap nhat cac san pham 1-5 da co
cursor.execute("""
UPDATE Products 
SET Name = N'Sân cầu lông 01', ImagePath = '/uploads/products/sancaulong1.png', BasePrice = 80000, Unit = N'giờ'
WHERE Id = 1;
""")

cursor.execute("""
UPDATE Products 
SET Name = N'Sân Pickleball 01', ImagePath = '/uploads/products/download.png', BasePrice = 120000, Unit = N'giờ'
WHERE Id = 2;
""")

cursor.execute("""
UPDATE Products 
SET Name = N'Sân bóng đá mini 01', ImagePath = '/uploads/products/sandabanh1.png', BasePrice = 250000, Unit = N'giờ'
WHERE Id = 3;
""")

cursor.execute("""
UPDATE Products 
SET Name = N'Nước tăng lực Sting', ImagePath = '/uploads/products/images_8.jpg', BasePrice = 12000, Unit = N'chai', Description = N'Nước tăng lực Sting dâu ướp lạnh'
WHERE Id = 4;
""")

cursor.execute("""
UPDATE Products 
SET Name = N'Mẹt đồ ăn vặt', ImagePath = '/uploads/products/doan1.png', BasePrice = 55000, Unit = N'mẹt', Description = N'Xúc xích, cá viên chiên, khoai tây chiên'
WHERE Id = 5;
""")

# Danh sach cac san pham moi can bo sung
new_products = [
    # Cầu lông (CategoryId: 1)
    (1, 1, "Court", "Sân cầu lông 02", "Sân trong nhà, thảm cao su chống trượt tiêu chuẩn.", "/uploads/products/sancaulong2.png", 80000, "giờ", 4, "Thảm cao su", True),
    (1, 1, "Court", "Sân cầu lông 03 (VIP)", "Sân thi đấu thảm BWF, ánh sáng chuẩn quốc tế.", "/uploads/products/sancaulong3.png", 90000, "giờ", 4, "Thảm BWF", True),
    (1, 1, "Court", "Sân cầu lông 04 (Trong nhà)", "Sân rộng thoáng mát, sàn PVC cao cấp.", "/uploads/products/images_5.png", 85000, "giờ", 4, "Sàn PVC", True),

    # Pickleball (CategoryId: 2)
    (2, 1, "Court", "Sân Pickleball 02", "Sân sơn Acrylic chuyên dụng, độ nảy bóng tốt.", "/uploads/products/download_1.png", 120000, "giờ", 4, "Sơn Acrylic", False),
    (2, 1, "Court", "Sân Pickleball 03 (Đèn đêm)", "Sân có hệ thống đèn LED chiếu sáng hiện đại ban đêm.", "/uploads/products/images.png", 140000, "giờ", 4, "Sân tiêu chuẩn", False),
    (2, 1, "Court", "Sân Pickleball 04 (Mái che)", "Sân Pickleball ngoài trời có mái che tiện lợi.", "/uploads/products/download.jpg", 120000, "giờ", 4, "Sơn Acrylic", True),

    # Bóng đá mini (CategoryId: 3)
    (3, 1, "Court", "Sân bóng đá mini 02", "Sân cỏ nhân tạo 5 người, hệ thống thoát nước tốt.", "/uploads/products/sandabanh2.png", 250000, "giờ", 10, "Cỏ nhân tạo", False),
    (3, 1, "Court", "Sân bóng đá mini 03 (Sân 7)", "Sân thi đấu 7 người, cỏ nhân tạo chuẩn FIFA.", "/uploads/products/sandabanh3.png", 350000, "giờ", 14, "Cỏ nhân tạo FIFA", False),
    (3, 1, "Court", "Sân bóng đá mini 04", "Sân cỏ nhân tạo mới thay sợi mềm, đèn sáng rực.", "/uploads/products/images_1.png", 260000, "giờ", 10, "Cỏ nhân tạo", False),
    (3, 1, "Court", "Sân bóng đá mini 05", "Sân thoáng mát, thích hợp giao lưu văn nghệ thể thao.", "/uploads/products/images_2.png", 240000, "giờ", 10, "Cỏ nhân tạo", False),

    # Dịch vụ (CategoryId: 4)
    (4, 1, "Service", "Nước tăng lực Red Bull", "Bò húc Red Bull lon vàng nhập khẩu.", "/uploads/products/images_9.jpg", 15000, "lon", 0, "", False),
    (4, 1, "Service", "Gà rán & Khoai tây giòn", "Gà rán giòn rụm kèm sốt tương cà đậm đà.", "/uploads/products/doan3.png", 45000, "phần", 0, "", False),
    (4, 1, "Service", "Mì trứng xúc xích", "Tô mì tôm nóng hổi kèm trứng ốp la và xúc xích.", "/uploads/products/images_10.png", 30000, "tô", 0, "", False),
    (4, 1, "Service", "Mì xào bò thể thao", "Mì xào thịt bò nhiều đạm bổ sung năng lượng.", "/uploads/products/images_11.png", 35000, "đĩa", 0, "", False),
    (4, 1, "Service", "Set ăn nhẹ vận động viên", "Bữa ăn nhẹ nhanh gọn tiếp sức sau giờ tập luyện.", "/uploads/products/doan2.png", 40000, "phần", 0, "", False),
]

for cat_id, venue_id, p_type, name, desc, img, price, unit, cap, surface, indoor in new_products:
    cursor.execute("SELECT Id FROM Products WHERE Name = ?", (name,))
    row = cursor.fetchone()
    if row:
        prod_id = row[0]
        cursor.execute("""
            UPDATE Products 
            SET ImagePath = ?, BasePrice = ?, Unit = ?, Description = ?, CategoryId = ?, Type = ?
            WHERE Id = ?
        """, (img, price, unit, desc, cat_id, p_type, prod_id))
        print(f"Cap nhat san pham: {name} (Id: {prod_id})")
    else:
        cursor.execute("""
            INSERT INTO Products (CategoryId, VenueId, Type, Name, Description, ImagePath, BasePrice, Unit, IsActive, CreatedAt)
            OUTPUT INSERTED.Id
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, GETUTCDATE())
        """, (cat_id, venue_id, p_type, name, desc, img, price, unit))
        prod_id = cursor.fetchone()[0]
        print(f"Them moi san pham: {name} (Id: {prod_id})")

    # Neu la Court thi them/cap nhat CourtProfile va CourtSchedule
    if p_type == "Court":
        cursor.execute("SELECT ProductId FROM CourtProfiles WHERE ProductId = ?", (prod_id,))
        if not cursor.fetchone():
            cursor.execute("""
                INSERT INTO CourtProfiles (ProductId, Capacity, Surface, Indoor, SlotMinutes)
                VALUES (?, ?, ?, ?, 30)
            """, (prod_id, cap, surface, 1 if indoor else 0))

        # Schedules
        for day in range(7):
            cursor.execute("SELECT CourtId FROM CourtSchedules WHERE CourtId = ? AND DayOfWeek = ?", (prod_id, day))
            if not cursor.fetchone():
                cursor.execute("""
                    INSERT INTO CourtSchedules (CourtId, DayOfWeek, OpenTime, CloseTime)
                    VALUES (?, ?, '06:00:00', '22:00:00')
                """, (prod_id, day))

print("HOAN TAT! Tat ca hinh anh va san pham da duoc cap nhat day du vao Database.")
conn.close()
