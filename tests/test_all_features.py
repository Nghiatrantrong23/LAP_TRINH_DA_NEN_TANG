import argparse
import os
import re
import time
import unittest
from pathlib import Path
from unittest.mock import patch
import urllib.request
import urllib.parse
import json
import uuid

BASE_URL = os.environ.get("SPORTBOOKING_API_URL", "http://localhost:5290/api").rstrip("/")

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

def run_auth_bonus_tests(check, otp_log):
    def auth(route, data=None, token=None):
        return make_request("POST", f"{BASE_URL}/auth/{route}", data, token)

    def read_otp_after(send):
        if otp_log is None:
            status, _ = send()
            if status != 204:
                return status, None
            return status, input("Nhap OTP moi tu console WebApi: ").strip()
        with open(otp_log, "rb") as log:
            log.seek(0, os.SEEK_END)
            status, _ = send()
            if status == 204:
                for _ in range(20):
                    match = re.search(rb"\[OTP CODE: ([0-9]{6})\]", log.read())
                    if match:
                        return status, match[1].decode("ascii")
                    time.sleep(0.1)
            return status, None

    email = f"bonus_{uuid.uuid4().hex}@example.com"
    old_password, new_password = "Old-Test@1234", "New-Test@5678"
    status, _ = auth("register", {"email": email, "givenName": "Bonus", "password": old_password})
    check("Tao tai khoan kiem thu OTP", status in (200, 201))
    status, session = auth("login", {"email": email, "password": old_password})
    token = session.get("token")
    check("Dang nhap truoc khi xac thuc", status == 200 and bool(token) and session.get("member", {}).get("emailConfirmed") is False)
    check("Gui OTP xac thuc yeu cau token", auth("send-verification-email")[0] == 401)
    if not token:
        return
    status, otp = read_otp_after(lambda: auth("send-verification-email", token=token))
    check("Gui va nhan OTP xac thuc", status == 204 and bool(otp))
    if otp:
        wrong = "000000" if otp != "000000" else "000001"
        check("Tu choi OTP xac thuc sai", auth("verify-email", {"otp": wrong}, token)[0] == 400)
        check("Xac thuc email", auth("verify-email", {"otp": otp}, token)[0] == 204)
        check("Khong dung lai OTP xac thuc", auth("verify-email", {"otp": otp}, token)[0] == 400)
        status, profile = make_request("GET", f"{BASE_URL}/member/me", token=token)
        check("Ho so hien email da xac thuc", status == 200 and profile.get("emailConfirmed") is True)

    status, reset_otp = read_otp_after(lambda: auth("forgot-password", {"email": email}))
    check("Gui va nhan OTP dat lai mat khau", status == 204 and bool(reset_otp))
    check("Yeu cau OTP email chua dang ky tra cung ma 204", auth("forgot-password", {"email": f"missing_{email}"})[0] == 204)
    check("Gui lai OTP trong thoi gian cho van tra ma 204", auth("forgot-password", {"email": email})[0] == 204)
    if reset_otp:
        payload = {"email": email, "otp": reset_otp, "newPassword": new_password}
        wrong = "000000" if reset_otp != "000000" else "000001"
        check("Tu choi OTP dat lai mat khau sai", auth("reset-password", dict(payload, otp=wrong))[0] == 400)
        check("Tu choi mat khau qua ngan", auth("reset-password", dict(payload, newPassword="short"))[0] == 400)
        check("Dat lai mat khau bang OTP", auth("reset-password", payload)[0] == 204)
        check("Khong dung lai OTP dat lai mat khau", auth("reset-password", payload)[0] == 400)
        check("Phien cu da bi thu hoi", make_request("GET", f"{BASE_URL}/member/me", token=token)[0] == 401)
        check("Mat khau cu bi tu choi", auth("login", {"email": email, "password": old_password})[0] == 401)
        check("Dang nhap duoc bang mat khau moi", auth("login", {"email": email, "password": new_password})[0] == 200)

    for provider in ("Google", "Facebook", "Zalo"):
        slug = provider.lower()
        payload = {"provider": provider, "email": f"{slug}@sportbooking.invalid", "name": f"{provider} Demo", "providerKey": f"demo-{slug}"}
        status, login = auth("external-login", payload)
        member = login.get("member", {})
        check(f"Dang nhap demo {provider}", status == 200 and bool(login.get("token")) and bool(login.get("refreshToken")) and member.get("role") == "Member" and member.get("emailConfirmed") is True)
        status, again = auth("external-login", payload)
        check(f"Tai su dung tai khoan demo {provider}", status == 200 and bool(member.get("id")) and member["id"] == again.get("member", {}).get("id"))
    check("Tu choi demo dung email tai khoan that", auth("external-login", dict(payload, email=email))[0] == 400)


