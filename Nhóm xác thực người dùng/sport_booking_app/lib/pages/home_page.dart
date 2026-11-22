import 'package:flutter/material.dart';
import 'package:sport_booking_app/helpers/helper.dart';
import 'package:sport_booking_app/helpers/session_helper.dart';

// Màn hình chính phân quyền người dùng (Member & Admin) + Logout (0.25đ + 0.5đ)
class HomePage extends StatefulWidget {
  final String title;
  const HomePage({super.key, required this.title});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _email;
  String? _role;
  String? _fullName;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  void _loadSession() async {
    String? email = await SessionHelper.email;
    String? role = await SessionHelper.role;
    String? fullName = await SessionHelper.fullName;
    bool isAdmin = await SessionHelper.isAdmin;

    setState(() {
      _email = email;
      _role = role;
      _fullName = fullName;
      _isAdmin = isAdmin;
    });
  }

  // 6. Chức năng thoát (Logout) - 0.25đ bắt buộc
  void _logout() async {
    await SessionHelper.delete();
    setState(() {
      _email = null;
      _role = null;
      _fullName = null;
      _isAdmin = false;
    });
    if (!mounted) return;
    showMessage(context, 'Đã đăng xuất khỏi hệ thống');
  }

  void _login() async {
    var result = await Navigator.pushNamed(context, '/login');
    if (result == true) {
      _loadSession();
    }
  }

  void _register() async {
    var result = await Navigator.pushNamed(context, '/register');
    if (result == true) {
      _loadSession();
    }
  }

  void _onProfile() async {
    await Navigator.pushNamed(context, '/profile');
    _loadSession();
  }

  void _onMemberManagement() async {
    await Navigator.pushNamed(context, '/admin/members');
  }

  void _onRoleManagement() async {
    await Navigator.pushNamed(context, '/admin/roles');
  }

  void _onChangePassword() async {
    await Navigator.pushNamed(context, '/change-password');
  }

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = _email != null && _email!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: _isAdmin ? Colors.red.shade800 : Colors.green.shade800,
        foregroundColor: Colors.white,
        actions: [
          if (!isLoggedIn) ...[
            ElevatedButton.icon(
              onPressed: _login,
              icon: const Icon(Icons.login),
              label: const Text('Đăng nhập'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _register,
              icon: const Icon(Icons.person_add),
              label: const Text('Đăng ký'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
            ),
            const SizedBox(width: 10),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.account_circle),
              tooltip: 'Hồ sơ cá nhân',
              onPressed: _onProfile,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Đăng xuất',
              onPressed: _logout,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner chào mừng & Thông tin người dùng
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: isLoggedIn ? (_isAdmin ? Colors.red.shade50 : Colors.green.shade50) : Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      _isAdmin ? Icons.admin_panel_settings : Icons.sports_tennis,
                      size: 54,
                      color: _isAdmin ? Colors.red.shade800 : Colors.green.shade800,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLoggedIn ? 'Xin chào, ${_fullName ?? _email}!' : 'HỆ THỐNG ĐẶT SÂN THỂ THAO',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (isLoggedIn) ...[
                      const SizedBox(height: 6),
                      Chip(
                        avatar: Icon(_isAdmin ? Icons.security : Icons.person, size: 18, color: Colors.white),
                        label: Text('Vai trò: ${_role ?? 'Member'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        backgroundColor: _isAdmin ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ] else ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Vui lòng đăng nhập để đặt sân và sử dụng các dịch vụ tiện ích',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 7. PHÂN QUYỀN GIAO DIỆN: ADMIN vs MEMBER
            if (_isAdmin) ...[
              // Giao diện chức năng dành cho ADMIN
              const Text(
                'BẢNG ĐIỀU KHIỂN QUẢN TRỊ VIÊN (ADMIN)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 2,
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.group, color: Colors.white)),
                  title: const Text('Quản lý thành viên (Members)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Xem danh sách, khóa / mở khóa tài khoản, phân quyền Role'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _onMemberManagement,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.security, color: Colors.white)),
                  title: const Text('Quản lý vai trò (Roles)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Thêm, xem, cập nhật và xóa các vai trò trong hệ thống'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _onRoleManagement,
                ),
              ),
            ] else ...[
              // Giao diện chức năng dành cho KHÁCH HÀNG / MEMBER
              const Text(
                'DỊCH VỤ ĐẶT SÂN & TIỆN ÍCH',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildServiceCard('Sân Bóng Đá', Icons.sports_soccer, Colors.green),
                  _buildServiceCard('Sân Cầu Lông', Icons.sports_tennis, Colors.orange),
                  _buildServiceCard('Sân Tennis', Icons.sports_baseball, Colors.blue),
                  _buildServiceCard('Dịch Vụ Đi Kèm', Icons.fastfood, Colors.purple),
                ],
              ),
            ],

            const SizedBox(height: 20),
            if (isLoggedIn) ...[
              const Text('CÀI ĐẶT TÀI KHOẢN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Card(
                elevation: 2,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.badge, color: Colors.blueGrey),
                      title: const Text('Hồ sơ cá nhân'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _onProfile,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_reset, color: Colors.blueGrey),
                      title: const Text('Đổi mật khẩu'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _onChangePassword,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Thoát tài khoản (Logout)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      onTap: _logout,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(String title, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          showMessage(context, 'Bạn đã chọn dịch vụ: $title (Chức năng nhóm Đặt sân)');
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

