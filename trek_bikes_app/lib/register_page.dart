import 'package:flutter/material.dart';

import 'member_repository.dart';
import 'helper.dart';

class RegisterPage extends StatefulWidget {
  final MemberRepository repository;
  const RegisterPage({super.key, required this.repository});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController(),
      given = TextEditingController(),
      surname = TextEditingController(),
      phone = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    for (final c in [email, password, confirm, given, surname, phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> register() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repository.register(
        email: email.text,
        password: password.text,
        givenName: given.text,
        surname: surname.text,
        phone: phone.text,
      );
      if (mounted) {
        showMessage(context, 'Đăng ký thành công. Bạn có thể đăng nhập.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đăng ký thành viên')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: surname,
                  maxLength: 50,
                  decoration: const InputDecoration(labelText: 'Họ và tên đệm'),
                ),
                TextFormField(
                  controller: given,
                  maxLength: 50,
                  decoration: const InputDecoration(labelText: 'Tên'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Nhập tên' : null,
                ),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      (v ?? '').contains('@') ? null : 'Nhập email hợp lệ',
                ),
                TextFormField(
                  controller: phone,
                  maxLength: 20,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                ),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  validator: (v) =>
                      (v ?? '').length < 8 ? 'Cần ít nhất 8 ký tự' : null,
                ),
                TextFormField(
                  controller: confirm,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nhập lại mật khẩu',
                  ),
                  validator: (v) =>
                      v != password.text ? 'Mật khẩu không khớp' : null,
                ),
                const SizedBox(height: 16),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
                FilledButton(
                  onPressed: busy ? null : register,
                  child: Text(busy ? 'Đang đăng ký…' : 'Đăng ký'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
