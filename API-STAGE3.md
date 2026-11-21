# API quản lý danh mục và sân giai đoạn 3

Base URL: `http://localhost:5290/api`. Các API `/admin/...` yêu cầu JWT của Admin. API xác thực giai đoạn 2 giữ nguyên trong `API-STAGE2.md`.

| Method | Route | Request | Response |
|---|---|---|---|
| GET | /category | — | Danh mục đang hoạt động |
| GET | /admin/category | search, pageIndex=1, pageSize=10 | PageResult Category |
| GET | /admin/category/{id} | — | Category |
| POST | /admin/category | Multipart CategoryModel, image tùy chọn | 201 Category |
| PUT | /admin/category/{id} | Multipart CategoryModel, rowVersion bắt buộc | Category |
| DELETE | /admin/category/{id} | Query rowVersion | 204 |
| GET | /product | categoryId, search, pageIndex, pageSize | PageResult ProductDto đang hoạt động |
| GET | /product/{id} | — | ProductDto đang hoạt động |
| GET | /admin/product | categoryId, search, pageIndex, pageSize | PageResult ProductDto gồm cả ngừng hoạt động |
| GET | /admin/product/{id} | — | ProductDto chi tiết |
| POST | /admin/product | Multipart ProductModel, image bắt buộc | 201 ProductDto |
| PUT | /admin/product/{id} | Multipart ProductModel, rowVersion bắt buộc | ProductDto |
| DELETE | /admin/product/{id} | Query rowVersion | 204 |
| GET | /admin/venue | — | Danh sách cơ sở để chọn trong form |

## CategoryModel

Gửi form-data với các trường:

```text
name: Pickleball
description: Sân Pickleball
displayOrder: 2
isActive: true
image: <file PNG/JPEG/WebP, tùy chọn>
rowVersion: <base64 từ GET gần nhất, chỉ khi sửa>
```

Response:

```json
{
  "id": 2,
  "name": "Pickleball",
  "description": "Sân Pickleball",
  "displayOrder": 2,
  "isActive": true,
  "imagePath": "/uploads/categories/<tên-server>.png",
  "rowVersion": "<base64>"
}
```

Không có ảnh mới khi sửa nghĩa là giữ ảnh cũ. Khi xóa danh mục còn bất kỳ sản phẩm nào, API trả 409 CATEGORY_HAS_PRODUCTS và giữ cả bản ghi lẫn ảnh.

## ProductModel

Ví dụ sân, gửi multipart/form-data:

```text
categoryId: 2
venueId: 1
type: Court
name: Sân Pickleball 02
description: Sân có mái che
basePrice: 120000
unit: giờ
isActive: true
capacity: 4
indoor: true
surface: Thảm
openTime: 06:00
closeTime: 22:00
peakStartTime: 17:00
peakEndTime: 21:00
peakPrice: 180000
image: <file, bắt buộc khi tạo>
rowVersion: <base64 khi sửa>
```

Với dịch vụ dùng `type=Service`, ví dụ `unit=chai`, `basePrice=10000`; không cần các trường cấu hình sân. Không đổi Court thành Service hoặc ngược lại sau khi tạo.

Giá trong khoảng 0..100000000. Sức chứa 2..100. Các mốc giờ dùng HH:mm theo bước 30 phút; giờ mở trước giờ đóng, giờ vàng nằm trong giờ mở cửa và có thời lượng dương. Cấu hình form được lưu cho bảy ngày trong tuần. Đơn đã đặt lưu giá riêng, sửa giá sản phẩm không thay giá trong đơn.

Response chi tiết gồm các trường chung id/categoryId/categoryName/venueId/venueName/type/name/description/imagePath/basePrice/unit/isActive/rowVersion. Sân có thêm capacity/indoor/surface/openTime/closeTime/peakStartTime/peakEndTime/peakPrice; các trường này là null với dịch vụ. Danh sách chỉ trả các trường chung, dùng GET chi tiết trước khi mở form sửa.

## Ảnh và tính nhất quán

- PNG/JPEG/WebP tối đa 5 MB/file; giới hạn request 6 MB.
- Server kiểm tra chữ ký file, không tin filename hoặc Content-Type client; không nhận SVG hay URL tải ảnh từ bên ngoài.
- Tên file do server sinh. imagePath là đường dẫn công khai, nối với API_URL để hiển thị.
- Thay/xóa ảnh được ghi vào FileDeletionJobs cùng transaction dữ liệu. Worker xóa sau tối đa khoảng 5 giây nếu không có lỗi I/O; lỗi được thử lại với backoff.
- Upload chưa gắn vào bản ghi có job dọn sau 24 giờ. Cập nhật thất bại dọn ảnh mới ngay khi có thể, còn ảnh đang được tham chiếu luôn được giữ.

## Phiên bản và lỗi

rowVersion lấy từ GET/response mới nhất. Khi gửi query cần URL-encode base64. Client phải tải lại dữ liệu sau 409 DATA_CHANGED, không tự gửi lại bản sửa cũ để ghi đè.

| HTTP | Mã điển hình | Ý nghĩa |
|---|---|---|
| 400 | IMAGE_REQUIRED, INVALID_IMAGE | Thiếu ảnh sản phẩm mới hoặc ảnh quá lớn |
| 400 | INVALID_COURT, INVALID_CATEGORY_OR_VENUE | Cấu hình sân hoặc danh mục/cơ sở không hợp lệ |
| 400 | VERSION_REQUIRED, INVALID_PAGE | Thiếu phiên bản hoặc phân trang sai |
| 401/403 | — | Chưa đăng nhập/thiếu quyền |
| 404 | NOT_FOUND | Không tồn tại hoặc đã bị ẩn trên API công khai |
| 409 | CATEGORY_EXISTS, CATEGORY_HAS_PRODUCTS | Trùng tên danh mục hoặc danh mục còn sản phẩm |
| 409 | PRODUCT_IN_USE, COURT_IN_USE | Sản phẩm/lịch có dữ liệu tham chiếu |
| 409 | ACTIVE_BOOKINGS | Còn đơn chưa kết thúc, chặn đổi lịch/cơ sở/sức chứa hoặc ngừng sân |
| 409 | DATA_CHANGED, IMMUTABLE_TYPE | Dữ liệu cũ hoặc yêu cầu đổi loại sản phẩm |
| 415 | INVALID_IMAGE | Định dạng/chữ ký ảnh không được chấp nhận |

Lỗi validation DTO dùng Problem Details kèm errors. Không dùng các endpoint CRUD này để xác nhận thanh toán hoặc thay đổi đơn hàng.