def run_tests(args):
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

    if args.auth_bonus_only:
        run_auth_bonus_tests(check, args.otp_log)
        print(f"KET QUA AUTH BONUS: {passed}/{total}")
        return passed == total

    # 1. Dang nhap Admin
    status, res = make_request("POST", f"{BASE_URL}/auth/login", {
        "email": "nghiaadmin@gmail.com",
        "password": "147852369"
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
    if args.auth_bonus or args.otp_log:
        run_auth_bonus_tests(check, args.otp_log)

    print(f"KET QUA: {passed}/{total} tinh nang dat chuan")
    print("=" * 60)
    return passed == total

class AuthBonusTests(unittest.TestCase):
    def test_postman_auth_bonus_contract(self):
        path = Path(__file__).resolve().parents[1] / "docs" / "SportBooking_Postman_Collection.json"
        collection = json.loads(path.read_text(encoding="utf-8"))
        auth = next(item for item in collection["item"] if item["name"].endswith("(Auth)"))
        bonus = next(item for item in auth["item"] if item["name"] == "Xác thực email, đặt lại mật khẩu và đăng nhập demo")
        requests = {item["request"]["url"].rsplit("/", 1)[-1]: item["request"] for item in bonus["item"]}
        expected = {
            "send-verification-email": (True, set()),
            "verify-email": (True, {"otp"}),
            "forgot-password": (False, {"email"}),
            "reset-password": (False, {"email", "otp", "newPassword"}),
            "external-login": (False, {"provider", "email", "name", "providerKey"}),
        }
        self.assertEqual(set(requests), set(expected))
        variables = {item["key"] for item in collection["variable"]}
        for route, (protected, fields) in expected.items():
            with self.subTest(route=route):
                request = requests[route]
                self.assertEqual(request["method"], "POST")
                self.assertEqual(request["url"], f"{{{{baseUrl}}}}/auth/{route}")
                self.assertEqual(request.get("auth", {}).get("type") == "bearer", protected)
                raw = request.get("body", {}).get("raw", "{}")
                self.assertEqual(set(json.loads(raw)), fields)
                self.assertLessEqual(set(re.findall(r"\{\{(\w+)\}\}", raw)), variables)

    @patch("urllib.request.urlopen")
    def test_otp_request_preserves_leading_zero_and_accepts_no_content(self, urlopen):
        response = urlopen.return_value.__enter__.return_value
        response.status = 204
        response.read.return_value = b""
        url = "http://example.test/api/auth/verify-email"
        self.assertEqual(make_request("POST", url, {"otp": "012345"}, "test-token"), (204, {}))
        request = urlopen.call_args.args[0]
        self.assertEqual(request.get_method(), "POST")
        self.assertEqual(request.get_header("Authorization"), "Bearer test-token")
        self.assertEqual(json.loads(urlopen.call_args.kwargs["data"]), {"otp": "012345"})


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Kiem thu voi WebApi va SQL Server demo, khong dung du lieu that.")
    parser.add_argument("--auth-bonus", action="store_true", help="Kiem thu ca tinh nang auth bonus, nhap OTP tu console Development")
    parser.add_argument("--auth-bonus-only", action="store_true", help="Chi kiem thu auth bonus, khong can tai khoan admin")
    parser.add_argument("--otp-log", help="Duong dan console log cua WebApi Development de doc OTP tu dong")
    raise SystemExit(0 if run_tests(parser.parse_args()) else 1)
