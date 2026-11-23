import 'package:flutter/material.dart';

import 'session_helper.dart';
import 'helper.dart';

class ChangePasswordPage extends StatefulWidget {
  final SessionHelper session;
  const ChangePasswordPage({super.key, required this.session});
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final form = GlobalKey<FormState>();
  final current = TextEditingController(),
      next = TextEditingController(),
      confirm = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.session.changePassword(current.text, next.text);
      if (mounted) {
        Navigator.popUntil(context, (r) => r.isFirst);
        showMessage(context, 'Đã đổi mật khẩu. Vui lòng đăng nhập lại.');
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đổi mật khẩu')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: form,
        child: Column(
          children: [
            TextFormField(
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
              validator: (v) =>
                  (v ?? '').isEmpty ? 'Nhập mật khẩu hiện tại' : null,
            ),
            TextFormField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
              validator: (v) =>
                  (v ?? '').length < 8 ? 'Cần ít nhất 8 ký tự' : null,
            ),
            TextFormField(
              controller: confirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nhập lại mật khẩu mới',
              ),
              validator: (v) => v != next.text ? 'Mật khẩu không khớp' : null,
            ),
            const SizedBox(height: 16),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            FilledButton(
              onPressed: busy ? null : save,
              child: Text(busy ? 'Đang lưu…' : 'Đổi mật khẩu'),
            ),
          ],
        ),
      ),
    ),
  );
}
