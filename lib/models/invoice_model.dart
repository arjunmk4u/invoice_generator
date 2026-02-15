class Invoice {
  final int? id;
  final String invoiceNumber;
  final String clientName;
  final DateTime issueDate;
  final InvoiceStatus status;
  final double grandTotal;
  final String? notes;
  final List<InvoiceItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.clientName,
    required this.issueDate,
    required this.status,
    required this.grandTotal,
    this.notes,
    required this.items,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Compatibility getters for pdf_service.dart
  String get customerName => clientName;
  DateTime get date => issueDate;
  double get subTotal => grandTotal;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'clientName': clientName,
      'issueDate': issueDate.toIso8601String(),
      'status': status.name,
      'grandTotal': grandTotal,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, List<InvoiceItem> items) {
    return Invoice(
      id: map['id'] as int?,
      invoiceNumber: map['invoiceNumber'] as String,
      clientName: map['clientName'] as String,
      issueDate: DateTime.parse(map['issueDate'] as String),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InvoiceStatus.pending,
      ),
      grandTotal: map['grandTotal'] as double,
      notes: map['notes'] as String?,
      items: items,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    String? clientName,
    DateTime? issueDate,
    InvoiceStatus? status,
    double? grandTotal,
    String? notes,
    List<InvoiceItem>? items,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      clientName: clientName ?? this.clientName,
      issueDate: issueDate ?? this.issueDate,
      status: status ?? this.status,
      grandTotal: grandTotal ?? this.grandTotal,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static String generateInvoiceNumber(int count) {
    final year = DateTime.now().year;
    final number = (count + 1).toString().padLeft(3, '0');
    return 'INV-$year-$number';
  }

  bool get isOverdue {
    return status != InvoiceStatus.paid && DateTime.now().isAfter(issueDate.add(const Duration(days: 30)));
  }
}

class InvoiceItem {
  final int? id;
  final int? invoiceId;
  final String itemName;
  final int quantity;
  final double pricePerUnit;
  final double total;

  InvoiceItem({
    this.id,
    this.invoiceId,
    required this.itemName,
    required this.quantity,
    required this.pricePerUnit,
  }) : total = quantity * pricePerUnit;

  // Compatibility getters for pdf_service.dart
  String get name => itemName;
  double get price => pricePerUnit;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'itemName': itemName,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'total': total,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as int?,
      invoiceId: map['invoiceId'] as int?,
      itemName: map['itemName'] as String,
      quantity: map['quantity'] as int,
      pricePerUnit: map['pricePerUnit'] as double,
    );
  }

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    String? itemName,
    int? quantity,
    double? pricePerUnit,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
    );
  }
}

enum InvoiceStatus {
  draft,
  pending,
  paid,
  overdue,
}

extension InvoiceStatusExtension on InvoiceStatus {
  String get displayName {
    switch (this) {
      case InvoiceStatus.draft:
        return 'DRAFT';
      case InvoiceStatus.pending:
        return 'PENDING';
      case InvoiceStatus.paid:
        return 'PAID';
      case InvoiceStatus.overdue:
        return 'OVERDUE';
    }
  }
}
