import 'package:cloud_firestore/cloud_firestore.dart';

class Billing {
  final String id;
  final String patientId;
  final String appointmentId;
  final DateTime billDate;
  final double consultationFee;
  final List<BillItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double totalAmount;
  final String paymentStatus; // pending, paid, partial
  final String? paymentMethod;
  final DateTime? paymentDate;

  Billing({
    required this.id,
    required this.patientId,
    required this.appointmentId,
    required this.billDate,
    required this.consultationFee,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.totalAmount,
    required this.paymentStatus,
    this.paymentMethod,
    this.paymentDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'appointmentId': appointmentId,
      'billDate': Timestamp.fromDate(billDate),
      'consultationFee': consultationFee,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate != null
          ? Timestamp.fromDate(paymentDate!)
          : null,
    };
  }

  factory Billing.fromMap(Map<String, dynamic> map) {
    return Billing(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      appointmentId: map['appointmentId'] ?? '',
      billDate: (map['billDate'] as Timestamp).toDate(),
      consultationFee: (map['consultationFee'] ?? 0).toDouble(),
      items: (map['items'] as List)
          .map((item) => BillItem.fromMap(item))
          .toList(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      tax: (map['tax'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      paymentStatus: map['paymentStatus'] ?? 'pending',
      paymentMethod: map['paymentMethod'],
      paymentDate: map['paymentDate'] != null
          ? (map['paymentDate'] as Timestamp).toDate()
          : null,
    );
  }
}

class BillItem {
  final String description;
  final double amount;
  final int quantity;

  BillItem({
    required this.description,
    required this.amount,
    required this.quantity,
  });

  double get total => amount * quantity;

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'amount': amount,
      'quantity': quantity,
    };
  }

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
    );
  }
}