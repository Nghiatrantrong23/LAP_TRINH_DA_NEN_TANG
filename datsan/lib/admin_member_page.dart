import 'package:flutter/material.dart';

import 'member.dart';
import 'session_helper.dart';
import 'helper.dart';

class AdminMemberPage extends StatefulWidget {
  final SessionHelper session;
  const AdminMemberPage({super.key, required this.session});
  @override
  State<AdminMemberPage> createState() => _AdminMemberPageState();
}

class _AdminMemberPageState extends State<AdminMemberPage> {
  late Future<dynamic> data;
  final search = TextEditingController();
  int page = 1;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void reload() {
    data = widget.session.repository.getMembers(
      search: search.text,
      pageIndex: page,
    );
  }

  Future<void> access(Member member, String action) async {
    final message = action == 'lock'
        ? (member.isLocked
              ? 'Mở khóa tài khoản này?'
              : 'Khóa tài khoản và thu hồi các phiên đăng nhập?')
        : (member.isAdmin
              ? 'Chuyển tài khoản thành Member?'
              : 'Cấp quyền Admin cho tài khoản này?');
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(member.email),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => busy = true);
    try {
      if (action == 'lock') {
        await widget.session.repository.setLocked(member, !member.isLocked);
      } else {
        await widget.session.repository.setRole(member, member.isAdmin ? 1 : 2);
      }
      if (mounted) setState(reload);
    } catch (e) {
      if (mounted) {
        showMessage(context, e);
        setState(reload);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> edit(Member member) async {
    final given = TextEditingController(text: member.givenName),
        surname = TextEditingController(text: member.surname),
        phone = TextEditingController(text: member.phone ?? '');
    String? error;
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('Sửa thông tin thành viên'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(member.email),
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
                  decoration: const InputDecoration(labelText: 'Điện thoại'),
                ),
                if (error != null) Text(error!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Quay lại'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      update(() => saving = true);
                      try {
                        await widget.session.repository.updateMember(
                          member,
                          given.text,
                          surname.text,
                          phone.text,
                          admin: true,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          update(() {
                            saving = false;
                            error = e.toString();
                          });
                        }
                      }
                    },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    given.dispose();
    surname.dispose();
    phone.dispose();
    if (mounted) setState(reload);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.session,
    builder: (context, _) {
      if (widget.session.member?.isAdmin != true) {
        return Scaffold(
          appBar: AppBar(title: const Text('Quản trị')),
          body: const Center(
            child: Text('Cần đăng nhập bằng tài khoản Admin.'),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Quản lý thành viên')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: search,
                onSubmitted: (_) => setState(() {
                  page = 1;
                  reload();
                }),
                decoration: InputDecoration(
                  labelText: 'Tìm theo tên hoặc email',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() {
                      page = 1;
                      reload();
                    }),
                    icon: const Icon(Icons.search),
                  ),
                ),
              ),
            ),
            if (busy) const LinearProgressIndicator(),
            Expanded(
              child: RequestView(
                future: data,
                retry: () => setState(reload),
                builder: (value) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final raw in value['items'])
                      Builder(
                        builder: (context) {
                          final member = Member.fromMap(raw);
                          final self = member.id == widget.session.member?.id;
                          return Card(
                            child: ListTile(
                              title: Text(member.fullName),
                              subtitle: Text(
                                '${member.email}\n${member.role} • ${member.isLocked ? 'Đã khóa' : 'Hoạt động'}',
                              ),
                              isThreeLine: true,
                              onTap: busy ? null : () => edit(member),
                              trailing: PopupMenuButton<String>(
                                enabled: !busy && !self,
                                onSelected: (a) => access(member, a),
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'lock',
                                    child: Text(
                                      member.isLocked
                                          ? 'Mở khóa'
                                          : 'Khóa tài khoản',
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'role',
                                    child: Text(
                                      member.isAdmin
                                          ? 'Chuyển thành Member'
                                          : 'Cấp quyền Admin',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    if ((value['items'] as List).isEmpty)
                      const Center(child: Text('Không tìm thấy thành viên.')),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: page > 1 && !busy
                              ? () => setState(() {
                                  page--;
                                  reload();
                                })
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          'Trang $page / ${value['totalPages'] == 0 ? 1 : value['totalPages']}',
                        ),
                        IconButton(
                          onPressed: page < value['totalPages'] && !busy
                              ? () => setState(() {
                                  page++;
                                  reload();
                                })
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
