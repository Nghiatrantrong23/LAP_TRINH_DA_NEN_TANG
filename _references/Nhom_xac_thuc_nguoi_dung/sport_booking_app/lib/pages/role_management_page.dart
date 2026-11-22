import 'package:flutter/material.dart';
import 'package:sport_booking_app/helpers/helper.dart';
import 'package:sport_booking_app/helpers/session_helper.dart';
import 'package:sport_booking_app/models/role.dart';
import 'package:sport_booking_app/repositories/role_repository.dart';

// Quản lý Role người dùng (0.5 điểm bắt buộc)
class RoleManagementPage extends StatefulWidget {
  final String title;
  const RoleManagementPage({super.key, required this.title});

  @override
  State<RoleManagementPage> createState() => _RoleManagementPageState();
}

class _RoleManagementPageState extends State<RoleManagementPage> {
  List<Role> _roles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  void _loadRoles() async {
    String? token = await SessionHelper.token;
    if (token != null) {
      var list = await RoleRepository.getRoles(token);
      setState(() {
        _roles = list;
        _isLoading = false;
      });
    }
  }

  // Thêm hoặc sửa Role qua Dialog
  void _onOpenRoleDialog({Role? role}) async {
    final nameController = TextEditingController(text: role?.roleName ?? '');
    final descController = TextEditingController(text: role?.description ?? '');

    var result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(role == null ? 'Thêm vai trò mới' : 'Chỉnh sửa vai trò: ${role.roleName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên Role (*)'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Mô tả vai trò'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      String? token = await SessionHelper.token;
      if (token != null) {
        int ret;
        if (role == null) {
          Role newRole = Role(
            roleId: 0,
            roleName: nameController.text.trim(),
            description: descController.text.trim(),
          );
          ret = await RoleRepository.add(newRole, token);
        } else {
          Role updatedRole = Role(
            roleId: role.roleId,
            roleName: nameController.text.trim(),
            description: descController.text.trim(),
          );
          ret = await RoleRepository.update(updatedRole, token);
        }

        if (!mounted) return;
        if (ret > 0) {
          showMessage(context, 'Thao tác vai trò thành công!');
          _loadRoles();
        } else {
          showMessage(context, 'Thao tác thất bại (trùng tên hoặc lỗi hệ thống)', isError: true);
        }
      }
    }
  }

  // Xóa Role
  void _onDelete(int roleId) async {
    var confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa vai trò này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      String? token = await SessionHelper.token;
      if (token != null) {
        int ret = await RoleRepository.delete(roleId, token);
        if (!mounted) return;
        if (ret > 0) {
          showMessage(context, 'Xóa vai trò thành công!');
          _loadRoles();
        } else {
          showMessage(context, 'Không thể xóa vai trò mặc định hoặc đang có người dùng', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onOpenRoleDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm Role'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _roles.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                Role p = _roles[index];
                bool isSystemRole = p.roleId <= 2;
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSystemRole ? Colors.red.shade700 : Colors.teal,
                      child: Text(p.roleId.toString(), style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(p.roleName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(p.description ?? 'Không có mô tả'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _onOpenRoleDialog(role: p),
                        ),
                        if (!isSystemRole)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _onDelete(p.roleId),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

