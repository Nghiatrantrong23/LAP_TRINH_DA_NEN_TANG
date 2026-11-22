import 'package:flutter/material.dart';

class OrderModel {
  final String orderId;
  final String orderNumber;
  final String memberId;
  final int facilityId;
  final String playDate;
  final String customerName;
  final String customerPhone;
  final String status;
  final String statusText;
  final double totalAmount;
  final double depositAmount;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int itemCount;
  final List<OrderItemModel> items;

  OrderModel({
    required this.orderId,
    required this.orderNumber,
    required this.memberId,
    required this.facilityId,
    required this.playDate,
    required this.customerName,
    required this.customerPhone,
    required this.status,
    required this.statusText,
    required this.totalAmount,
    required this.depositAmount,
    this.note,
    required this.createdAt,
    this.updatedAt,
    required this.itemCount,
    required this.items,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    var rawItems = map['chiTiet'] as List<dynamic>? ?? [];
    List<OrderItemModel> parsedItems = rawItems
        .map((e) => OrderItemModel.fromMap(e as Map<String, dynamic>))
        .toList();

    return OrderModel(
      orderId: map['maDonHang']?.toString() ?? '',
      orderNumber: map['soDonHang'] ?? '',
      memberId: map['maThanhVien']?.toString() ?? '',
      facilityId: map['maCoSo'] is int ? map['maCoSo'] : int.tryParse(map['maCoSo']?.toString() ?? '1') ?? 1,
      playDate: map['ngayDatChoi'] ?? '',
      customerName: map['tenKhachHang'] ?? '',
      customerPhone: map['soDienThoaiKhach'] ?? '',
      status: map['trangThai'] ?? 'ChoCoc',
      statusText: map['trangThaiText'] ?? map['trangThai'] ?? '',
      totalAmount: (map['tongTien'] as num?)?.toDouble() ?? 0.0,
      depositAmount: (map['tienCoc'] as num?)?.toDouble() ?? 0.0,
      note: map['ghiChu'],
      createdAt: map['ngayTao'] != null
          ? DateTime.tryParse(map['ngayTao']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['ngayCapNhat'] != null
          ? DateTime.tryParse(map['ngayCapNhat'])
          : null,
      itemCount: (map['soLuongMatHang'] as int?) ?? parsedItems.length,
      items: parsedItems,
    );
  }

  Color get statusColor {
    switch (status) {
      case 'ChoCoc':
        return Colors.orange.shade700;
      case 'DaXacNhan':
        return Colors.blue.shade700;
      case 'DangChoi':
        return Colors.purple.shade700;
      case 'HoanThanh':
        return Colors.green.shade700;
      case 'DaHuy':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color get statusBgColor {
    switch (status) {
      case 'ChoCoc':
        return Colors.orange.shade50;
      case 'DaXacNhan':
        return Colors.blue.shade50;
      case 'DangChoi':
        return Colors.purple.shade50;
      case 'HoanThanh':
        return Colors.green.shade50;
      case 'DaHuy':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'ChoCoc':
        return Icons.hourglass_top;
      case 'DaXacNhan':
        return Icons.verified;
      case 'DangChoi':
        return Icons.sports_tennis;
      case 'HoanThanh':
        return Icons.check_circle;
      case 'DaHuy':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}

class OrderItemModel {
  final int orderItemId;
  final int productId;
  final String productName;
  final String productType; // San, DichVu
  final String unit;
  final int quantity;
  final double? unitPrice;
  final double totalPrice;

  OrderItemModel({
    required this.orderItemId,
    required this.productId,
    required this.productName,
    required this.productType,
    required this.unit,
    required this.quantity,
    this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      orderItemId: (map['maChiTietDon'] as num?)?.toInt() ?? 0,
      productId: (map['maSanPham'] as num?)?.toInt() ?? 0,
      productName: map['tenSanPham'] ?? '',
      productType: map['loaiSanPham'] ?? 'San',
      unit: map['donViTinh'] ?? '',
      quantity: (map['soLuong'] as num?)?.toInt() ?? 1,
      unitPrice: (map['donGia'] as num?)?.toDouble(),
      totalPrice: (map['thanhTien'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get isCourt => productType == 'San';
}

