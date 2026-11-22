import 'package:flutter/material.dart';
import 'package:sport_booking_app/helpers/helper.dart';
import 'package:sport_booking_app/helpers/session_helper.dart';
import 'package:sport_booking_app/models/member.dart';
import 'package:sport_booking_app/repositories/member_repository.dart';

class ProfilePage extends StatefulWidget {
  final String title;
  const ProfilePage({super.key, required this.title});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Member? _member;
  bool _isLoading = true;

  final _givenNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    String? token = await SessionHelper.token;
    if (token != null) {
      Member? item = await MemberRepository.getProfile(token);
      if (item != null) {
        setState(() {
          _member = item;
          _givenNameController.text = item.givenName;
          _surnameController.text = item.surname ?? '';
          _phoneController.text = item.phone ?? '';
          _isLoading = false;
        });
      }
    }
  }

  void _onSave() async {
    String? token = await SessionHelper.token;
    if (token != null) {
      int ret = await MemberRepository.updateProfile(
        givenName: _givenNameController.text.trim(),
        surname: _surnameController.text.trim(),
        phone: _phoneController.text.trim(),
        token: token,
      );

      if (!mounted) return;
      if (ret > 0) {
        showMessage(context, 'Cập nhật thông tin thành công!');
        _loadProfile();
      } else {
        showMessage(context, 'Cập nhật thất bại', isError: true);
      }
    }
  }

  void _onChangePassword() {
    Navigator.pushNamed(context, '/change-password');
  }

  Widget _loadTable() {
    if (_member == null) return const SizedBox();
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: [
            const Padding(padding: EdgeInsets.all(8.0), child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: const EdgeInsets.all(8.0), child: Text(_member!.email)),
          ],
        ),
        TableRow(
          children: [
            const Padding(padding: EdgeInsets.all(8.0), child: Text('Vai trò', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: Text(_member!.roleName ?? 'Member'),
                backgroundColor: (_member!.roleName?.toLowerCase() == 'admin') ? Colors.red.shade100 : Colors.green.shade100,
              ),
            ),
          ],
        ),
        TableRow(
          children: [
            const Padding(padding: EdgeInsets.all(8.0), child: Text('Xác thực Email', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_member!.isEmailConfirmed ? 'Đã xác thực (Active)' : 'Chưa xác thực',
                  style: TextStyle(color: _member!.isEmailConfirmed ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    child: Icon(Icons.person, size: 45),
                  ),
                  const SizedBox(height: 15),
                  _loadTable(),
                  const SizedBox(height: 20),
                  const Text('Chỉnh sửa thông tin cá nhân', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _surnameController,
                          decoration: const InputDecoration(labelText: 'Họ', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _givenNameController,
                          decoration: const InputDecoration(labelText: 'Tên', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: _onSave,
                    icon: const Icon(Icons.check),
                    label: const Text('LƯU THAY ĐỔI'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _onChangePassword,
                    icon: const Icon(Icons.lock_reset),
                    label: const Text('Đổi mật khẩu tài khoản'),
                  ),
                ],
              ),
            ),
    );
  }
}

