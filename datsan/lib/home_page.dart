import 'package:flutter/material.dart';
import 'cart_repository.dart';
import 'category.dart';
import 'helper.dart';
import 'product.dart';
import 'product_repository.dart';
import 'session_helper.dart';

class HomePage extends StatefulWidget {
  final String _title;
  final SessionHelper session;
  const HomePage({super.key, required this.session, this._title = 'SportBooking'});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Category> _categories = [];
  List<Product> _products = [];
  int? _categoryId;
  int _page = 1;
  int _totalPages = 1;
  int _cartCount = 0;
  String? _email;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCategories();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() async {
    final member = widget.session.member;
    setState(() {
      _email = member?.email;
    });
    if (member != null) {
      try {
        int count = await CartRepository(widget.session.api).getCount();
        setState(() {
          _cartCount = count;
        });
      } catch (_) {}
    }
  }

  void _loadCategories() async {
    try {
      final res = await widget.session.api.call('GET', '/category');
      if (res is List) {
        setState(() {
          _categories = res.map((e) => Category.fromMap(e as Map<String, dynamic>)).toList();
        });
      }
    } catch (_) {}
  }

  void _loadProducts() async {
    try {
      final res = await ProductRepository(widget.session.api).getProducts(
        search: _searchController.text.trim(),
        page: _page,
        pageSize: 6,
        categoryId: _categoryId,
      );
      if (res['items'] is List) {
        setState(() {
          _products = (res['items'] as List).map((e) => Product.fromMap(e)).toList();
          _totalPages = (res['totalPages'] as int?) ?? 1;
          if (_totalPages < 1) _totalPages = 1;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Text(widget._title),
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((p) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ChoiceChip(
                  label: Text(p.name),
                  selected: _categoryId != null && _categoryId! == p.id,
                  onSelected: (val) {
                    setState(() {
                      _categoryId = val ? p.id : null;
                      _page = 1;
                    });
                    _loadProducts();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          if (_email == null || _email!.isEmpty) ...[
            ElevatedButton.icon(
              onPressed: _login,
              label: const Text('Login'),
              icon: const Icon(Icons.login),
            ),
            ElevatedButton.icon(
              onPressed: _register,
              label: const Text('Register'),
              icon: const Icon(Icons.add),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: _profile,
              label: const Text('Profile'),
              icon: const Icon(Icons.person),
            ),
            ElevatedButton.icon(
              onPressed: _logout,
              label: const Text('Logout'),
              icon: const Icon(Icons.logout),
            ),
            Stack(
              alignment: Alignment.topRight,
              children: [
                ElevatedButton.icon(
                  onPressed: _onCart,
                  label: const Text('Cart'),
                  icon: const Icon(Icons.shopping_cart),
                ),
                if (_cartCount > 0)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_cartCount',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
              ],
            ),
            if (widget.session.member?.isAdmin == true)
              ElevatedButton.icon(
                onPressed: _onInvoice,
                label: const Text('Orders'),
                icon: const Icon(Icons.receipt_long),
              ),
            if (widget.session.member?.isAdmin == true)
              PopupMenuButton<String>(
                icon: const Icon(Icons.admin_panel_settings),
                tooltip: 'Quản trị Admin',
                onSelected: (route) => Navigator.pushNamed(context, route),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: '/admin/category',
                    child: Text('Quản lý danh mục'),
                  ),
                  PopupMenuItem(
                    value: '/admin/product',
                    child: Text('Quản lý sân & dịch vụ'),
                  ),
                  PopupMenuItem(
                    value: '/admin/member',
                    child: Text('Quản lý thành viên'),
                  ),
                  PopupMenuItem(
                    value: '/admin/order',
                    child: Text('Quản lý đơn hàng'),
                  ),
                ],
              ),
          ],
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Tìm kiếm sân, đồ uống, dịch vụ...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      isDense: true,
                    ),
                    onSubmitted: (_) {
                      setState(() => _page = 1);
                      _loadProducts();
                    },
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _page = 1);
                    _loadProducts();
                  },
                  label: const Text('Tìm'),
                  icon: const Icon(Icons.search, size: 18),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              itemCount: _products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemBuilder: (context, index) {
                Product item = _products[index];
                return Column(
                  children: [
                    if (item.imagePath != null && item.imagePath!.isNotEmpty)
                      Image.network(
                        item.imagePath!.startsWith('/')
                            ? '${widget.session.api.baseUrl}${item.imagePath}'
                            : '${widget.session.api.baseUrl}/uploads/${item.imagePath}',
                        width: 120,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) =>
                            const Icon(Icons.sports_tennis, size: 50),
                      )
                    else
                      const Icon(Icons.sports_tennis, size: 50),
                    Text(item.name, overflow: TextOverflow.ellipsis),
                    Text('${item.basePrice.toStringAsFixed(0)} đ/${item.unit}'),
                    ElevatedButton.icon(
                      onPressed: () => _onDetails(item.id),
                      label: const Text('Details'),
                      icon: const Icon(Icons.details),
                    ),
                  ],
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _page > 1
                    ? () {
                        setState(() => _page--);
                        _loadProducts();
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('Trang $_page / $_totalPages'),
              IconButton(
                onPressed: _page < _totalPages
                    ? () {
                        setState(() => _page++);
                        _loadProducts();
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onCart() async {
    await Navigator.pushNamed(context, '/cart');
    _loadData();
  }

  void _onDetails(int id) async {
    await Navigator.pushNamed(context, '/details', arguments: id);
    _loadData();
  }

  void _onInvoice() {
    Navigator.pushNamed(context, '/admin/order');
  }

  void _login() async {
    var result = await Navigator.pushNamed(context, '/login');
    if (result == true) {
      _loadData();
      _loadProducts();
    }
  }

  void _register() {
    Navigator.pushNamed(context, '/register');
  }

  void _logout() async {
    try {
      await widget.session.logout();
    } catch (e) {
      if (mounted) showMessage(context, e);
    }
    setState(() {
      _email = null;
      _cartCount = 0;
    });
  }

  void _profile() async {
    await Navigator.pushNamed(context, '/profile');
  }
}
