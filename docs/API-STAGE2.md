# API giai đoạn 2

Base URL phát triển: `http://localhost:5290/api`. Token gửi qua `Authorization: Bearer <token>`.

| Method | Route | Request | Response | Quyền |
|---|---|---|---|---|
| POST | /auth/register | email, password, givenName, surname, phone | 201 MemberDto | Public |
| POST | /auth/login | email, password | 200 LoginResponse | Public |
| POST | /auth/refresh | refreshToken | 200 LoginResponse với refresh token mới | Public, refresh token hợp lệ |
| GET | /auth hoặc /auth/me | — | MemberDto | Đăng nhập |
| POST | /auth/logout | — | 204 | Đăng nhập |
| PUT | /auth/password | currentPassword, newPassword | 204, thu hồi mọi phiên | Đăng nhập |
| GET | /member/me | — | MemberDto | Đăng nhập |
| PUT | /member/me | givenName, surname, phone, rowVersion | MemberDto | Đăng nhập |
| GET | /admin/member | search, pageIndex=1, pageSize=10 | PageResult | Admin |
| GET | /admin/member/{id} | — | MemberDto | Admin |
| PUT | /admin/member/{id} | givenName, surname, phone, rowVersion | MemberDto | Admin |
| PUT | /admin/member/{id}/lock | isLocked, rowVersion | MemberDto | Admin |
| PUT | /admin/member/{id}/role | roleId, rowVersion | MemberDto | Admin |
| GET | /admin/role | — | Danh sách Role | Admin |
| GET | /category | — | Danh mục mẫu đang hoạt động | Public |

RoleId 1 = Member; RoleId 2 = Admin. API đăng ký bỏ qua các trường không có trong RegisterModel và luôn gán RoleId=1. Không trả PasswordHash hoặc RefreshTokenHash.

## Đăng ký

```json
{
  "email": "an@example.com",
  "password": "mat-khau-rieng-cua-ban",
  "givenName": "An",
  "surname": "Nguyễn",
  "phone": "0900000000"
}
```

Mật khẩu ít nhất 8 ký tự, tối đa 72 byte UTF-8. Email được chuẩn hóa trước khi kiểm tra trùng.

## Đăng nhập

```json
{
  "email": "an@example.com",
  "password": "mat-khau-rieng-cua-ban"
}
```

Response minh họa; token và ID thực tế được server sinh:

```json
{
  "success": true,
  "message": "Đăng nhập thành công.",
  "token": "<access-token>",
  "refreshToken": "<refresh-token>",
  "expiresAt": "2026-11-21T10:15:00Z",
  "member": {
    "id": "00000000-0000-0000-0000-000000000001",
    "email": "an@example.com",
    "givenName": "An",
    "surname": "Nguyễn",
    "phone": "0900000000",
    "roleId": 1,
    "role": "Member",
    "isLocked": false,
    "emailConfirmed": false,
    "rowVersion": "<base64-rowversion>"
  }
}
```

Sau refresh phải lưu cả hai token mới, thay refresh token cũ. Đăng xuất thu hồi phiên hiện tại; các thiết bị khác vẫn hoạt động. Đổi mật khẩu, khóa hoặc đổi quyền thu hồi mọi phiên cũ.

## Cập nhật quyền

```json
{
  "roleId": 2,
  "rowVersion": "<lấy-từ-response-thành-viên-mới-nhất>"
}
```

Nếu thành viên vừa được cập nhật, rowVersion cũ trả HTTP 409. Client cần tải lại trước khi thực hiện lại thay đổi.

## Phân trang

```json
{
  "items": [],
  "pageIndex": 1,
  "pageSize": 10,
  "totalItems": 0,
  "totalPages": 0
}
```

pageIndex trong 1..1000000, pageSize trong 1..100. Sắp xếp ổn định theo email chuẩn hóa rồi ID.

## Lỗi

```json
{
  "type": "about:blank",
  "title": "Thông tin vừa thay đổi. Vui lòng tải lại.",
  "status": 409,
  "code": "MEMBER_CHANGED"
}
```

- 400: dữ liệu không hợp lệ, sai mật khẩu hiện tại hoặc quyền không tồn tại.
- 401: thông tin đăng nhập/token/phiên không hợp lệ.
- 403: thiếu quyền hoặc tài khoản bị khóa khi đăng nhập.
- 404: thành viên không tồn tại.
- 409: email trùng, cập nhật dữ liệu cũ, tự khóa/hạ quyền hoặc xung đột database.
- 429: vượt 40 yêu cầu auth/phút/IP.

DTO validation trả Problem Details kèm `errors`. Các lỗi SQL bất ngờ được ghi log máy chủ và trả lỗi 500 chung.
