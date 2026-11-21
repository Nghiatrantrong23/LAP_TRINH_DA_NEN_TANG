import 'package:flutter/material.dart';
import 'package:sport_booking_app/helpers/helper.dart';
import 'package:sport_booking_app/repositories/auth_repository.dart';

// Màn hình xác thực Email qua OTP (0.5 điểm cộng)
class VerifyEmailPage extends StatefulWidget {
  final String title;
  const VerifyEmailPage({super.key, required this.title});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _codeController = TextEditingController();
  String? _email;
  String? _message;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _email = args;
    }
  }

  void _onVerify() async {
    String code = _codeController.text.trim();
    if (_email == null || _email!.isEmpty || code.isEmpty) {
      setState(() => _message = 'Vui lòng nhập đầy đủ mã OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    var ret = await AuthRepository.verifyEmail(_email!, code);
    setState(() => _isLoading = false);

    if (ret['code'] > 0) {
      if (!mounted) return;
      showMessage(context, 'Xác thực tài khoản thành công! Vui lòng đăng nhập.');
      Navigator.pop(context, true);
    } else {
      setState(() => _message = ret['message']);
    }
  }

  void _onResendCode() async {
    if (_email == null || _email!.isEmpty) return;

    setState(() => _isLoading = true);
    var ret = await AuthRepository.resendCode(_email!);
    setState(() => _isLoading = false);

    if (!mounted) return;
    showMessage(context, ret['message'], isError: ret['code'] < 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.mark_email_read, size: 64, color: Colors.blue),
            const SizedBox(height: 15),
            Text(
              'Xác thực tài khoản cho Email:\n$_email',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '123456',
                labelText: 'Mã xác thực OTP (6 chữ số)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_message != null) ...[
              Text(_message!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
            ],
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _onVerify,
              icon: const Icon(Icons.verified),
              label: const Text('XÁC NHẬN MÃ OTP'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _isLoading ? null : _onResendCode,
              icon: const Icon(Icons.refresh),
              label: const Text('Chưa nhận được mã? Gửi lại OTP'),
            ),
          ],
        ),
      ),
    );
  }
}

