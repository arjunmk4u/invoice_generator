class InvoiceItem {
  String name;
  int quantity;
  double price;

  InvoiceItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;
}
