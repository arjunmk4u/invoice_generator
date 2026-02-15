import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final StorageService _storage = StorageService.instance;
  final TextEditingController _clientNameController = TextEditingController();
  
  String _invoiceNumber = '';
  DateTime _issueDate = DateTime.now();
  List<InvoiceItem> _items = [];
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadInvoiceNumber();
    _loadUserProfile();
    // Start with empty items template
    _items = [
      InvoiceItem(itemName: '', quantity: 1, pricePerUnit: 0),
    ];
  }

  Future<void> _loadInvoiceNumber() async {
    final number = await _storage.generateNextInvoiceNumber();
    setState(() {
      _invoiceNumber = number;
    });
  }

  Future<void> _loadUserProfile() async {
    final profile = await _storage.getUserProfile();
    setState(() {
      _userProfile = profile;
    });
  }

  double get _grandTotal {
    return _items.fold<double>(0.0, (sum, item) => sum + item.total);
  }

  void _addItem() {
    setState(() {
      _items.add(InvoiceItem(itemName: '', quantity: 1, pricePerUnit: 0));
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    }
  }

  void _updateItem(int index, String name, int qty, double price) {
    setState(() {
      _items[index] = InvoiceItem(
        itemName: name,
        quantity: qty,
        pricePerUnit: price,
      );
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _issueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _issueDate = picked;
      });
    }
  }

  Future<void> _saveInvoice() async {
    if (_clientNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter client name')),
      );
      return;
    }

    if (_items.isEmpty || _items.every((item) => item.itemName.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    // Filter out empty items
    final validItems = _items.where((item) => item.itemName.isNotEmpty).toList();

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one valid item')),
      );
      return;
    }

    try {
      final invoice = Invoice(
        invoiceNumber: _invoiceNumber,
        clientName: _clientNameController.text,
        issueDate: _issueDate,
        status: InvoiceStatus.pending,
        grandTotal: _grandTotal,
        items: validItems,
        notes: '',
      );

      // Save to database
      await _storage.createInvoice(invoice);

      // Generate and print PDF directly (no share dialog)
      if (_userProfile != null) {
        try {
          await PdfService.printPdf(invoice, _userProfile!);
        } catch (e) {
          print('PDF generation error: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Invoice',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Invoice Details Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'INVOICE DETAILS',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      _invoiceNumber,
                      style: const TextStyle(
                        color: Color(0xFF2196F3),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Client Name
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Client Name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _clientNameController,
                        decoration: const InputDecoration(
                          hintText: 'Who is this for?',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Issue Date Only (no due date)
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Invoice Date',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(_issueDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Items Section
                const Text(
                  'ITEMS & SERVICES',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 16),

                // Item List
                ..._items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _ItemCard(
                    item: item,
                    onDelete: () => _removeItem(index),
                    onUpdate: (name, qty, price) =>
                        _updateItem(index, name, qty, price),
                    showDelete: _items.length > 1,
                  );
                }),

                const SizedBox(height: 16),

                // Add More Items Button
                OutlinedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add More Items'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2196F3),
                    side: const BorderSide(
                      color: Color(0xFF2196F3),
                      style: BorderStyle.solid,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _saveInvoice,
                  icon: const Icon(Icons.print),
                  label: const Text('Save & Print Invoice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grand Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${_grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatefulWidget {
  final InvoiceItem item;
  final VoidCallback onDelete;
  final Function(String, int, double) onUpdate;
  final bool showDelete;

  const _ItemCard({
    required this.item,
    required this.onDelete,
    required this.onUpdate,
    required this.showDelete,
  });

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.itemName);
    _quantityController = TextEditingController(
      text: widget.item.quantity > 0 ? widget.item.quantity.toString() : '',
    );
    _priceController = TextEditingController(
      text: widget.item.pricePerUnit > 0 ? widget.item.pricePerUnit.toString() : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _updateItem() {
    final name = _nameController.text;
    final qty = int.tryParse(_quantityController.text) ?? 1;
    final price = double.tryParse(_priceController.text) ?? 0;
    widget.onUpdate(name, qty, price);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Item Name',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              if (widget.showDelete)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          TextField(
            controller: _nameController,
            onChanged: (_) => _updateItem(),
            decoration: const InputDecoration(
              hintText: 'Enter item name',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QUANTITY',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _quantityController,
                      onChanged: (_) => _updateItem(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PRICE/UNIT',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _priceController,
                      onChanged: (_) => _updateItem(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixText: '₹ ',
                        hintText: '0',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${widget.item.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
