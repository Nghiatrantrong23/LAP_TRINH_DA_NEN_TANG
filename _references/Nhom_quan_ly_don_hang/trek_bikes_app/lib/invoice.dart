import 'package:flutter/material.dart';

class Invoice {
  final int id;
  final String? memberId;
  final int statusId;
  final DateTime? dated;
  final String? statusName;
  final List<InvoiceDetail> details;

  Invoice({
    required this.id,
    required this.memberId,
    required this.statusId,
    required this.dated,
    this.statusName,
    this.details = const [],
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'statusId': statusId,
      'dated': dated?.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    var rawDetails = map['details'] as List<dynamic>? ?? [];
    List<InvoiceDetail> parsedDetails = rawDetails
        .map((p) => InvoiceDetail.fromMap(p as Map<String, dynamic>))
        .toList();

    return Invoice(
      id: (map['id'] as num?)?.toInt() ?? 0,
      memberId: map['memberId']?.toString(),
      statusId: (map['statusId'] as num?)?.toInt() ?? 2,
      dated: map['dated'] != null ? DateTime.tryParse(map['dated'].toString()) : null,
      statusName: map['status'] != null ? map['status']['statusName'] : null,
      details: parsedDetails,
    );
  }

  // Tên hiển thị của trạng thái
  String get displayStatusName {
    if (statusName != null && statusName!.isNotEmpty) return statusName!;
    switch (statusId) {
      case 1:
        return 'Cancel';
      case 2:
        return 'Waiting';
      case 3:
        return 'Accepted';
      case 4:
        return 'Shipping';
      case 5:
        return 'Finished';
      default:
        return 'Unknown';
    }
  }

  // Màu sắc trạng thái
  Color get statusColor {
    switch (statusId) {
      case 1:
        return Colors.red.shade700;
      case 2:
        return Colors.orange.shade700;
      case 3:
        return Colors.blue.shade700;
      case 4:
        return Colors.purple.shade700;
      case 5:
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color get statusBgColor {
    switch (statusId) {
      case 1:
        return Colors.red.shade50;
      case 2:
        return Colors.orange.shade50;
      case 3:
        return Colors.blue.shade50;
      case 4:
        return Colors.purple.shade50;
      case 5:
        return Colors.green.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  IconData get statusIcon {
    switch (statusId) {
      case 1:
        return Icons.cancel_outlined;
      case 2:
        return Icons.hourglass_top;
      case 3:
        return Icons.check_circle_outline;
      case 4:
        return Icons.local_shipping_outlined;
      case 5:
        return Icons.verified;
      default:
        return Icons.help_outline;
    }
  }

  double get totalAmount {
    if (details.isEmpty) return 0.0;
    return details.fold(0.0, (sum, item) => sum + item.lineTotal);
  }
}

class InvoiceDetail {
  final int bikeId;
  final String? bikeName;
  final int quantity;
  final double price;

  InvoiceDetail({
    required this.bikeId,
    this.bikeName,
    required this.quantity,
    required this.price,
  });

  factory InvoiceDetail.fromMap(Map<String, dynamic> map) {
    return InvoiceDetail(
      bikeId: (map['bikeId'] as num?)?.toInt() ?? 0,
      bikeName: map['bike'] != null ? map['bike']['bikeName'] : map['bikeName'],
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  double get lineTotal => quantity * price;
}
