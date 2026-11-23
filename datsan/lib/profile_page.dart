import 'package:flutter/material.dart';

import 'member.dart';
import 'session_helper.dart';
import 'helper.dart';

class ProfilePage extends StatefulWidget {
  final SessionHelper session;
  const ProfilePage({super.key, required this.session});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Member> data;
  final given = TextEditingController(),
      surname = TextEditingController(),
      phone = TextEditingController();
  bool busy = false;
  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    data = widget.session.repository.getMember().then((m) {
      given.text = m.givenName;
      surname.text = m.surname;
      phone.text = m.phone ?? '';
      return m;
    });
  }

  @override
  void dispose() {
    given.dispose();
    surname.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> save(Member current) async {
    setState(() => busy = true);
    try {
      final member = await widget.session.repository.updateMember(
        current,
        given.text,
        surname.text,
        phone.text,
      );
      widget.session.setMember(member);
      if (mounted) {
        showMessage(context, 'Đã lưu thông tin.');
        setState(reload);
      }
    } catch (e) {
      if (mounted) showMessage(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thông tin tài khoản')),
    body: RequestView(
      future: data,
      retry: () => setState(reload),
      builder: (value) {
        final m = value as Member;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(m.email, style: Theme.of(context).textTheme.titleLarge),
            Text('Quyền: ${m.role}'),
            TextField(
              controller: surname,
              maxLength: 50,
              decoration: const InputDecoration(labelText: 'Họ và tên đệm'),
            ),
            TextField(
              controller: given,
              maxLength: 50,
              decoration: const InputDecoration(labelText: 'Tên'),
            ),
            TextField(
              controller: phone,
              maxLength: 20,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
            ),
            FilledButton(
              onPressed: busy ? null : () => save(m),
              child: const Text('Lưu thông tin'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/password'),
              child: const Text('Đổi mật khẩu'),
            ),
          ],
        );
      },
    ),
  );
}
