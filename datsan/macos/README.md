# Bản đồ mã nguồn Flutter (trek_bikes_app/lib)

Tất cả các file Dart được tổ chức theo phong cách giảng dạy chuẩn của môn học (đặt trực tiếp trong `lib/`). Danh mục các file theo từng phân hệ chức năng:

---

## 1. Phân hệ Quản lý Đơn hàng (Admin Orders)
* [`order_model.dart`](file:///D:/LTDNT/trek_bikes_app/lib/order_model.dart): Model `OrderModel`, `OrderItemModel` (ánh xạ tiếng Anh/tiếng Việt).
* [`order_repository.dart`](file:///D:/LTDNT/trek_bikes_app/lib/order_repository.dart): Gọi Web API (`api/admin/order`), xử lý tìm kiếm, lọc ngày/trạng thái.
* [`order_management_page.dart`](file:///D:/LTDNT/trek_bikes_app/lib/order_management_page.dart): Giao diện Admin quản lý đơn hàng (thẻ thống kê, lọc, chi tiết, cập nhật trạng thái).

---

## 2. Phân hệ Quản lý Sân bãi & Dịch vụ (Catalog & Products)
* [`product.dart`](file:///D:/LTDNT/trek_bikes_app/lib/product.dart): Model `Product` (Sân Court / Dịch vụ Service).
* [`product_repository.dart`](file:///D:/LTDNT/trek_bikes_app/lib/product_repository.dart): Gọi Web API (`api/product`), upload ảnh.
* [`admin_product_page.dart`](file:///D:/LTDNT/trek_bikes_app/lib/admin_product_page.dart): Giao diện danh sách sân/dịch vụ, tìm kiếm, phân trang.
* [`product_edit_page.dart`](file:///D:/LTDNT/trek_bikes_app/lib/product_edit_page.dart): Form thêm/sửa sân, chọn cơ sở, upload ảnh.

---

## 3. Phân hệ Quản lý Danh mục (Categories)
* [`category.dart`](file:///D:/LTDNT/trek_bikes_app/lib/category.dart): Model danh mục thể thao (Cầu lông, Pickleball, Bóng đá mini...).
* [`category_repository.dart`](file:///D:/LTDNT/trek_bikes_app/lib/category_repository.dart): Gọi Web API (`api/category`).
* [`admin_category_page.dart`](file:///D:/LTDNT/trek_bikes_app/lib/admin_category_page.dart): Giao diện Admin quản lý danh mục.
* [`category_edit_page.dart`](file:///D:/LTDNT/trek_bikes_app/lib/category_edit_page.dart): Form thêm/sửa danh mục kèm ảnh đại diện.

---

## 4. Phân hệ Xác thực & Quản lý Thành viên (Auth & Members)
* [`login.dart`](file:///D:/LTDNT/trek_bikes_app/lib/login.dart), [`login_response.dart`](file:///D:/LTDNT/trek_bikes_app/lib/login_response.dart): Model đăng nhập, token.
* [`login_page.dart`](file:///D:/LTDNT/trek_bikes_app/lib/login_page.dart): Giao diện đăng nhập.
* [`register_page.dart`](file:///D:/LTDNT/trek_bikes_app/lib/register_page.dart): Giao diện đăng ký tài khoản Member.
* [`profile_page.dart`](file:///D:/LTDNT/trek_bikes_app/lib/profile_page.dart): Giao diện hồ sơ cá nhân.
* [`change_password_page.dart`](file:///D:/LTDNT/trek_bikes_app/lib/change_password_page.dart): Giao diện đổi mật khẩu.
* [`member.dart`](file:///D:/LTDNT/trek_bikes_app/lib/member.dart), [`member_repository.dart`](file:///D:/LTDNT/trek_bikes_app/lib/member_repository.dart): Model & Repo thành viên.
* [`admin_member_page.dart`](file:///D:/LTDNT/trek_bikes_app/lib/admin_member_page.dart): Giao diện Admin quản lý thành viên, phân quyền.

---

## 5. Tầng dùng chung (Core & Shared Helpers)
* [`main.dart`](file:///D:/LTDNT/trek_bikes_app/lib/main.dart): Điểm khởi chạy app, cấu hình Routes.
* [`home_page.dart`](file:///D:/LTDNT/trek_bikes_app/lib/home_page.dart): Trang chủ điều hướng theo quyền Member/Admin.
* [`api_client.dart`](file:///D:/LTDNT/trek_bikes_app/lib/api_client.dart): HTTP client tự động gắn JWT Bearer và auto-refresh token.
* [`session_helper.dart`](file:///D:/LTDNT/trek_bikes_app/lib/session_helper.dart): Quản lý phiên đăng nhập và SharedPreferences.
* [`helper.dart`](file:///D:/LTDNT/trek_bikes_app/lib/helper.dart): Các tiện ích định dạng tiền tệ, ngày giờ, thông báo lỗi.
* [`catalog_image.dart`](file:///D:/LTDNT/trek_bikes_app/lib/catalog_image.dart): Widget hiển thị ảnh an toàn từ server.
