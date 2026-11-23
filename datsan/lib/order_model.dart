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
    var rawItems = (map['chiTiet'] ?? map['items']) as List<dynamic>? ?? [];
    List<OrderItemModel> parsedItems = rawItems
        .map((e) => OrderItemModel.fromMap(e as Map<String, dynamic>))
        .toList();

    return OrderModel(
      orderId: (map['maDonHang'] ?? map['id'])?.toString() ?? '',
      orderNumber: map['soDonHang'] ?? map['orderCode'] ?? '',
      memberId: (map['maThanhVien'] ?? map['memberId'])?.toString() ?? '',
      facilityId: map['maCoSo'] is int
          ? map['maCoSo']
          : int.tryParse((map['maCoSo'] ?? map['venueId'])?.toString() ?? '1') ?? 1,
      playDate: map['ngayDatChoi'] ?? map['bookingDate'] ?? '',
      customerName: map['tenKhachHang'] ?? map['customerName'] ?? '',
      customerPhone: map['soDienThoaiKhach'] ?? map['customerPhone'] ?? '',
      status: map['trangThai'] ?? map['status'] ?? 'ChoCoc',
      statusText: map['trangThaiText'] ?? map['statusText'] ?? map['trangThai'] ?? map['status'] ?? '',
      totalAmount: ((map['tongTien'] ?? map['totalAmount']) as num?)?.toDouble() ?? 0.0,
      depositAmount: ((map['tienCoc'] ?? map['depositAmount']) as num?)?.toDouble() ?? 0.0,
      note: map['ghiChu'] ?? map['note'],
      createdAt: (map['ngayTao'] ?? map['createdAt']) != null
          ? DateTime.tryParse((map['ngayTao'] ?? map['createdAt']).toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: (map['ngayCapNhat'] ?? map['updatedAt']) != null
          ? DateTime.tryParse((map['ngayCapNhat'] ?? map['updatedAt']).toString())
          : null,
      itemCount: (map['soLuongMatHang'] as int?) ?? parsedItems.length,
      items: parsedItems,
    );
  }

  Color get statusColor {
    switch (status) {
      case 'ChoCoc':
      case 'PendingDeposit':
        return Colors.orange.shade700;
      case 'DaXacNhan':
      case 'Confirmed':
        return Colors.blue.shade700;
      case 'DangChoi':
      case 'Playing':
        return Colors.purple.shade700;
      case 'HoanThanh':
      case 'Completed':
        return Colors.green.shade700;
      case 'DaHuy':
      case 'Cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color get statusBgColor {
    switch (status) {
      case 'ChoCoc':
      case 'PendingDeposit':
        return Colors.orange.shade50;
      case 'DaXacNhan':
      case 'Confirmed':
        return Colors.blue.shade50;
      case 'DangChoi':
      case 'Playing':
        return Colors.purple.shade50;
      case 'HoanThanh':
      case 'Completed':
        return Colors.green.shade50;
      case 'DaHuy':
      case 'Cancelled':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'ChoCoc':
      case 'PendingDeposit':
        return Icons.hourglass_top;
      case 'DaXacNhan':
      case 'Confirmed':
        return Icons.verified;
      case 'DangChoi':
      case 'Playing':
        return Icons.sports_tennis;
      case 'HoanThanh':
      case 'Completed':
        return Icons.check_circle;
      case 'DaHuy':
      case 'Cancelled':
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
  final String productType;
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
      orderItemId: ((map['maChiTietDon'] ?? map['id']) as num?)?.toInt() ?? 0,
      productId: ((map['maSanPham'] ?? map['productId']) as num?)?.toInt() ?? 0,
      productName: map['tenSanPham'] ?? map['productName'] ?? '',
      productType: map['loaiSanPham'] ?? map['productType'] ?? 'San',
      unit: map['donViTinh'] ?? map['unit'] ?? '',
      quantity: ((map['soLuong'] ?? map['quantity']) as num?)?.toInt() ?? 1,
      unitPrice: ((map['donGia'] ?? map['unitPrice']) as num?)?.toDouble(),
      totalPrice: ((map['thanhTien'] ?? map['lineTotal']) as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get isCourt => productType == 'San' || productType == 'Court';
}
