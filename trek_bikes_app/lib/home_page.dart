import 'package:flutter/material.dart';

import 'session_helper.dart';
import 'helper.dart';
import 'catalog_image.dart';

class HomePage extends StatefulWidget {
  final SessionHelper session;
  const HomePage({super.key, required this.session});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<dynamic> categories;
  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    categories = widget.session.api.call('GET', '/category');
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.session,
    builder: (context, _) {
      final member = widget.session.member;
      return Scaffold(
        appBar: AppBar(
          title: const Text('SportBooking'),
          actions: [
            if (member != null)
              IconButton(
                tooltip: 'Thông tin tài khoản',
                onPressed: () => Navigator.pushNamed(context, '/profile'),
                icon: const Icon(Icons.account_circle_outlined),
              ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xff124c37),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.sports_tennis, size: 48, color: Colors.white),
                      SizedBox(height: 14),
                      Text(
                        'Kết nối đam mê thể thao',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Cầu lông • Pickleball • Bóng đá mini',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (widget.session.startupError != null)
                  Text(widget.session.startupError!),
                if (!widget.session.ready)
                  const LinearProgressIndicator()
                else if (member == null)
                  Wrap(
                    spacing: 12,
                    children: [
                      FilledButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        child: const Text('Đăng nhập'),
                      ),
                      OutlinedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                        child: const Text('Đăng ký'),
                      ),
                    ],
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào, ${member.fullName}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text('${member.email} • ${member.role}'),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/profile'),
                                child: const Text('Thông tin cá nhân'),
                              ),
                              if (member.isAdmin)
                                FilledButton.tonal(
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    '/admin/member',
                                  ),
                                  child: const Text('Quản lý thành viên'),
                                ),
                              if (member.isAdmin)
                                FilledButton.tonal(
                                  onPressed: () async {
                                    await Navigator.pushNamed(
                                      context,
                                      '/admin/category',
                                    );
                                    if (mounted) setState(reload);
                                  },
                                  child: const Text('Quản lý danh mục'),
                                ),
                              if (member.isAdmin)
                                FilledButton.tonal(
                                  onPressed: () async {
                                    await Navigator.pushNamed(
                                      context,
                                      '/admin/product',
                                    );
                                    if (mounted) setState(reload);
                                  },
                                  child: const Text('Quản lý sân & dịch vụ'),
                                ),
                              if (member.isAdmin)
                                FilledButton.tonal(
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    '/admin/order',
                                  ),
                                  child: const Text('Quản lý đơn hàng'),
                                ),
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await widget.session.logout();
                                  } catch (e) {
                                    if (context.mounted) {
                                      showMessage(context, e);
                                    }
                                  }
                                },
                                child: const Text('Đăng xuất'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  'Danh mục thể thao',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: RequestView(
                    future: categories,
                    retry: () => setState(reload),
                    builder: (value) => ListView(
                      children: [
                        for (final c in value)
                          ListTile(
                            leading: CatalogImage(
                              api: widget.session.api,
                              path: c['imagePath'],
                              size: 42,
                            ),
                            title: Text(c['name']),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
