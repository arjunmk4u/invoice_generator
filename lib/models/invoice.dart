import 'invoice_item.dart';

class Invoice {
  String invoiceNumber;
  String customerName;
  DateTime date;
  List<InvoiceItem> items;
  String notes;

  Invoice({
    required this.invoiceNumber,
    required this.customerName,
    required this.date,
    required this.items,
    this.notes = '',
  });

  double get subTotal {
    return items.fold(0, (sum, item) => sum + item.total);
  }
}
