import 'package:flutter/material.dart';

class AuthDialog extends StatefulWidget {
  final String title, action, label;
  final bool email, newPassword;
  final String initialValue;
  final Future<void> Function(String value, String password) submit;

  const AuthDialog({
    super.key,
    required this.title,
    required this.action,
    required this.label,
    required this.submit,
    this.email = false,
    this.newPassword = false,
    this.initialValue = '',
  });

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  late final value = TextEditingController(text: widget.initialValue);
  final password = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    value.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> confirm() async {
    final input = value.text.trim();
    final valid = widget.email
        ? RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(input)
        : RegExp(r'^[0-9]{6}$').hasMatch(input);
    if (!valid) {
      setState(
        () => error = widget.email
            ? 'Nhập email hợp lệ.'
            : 'Nhập mã gồm 6 chữ số.',
      );
      return;
    }
    if (widget.newPassword && password.text.length < 8) {
      setState(() => error = 'Mật khẩu cần ít nhất 8 ký tự.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.submit(input, password.text);
      if (mounted) Navigator.pop(context, input);
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: Text(widget.title),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: value,
            enabled: !busy,
            keyboardType: widget.email
                ? TextInputType.emailAddress
                : TextInputType.number,
            maxLength: widget.email ? 254 : 6,
            decoration: InputDecoration(labelText: widget.label),
          ),
          if (widget.newPassword)
            TextField(
              controller: password,
              enabled: !busy,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
            ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: busy ? null : confirm,
          child: Text(widget.action),
        ),
      ],
    ),
  );
}
