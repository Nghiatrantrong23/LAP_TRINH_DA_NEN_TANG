import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sport_booking_app/pages/change_password_page.dart';
import 'package:sport_booking_app/pages/forgot_password_page.dart';
import 'package:sport_booking_app/pages/home_page.dart';
import 'package:sport_booking_app/pages/login_page.dart';
import 'package:sport_booking_app/pages/member_management_page.dart';
import 'package:sport_booking_app/pages/order_management_page.dart';
import 'package:sport_booking_app/pages/profile_page.dart';
import 'package:sport_booking_app/pages/register_page.dart';
import 'package:sport_booking_app/pages/role_management_page.dart';
import 'package:sport_booking_app/pages/verify_email_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Không tìm thấy file .env, sử dụng cấu hình mặc định: $e");
  }
  runApp(const SportBookingApp());
}

class SportBookingApp extends StatelessWidget {
  const SportBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đặt Sân Thể Thao & Dịch Vụ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: Colors.green.shade800,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(title: 'Sport Booking'),
        '/login': (context) => const LoginPage(title: 'Đăng nhập'),
        '/register': (context) => const RegisterPage(title: 'Đăng ký thành viên'),
        '/verify-email': (context) => const VerifyEmailPage(title: 'Xác thực Email (OTP)'),
        '/forgot-password': (context) => const ForgotPasswordPage(title: 'Quên mật khẩu'),
        '/change-password': (context) => const ChangePasswordPage(title: 'Đổi mật khẩu'),
        '/profile': (context) => const ProfilePage(title: 'Hồ sơ cá nhân'),
        '/admin/members': (context) => const MemberManagementPage(title: 'Quản lý thành viên'),
        '/admin/roles': (context) => const RoleManagementPage(title: 'Quản lý vai trò (Roles)'),
        '/admin/orders': (context) => const OrderManagementPage(title: 'Quản lý đơn hàng (Admin)'),
      },
    );
  }
}

