import 'package:flutter/material.dart';
import 'package:sport_booking_app/helpers/helper.dart';
import 'package:sport_booking_app/helpers/session_helper.dart';
import 'package:sport_booking_app/models/member.dart';
import 'package:sport_booking_app/models/role.dart';
import 'package:sport_booking_app/repositories/member_repository.dart';
import 'package:sport_booking_app/repositories/role_repository.dart';

// Quản lý Member (0.25đ) & Phân quyền Role người dùng (0.5đ) - Dành riêng cho Admin
class MemberManagementPage extends StatefulWidget {
  final String title;
  const MemberManagementPage({super.key, required this.title});

  @override
  State<MemberManagementPage> createState() => _MemberManagementPageState();
}

class _MemberManagementPageState extends State<MemberManagementPage> {
  List<Member> _members = [];
  List<Role> _roles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    String? token = await SessionHelper.token;
    if (token != null) {
      var members = await MemberRepository.getMembers(token);
      var roles = await RoleRepository.getRoles(token);
      setState(() {
        _members = members;
        _roles = roles;
        _isLoading = false;
      });
    }
  }

  // Khóa / Mở khóa tài khoản
  void _onToggleStatus(String memberId) async {
    String? token = await SessionHelper.token;
    if (token != null) {
      int ret = await MemberRepository.toggleStatus(memberId, token);
      if (!mounted) return;
      if (ret > 0) {
        showMessage(context, 'Thay đổi trạng thái tài khoản thành công!');
        _loadData();
      } else {
        showMessage(context, 'Không thể thay đổi trạng thái người dùng này', isError: true);
      }
    }
  }

  // Thay đổi Role người dùng qua Dialog
  void _onChangeRole(Member member) async {
    int selectedRoleId = member.roleId;

    var result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Phân quyền: ${member.fullName}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${member.email}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  const Text('Chọn vai trò mới:'),
                  DropdownButtonFormField<int>(
                    initialValue: selectedRoleId,
                    items: _roles.map((p) {
                      return DropdownMenuItem<int>(
                        value: p.roleId,
                        child: Text('${p.roleName} (ID: ${p.roleId})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedRoleId = val);
                      }
                    },
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
                  child: const Text('Lưu quyền'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      String? token = await SessionHelper.token;
      if (token != null && member.memberId != null) {
        int ret = await MemberRepository.changeRole(member.memberId!, selectedRoleId, token);
        if (!mounted) return;
        if (ret > 0) {
          showMessage(context, 'Cập nhật phân quyền thành công!');
          _loadData();
        } else {
          showMessage(context, 'Cập nhật phân quyền thất bại', isError: true);
        }
      }
    }
  }

  Widget _loadTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Họ và tên', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('SĐT', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Vai trò', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _members.map((p) {
          return DataRow(
            cells: [
              DataCell(Text(p.fullName)),
              DataCell(Text(p.email)),
              DataCell(Text(p.phone ?? '-')),
              DataCell(
                Chip(
                  label: Text(p.roleName ?? 'Member'),
                  backgroundColor: p.roleName?.toLowerCase() == 'admin' ? Colors.red.shade100 : Colors.blue.shade100,
                ),
              ),
              DataCell(
                Text(
                  p.isActive ? 'Hoạt động' : 'Đã khóa',
                  style: TextStyle(
                    color: p.isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        p.isActive ? Icons.lock_outline : Icons.lock_open,
                        color: p.isActive ? Colors.red : Colors.green,
                      ),
                      tooltip: p.isActive ? 'Khóa tài khoản' : 'Mở khóa tài khoản',
                      onPressed: () => _onToggleStatus(p.memberId!),
                    ),
                    IconButton(
                      icon: const Icon(Icons.admin_panel_settings, color: Colors.blue),
                      tooltip: 'Phân quyền Role',
                      onPressed: () => _onChangeRole(p),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue.shade50,
                  child: Text(
                    'Tổng số thành viên: ${_members.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(child: SingleChildScrollView(child: _loadTable())),
              ],
            ),
    );
  }
}

