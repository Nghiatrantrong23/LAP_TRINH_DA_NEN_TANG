import 'package:flutter/material.dart';

import 'auth_dialog.dart';

import 'session_helper.dart';

class LoginPage extends StatefulWidget {
  final SessionHelper session;
  const LoginPage({super.key, required this.session});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!form.currentState!.validate()) return;
    await signIn(() => widget.session.login(email.text, password.text));
  }

  Future<void> signIn(Future<void> Function() authenticate) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await authenticate();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> recoverPassword() async {
    final repository = widget.session.repository;
    final address = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AuthDialog(
        title: 'Quên mật khẩu',
        action: 'Gửi mã xác nhận',
        label: 'Email',
        email: true,
        initialValue: email.text,
        submit: (value, _) => repository.forgotPassword(value),
      ),
    );
    if (!mounted || address == null) return;
    final completed = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AuthDialog(
        title: 'Nhập mã nếu email đã đăng ký',
        action: 'Đổi mật khẩu',
        label: 'Mã xác nhận',
        newPassword: true,
        submit: (otp, secret) => repository.resetPassword(address, otp, secret),
      ),
    );
    if (!mounted || completed == null) return;
    email.text = address;
    password.clear();
    setState(() => error = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đổi mật khẩu. Bạn có thể đăng nhập.')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đăng nhập')),
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
                const Icon(
                  Icons.sports_tennis,
                  size: 72,
                  color: Color(0xff176448),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      (v ?? '').contains('@') ? null : 'Nhập email hợp lệ',
                ),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  validator: (v) => (v ?? '').isEmpty ? 'Nhập mật khẩu' : null,
                  onFieldSubmitted: (_) {
                    if (!busy) login();
                  },
                ),
                const SizedBox(height: 16),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                FilledButton(
                  onPressed: busy ? null : login,
                  child: Text(busy ? 'Đang đăng nhập…' : 'Đăng nhập'),
                ),
                TextButton(
                  onPressed: busy ? null : recoverPassword,
                  child: const Text('Quên mật khẩu?'),
                ),
                const Text('Đăng nhập demo', textAlign: TextAlign.center),
                for (final (provider, icon) in const [
                  ('Google', Icons.g_mobiledata),
                  ('Facebook', Icons.facebook),
                  ('Zalo', Icons.chat_bubble_outline),
                ])
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => signIn(
                            () => widget.session.externalLogin(provider),
                          ),
                    icon: Icon(icon),
                    label: Text('Đăng nhập với $provider'),
                  ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => Navigator.pushNamed(context, '/register'),
                  child: const Text('Tạo tài khoản mới'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
