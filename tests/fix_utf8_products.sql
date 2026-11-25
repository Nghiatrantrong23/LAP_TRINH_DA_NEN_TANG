-- Fix UTF-8 encoding for all Products
UPDATE Products SET Name = N'Sân cầu lông 01', Description = N'Sân trong nhà, thảm tiêu chuẩn.', Unit = N'giờ' WHERE Id = 1;
UPDATE Products SET Name = N'Sân Pickleball 01', Description = N'Sân có mái che.', Unit = N'giờ' WHERE Id = 2;
UPDATE Products SET Name = N'Sân bóng đá mini 01', Description = N'Sân cỏ nhân tạo 5 người.', Unit = N'giờ' WHERE Id = 3;
UPDATE Products SET Name = N'Nước tăng lực Sting', Description = N'Nước tăng lực Sting dâu ướp lạnh.', Unit = N'chai' WHERE Id = 4;
UPDATE Products SET Name = N'Mẹt đồ ăn vặt', Description = N'Xúc xích, cá viên chiên, khoai tây chiên.', Unit = N'mẹt' WHERE Id = 5;

UPDATE Products SET Name = N'Sân cầu lông 02', Description = N'Sân trong nhà, thảm cao su chống trượt tiêu chuẩn.', Unit = N'giờ' WHERE Id = 10;
UPDATE Products SET Name = N'Sân cầu lông 03 (VIP)', Description = N'Sân thi đấu thảm BWF, ánh sáng chuẩn quốc tế.', Unit = N'giờ' WHERE Id = 11;
UPDATE Products SET Name = N'Sân cầu lông 04 (Trong nhà)', Description = N'Sân rộng thoáng mát, sàn PVC cao cấp.', Unit = N'giờ' WHERE Id = 12;

UPDATE Products SET Name = N'Sân Pickleball 02', Description = N'Sân sơn Acrylic chuyên dụng, độ nảy bóng tốt.', Unit = N'giờ' WHERE Id = 13;
UPDATE Products SET Name = N'Sân Pickleball 03 (Đèn đêm)', Description = N'Sân có hệ thống đèn LED chiếu sáng hiện đại ban đêm.', Unit = N'giờ' WHERE Id = 14;
UPDATE Products SET Name = N'Sân Pickleball 04 (Mái che)', Description = N'Sân Pickleball ngoài trời có mái che tiện lợi.', Unit = N'giờ' WHERE Id = 15;

UPDATE Products SET Name = N'Sân bóng đá mini 02', Description = N'Sân cỏ nhân tạo 5 người, hệ thống thoát nước tốt.', Unit = N'giờ' WHERE Id = 16;
UPDATE Products SET Name = N'Sân bóng đá mini 03 (Sân 7)', Description = N'Sân thi đấu 7 người, cỏ nhân tạo chuẩn FIFA.', Unit = N'giờ' WHERE Id = 17;
UPDATE Products SET Name = N'Sân bóng đá mini 04', Description = N'Sân cỏ nhân tạo mới thay sợi mềm, đèn sáng rực.', Unit = N'giờ' WHERE Id = 18;
UPDATE Products SET Name = N'Sân bóng đá mini 05', Description = N'Sân thoáng mát, thích hợp giao lưu văn nghệ thể thao.', Unit = N'giờ' WHERE Id = 19;

UPDATE Products SET Name = N'Nước tăng lực Red Bull', Description = N'Bò húc Red Bull lon vàng nhập khẩu.', Unit = N'lon' WHERE Id = 20;
UPDATE Products SET Name = N'Gà rán & Khoai tây giòn', Description = N'Gà rán giòn rụm kèm sốt tương cà đậm đà.', Unit = N'phần' WHERE Id = 21;
UPDATE Products SET Name = N'Mì trứng xúc xích', Description = N'Tô mì tôm nóng hổi kèm trứng ốp la và xúc xích.', Unit = N'phần' WHERE Id = 22;
UPDATE Products SET Name = N'Mì xào bò thể thao', Description = N'Mì xào thịt bò nhiều đạm bổ sung năng lượng.', Unit = N'phần' WHERE Id = 23;
UPDATE Products SET Name = N'Set ăn nhẹ vận động viên', Description = N'Bữa ăn nhẹ nhanh gọn tiếp sức sau giờ tập luyện.', Unit = N'phần' WHERE Id = 24;

-- Fix UTF-8 encoding for CourtProfiles
UPDATE CourtProfiles SET Surface = N'Thảm tiêu chuẩn' WHERE ProductId = 1;
UPDATE CourtProfiles SET Surface = N'Sân cứng ngoài trời' WHERE ProductId = 2;
UPDATE CourtProfiles SET Surface = N'Cỏ nhân tạo' WHERE ProductId = 3;
UPDATE CourtProfiles SET Surface = N'Thảm cao su' WHERE ProductId = 10;
UPDATE CourtProfiles SET Surface = N'Thảm BWF' WHERE ProductId = 11;
UPDATE CourtProfiles SET Surface = N'Sàn PVC' WHERE ProductId = 12;
UPDATE CourtProfiles SET Surface = N'Sơn Acrylic' WHERE ProductId = 13;
UPDATE CourtProfiles SET Surface = N'Sân tiêu chuẩn' WHERE ProductId = 14;
UPDATE CourtProfiles SET Surface = N'Sơn Acrylic' WHERE ProductId = 15;
UPDATE CourtProfiles SET Surface = N'Cỏ nhân tạo' WHERE ProductId = 16;
UPDATE CourtProfiles SET Surface = N'Cỏ nhân tạo FIFA' WHERE ProductId = 17;
UPDATE CourtProfiles SET Surface = N'Cỏ nhân tạo' WHERE ProductId = 18;
UPDATE CourtProfiles SET Surface = N'Cỏ nhân tạo' WHERE ProductId = 19;
