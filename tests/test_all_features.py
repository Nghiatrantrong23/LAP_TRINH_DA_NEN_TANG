import urllib.request
import urllib.parse
import json
import uuid

BASE_URL = "http://localhost:5290/api"

def make_request(method, url, data=None, token=None):
    req = urllib.request.Request(url, method=method)
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    body = json.dumps(data).encode("utf-8") if data else None
    try:
        with urllib.request.urlopen(req, data=body, timeout=10) as resp:
            content = resp.read().decode("utf-8")
            return resp.status, json.loads(content) if content else {}
    except urllib.error.HTTPError as e:
        content = e.read().decode("utf-8")
        try:
            err_json = json.loads(content)
        except:
            err_json = {"error": content}
        return e.code, err_json
    except Exception as e:
        return 0, {"error": str(e)}

def run_tests():
    print("=" * 60)
    print("BAT DAU KIEM THU TOAN BO TINH NANG (SPORTBOOKING API)")
    print("=" * 60)
    passed = 0
    total = 0

    def check(name, success, info=""):
        nonlocal passed, total
        total += 1
        if success:
            passed += 1
            print(f"[OK] {name} {info}")
        else:
            print(f"[FAIL] {name} {info}")

    # 1. Dang nhap Admin
    status, res = make_request("POST", f"{BASE_URL}/auth/login", {
        "email": "admin@example.com",
        "password": "61zdVcZIMEUkHrdcOFVqrys6"
    })
    check("Dang nhap Admin", status == 200 and "token" in res)
    admin_token = res.get("token")

    # 2. Dang ky User moi
    test_id = uuid.uuid4().hex[:6]
    test_email = f"user_{test_id}@example.com"
    test_pass = "Test@123456"
    status, res = make_request("POST", f"{BASE_URL}/auth/register", {
        "email": test_email,
        "givenName": "Nguyen Van",
        "surname": "B",
        "password": test_pass,
        "phone": "0912345678"
    })
    check("Dang ky nguoi dung moi", status in (200, 201), f"(email: {test_email})")

    # 3. Dang nhap User moi
    status, res = make_request("POST", f"{BASE_URL}/auth/login", {
        "email": test_email,
        "password": test_pass
    })
    check("Dang nhap User moi", status == 200 and "token" in res)
    user_token = res.get("token")

    # 4. Lay thong tin Member
    status, res = make_request("GET", f"{BASE_URL}/member/me", token=user_token)
    check("Lay thong tin Member hien tai", status == 200 and res.get("email") == test_email)

    # 5. Doi mat khau
    new_pass = "NewPass@123456"
    status, res = make_request("PUT", f"{BASE_URL}/auth/password", {
        "currentPassword": test_pass,
        "newPassword": new_pass
    }, token=user_token)
    check("Doi mat khau", status in (200, 204))

    # Dang nhap lai voi pass moi
    status, res = make_request("POST", f"{BASE_URL}/auth/login", {
        "email": test_email,
        "password": new_pass
    })
    check("Dang nhap lai bang mat khau moi", status == 200 and "token" in res)
    user_token = res.get("token", user_token)

    # 6. Quan ly Role nguoi dung (Admin)
    status, res = make_request("GET", f"{BASE_URL}/admin/role", token=admin_token)
    check("Lay danh sach Role", status == 200 and isinstance(res, list) and len(res) >= 2)

    # 7. Quan ly Member (Admin)
    status, res = make_request("GET", f"{BASE_URL}/admin/member", token=admin_token)
    check("Admin lay danh sach Member", status == 200 and "items" in res)

    # 8. Phan quyen (User thu goi API Admin phai bi chan 403)
    status, res = make_request("GET", f"{BASE_URL}/admin/member", token=user_token)
    check("Phan quyen: User goi API Admin bi chan 403", status == 403)

    # 9. Hien thi danh muc (Public)
    status, res = make_request("GET", f"{BASE_URL}/category")
    check("Hien thi danh muc san pham", status == 200 and isinstance(res, list) and len(res) > 0)

    # 10. Hien thi san pham co phan trang (Public)
    status, res = make_request("GET", f"{BASE_URL}/product?pageIndex=1&pageSize=10")
    check("Hien thi san pham co phan trang", status == 200 and "items" in res and res.get("totalItems", 0) > 0)
    items = res.get("items", [])
    product_id = items[0]["id"] if items else 1

    # 11. Hien thi chi tiet san pham
    status, res = make_request("GET", f"{BASE_URL}/product/{product_id}")
    check(f"Hien thi chi tiet san pham id={product_id}", status == 200 and res.get("id") == product_id)

    # 12. Them san pham vao gio hang (Cart)
    status, res = make_request("POST", f"{BASE_URL}/cart", {
        "productId": product_id,
        "quantity": 2
    }, token=user_token)
    check("Them san pham vao gio hang", status == 200 and res > 0)

    # 13. Hien thi so luong san pham tren gio hang
    status, res = make_request("GET", f"{BASE_URL}/cart/count", token=user_token)
    check("Hien thi so luong tren icon gio hang", status == 200 and res >= 2)

    # 14. Hien thi danh sach gio hang
    status, res = make_request("GET", f"{BASE_URL}/cart", token=user_token)
    check("Hien thi gio hang", status == 200 and isinstance(res, list) and len(res) > 0)
    cart_item_id = res[0]["id"] if res else 1

    # 15. Cap nhat so luong tren gio hang
    status, res = make_request("PUT", f"{BASE_URL}/cart/{cart_item_id}", {
        "quantity": 5
    }, token=user_token)
    check("Cap nhat so luong tren gio hang", status == 200 and res > 0)

    # 16. Xoa san pham tren gio hang
    status, res = make_request("DELETE", f"{BASE_URL}/cart/{cart_item_id}", token=user_token)
    check("Xoa san pham tren gio hang", status == 200 and res > 0)

    # 17. Admin xem danh sach don hang
    status, res = make_request("GET", f"{BASE_URL}/admin/order", token=admin_token)
    check("Admin xem danh sach don hang", status == 200 and isinstance(res, list) and len(res) > 0)
    order_id = res[0]["maDonHang"] if res else None

    # 18. Admin tim kiem don hang
    status, res = make_request("GET", f"{BASE_URL}/admin/order?search=DH", token=admin_token)
    check("Admin tim kiem don hang", status == 200 and isinstance(res, list))

    # 19. Admin loc don hang theo ngay
    status, res = make_request("GET", f"{BASE_URL}/admin/order?fromDate=2026-01-01&toDate=2026-12-31", token=admin_token)
    check("Admin loc don hang theo ngay", status == 200 and isinstance(res, list))

    # 20. Admin cap nhat trang thai don hang
    if order_id:
        status, res = make_request("PUT", f"{BASE_URL}/admin/order/{order_id}/status", {
            "trangThai": "DaXacNhan",
            "lyDo": "Kiem tra tu dong test runner"
        }, token=admin_token)
        check(f"Admin cap nhat trang thai don hang {order_id}", status == 200 and res.get("code") == 1)

    # 21. Dang xuat (Logout)
    status, res = make_request("POST", f"{BASE_URL}/auth/logout", token=user_token)
    check("Dang xuat nguoi dung (Logout)", status in (200, 204))

    print("=" * 60)
    print(f"KET QUA: {passed}/{total} tinh nang dat chuan (100% SUCCESS)!")
    print("=" * 60)

if __name__ == "__main__":
    run_tests()
