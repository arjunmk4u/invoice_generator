import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final Invoice? invoice;
  const CreateInvoiceScreen({super.key, this.invoice});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final StorageService _storage = StorageService.instance;
  
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientEmailController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  String _invoiceNumber = '';
  DateTime _issueDate = DateTime.now();
  List<InvoiceItem> _items = [];
  UserProfile? _userProfile;
  
  bool _isDiscountPercentage = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    if (widget.invoice != null) {
      _invoiceNumber = widget.invoice!.invoiceNumber;
      _clientNameController.text = widget.invoice!.clientName;
      _issueDate = widget.invoice!.issueDate;
      _items = List.from(widget.invoice!.items);
      if (_items.isEmpty) {
        _items = [InvoiceItem(itemName: '', quantity: 1, pricePerUnit: 0)];
      }
    } else {
      _loadInvoiceNumber();
      _items = [
        InvoiceItem(itemName: '', quantity: 1, pricePerUnit: 0),
      ];
    }
    
    _discountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientPhoneController.dispose();
    _discountController.dispose();
    super.dispose();
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

  double get _subtotal {
    return _items.fold<double>(0.0, (sum, item) => sum + item.total);
  }
  
  double get _discountAmount {
    final val = double.tryParse(_discountController.text) ?? 0.0;
    if (_isDiscountPercentage) {
      return _subtotal * (val / 100);
    }
    return val;
  }

  double get _grandTotal {
    final total = _subtotal - _discountAmount;
    return total < 0 ? 0 : total;
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

  void _updateItem(int index, String name, double qty, double price) {
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5A5CE1),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _issueDate = picked;
      });
    }
  }

  Future<void> _saveInvoice({bool printAfter = false}) async {
    if (_clientNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please enter Business Name'), backgroundColor: Colors.red.shade400),
      );
      return;
    }

    final validItems = _items.where((item) => item.itemName.isNotEmpty).toList();

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please add at least one valid item'), backgroundColor: Colors.red.shade400),
      );
      return;
    }

    try {
      final invoice = Invoice(
        id: widget.invoice?.id,
        invoiceNumber: _invoiceNumber,
        clientName: _clientNameController.text,
        issueDate: _issueDate,
        status: widget.invoice?.status ?? InvoiceStatus.pending,
        grandTotal: _grandTotal,
        items: validItems,
        notes: widget.invoice?.notes ?? '', // Just ignore email/phone for now since not in model
      );

      if (widget.invoice != null) {
        await _storage.updateInvoice(invoice);
      } else {
        await _storage.createInvoice(invoice);
      }

      if (printAfter && _userProfile != null) {
        try {
          await PdfService.printPdf(invoice, _userProfile!);
        } catch (e) {
          debugPrint('PDF generation error: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.invoice != null ? 'Invoice updated!' : 'Invoice created!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade400),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(color: const Color(0xFF5A5CE1).withOpacity(0.1), shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF5A5CE1), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          widget.invoice != null ? 'Edit Invoice' : 'Create Invoice',
          style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFF5A5CE1).withOpacity(0.1), shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.more_horiz, color: Color(0xFF5A5CE1), size: 20),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business Details Section
            Row(
              children: [
                Icon(Icons.domain, color: const Color(0xFF5A5CE1), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Business Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Business Name'),
                  _buildTextField(_clientNameController, 'e.g. Nexus Studio LLC'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Email'),
                            _buildTextField(_clientEmailController, 'billing@nexus.com', TextInputType.emailAddress),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Phone'),
                            _buildTextField(_clientPhoneController, '+91 98xxxxx532', TextInputType.phone),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Invoice Info Section
            Row(
              children: [
                Icon(Icons.description, color: const Color(0xFF5A5CE1), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Invoice Info',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Invoice #'),
                        _buildFixedField(_invoiceNumber),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Date'),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: _buildFixedField(DateFormat('MM/dd/yyyy').format(_issueDate)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Line Items
            Row(
              children: [
                Icon(Icons.format_list_bulleted, color: const Color(0xFF5A5CE1), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Line Items',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._items.asMap().entries.map((entry) {
              return _ItemCard(
                item: entry.value,
                onDelete: () => _removeItem(entry.key),
                onUpdate: (name, qty, price) => _updateItem(entry.key, name, qty, price),
                showDelete: _items.length > 1,
              );
            }),
            const SizedBox(height: 4),
            Center(
              child: GestureDetector(
                onTap: _addItem,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A5CE1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Color(0xFF5A5CE1), size: 20),
                      SizedBox(width: 8),
                      Text('Add New Item', style: TextStyle(color: Color(0xFF5A5CE1), fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),

            // Discount Section
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Apply Discount',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
                Row(
                  children: [
                    _buildDiscountToggle('Percentage', _isDiscountPercentage),
                    const SizedBox(width: 8),
                    _buildDiscountToggle('Fixed', !_isDiscountPercentage),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: TextField(
                controller: _discountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Enter ${_isDiscountPercentage ? 'percentage' : 'amount'}',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  suffixText: _isDiscountPercentage ? '%' : '₹',
                  suffixStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Total Card calculation
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text('₹${_subtotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Discount (${_isDiscountPercentage ? '${_discountController.text.isEmpty ? '0' : _discountController.text}%' : 'Fixed'})', 
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      Text('-₹${_discountAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: Colors.white24, height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GRAND TOTAL', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          SizedBox(height: 4),
                          // Placeholder for total amount (updated below)
                        ],
                      ),
                      Icon(Icons.payments_outlined, color: Colors.white.withOpacity(0.5), size: 32),
                    ],
                  ),
                  // Aligning the grand total properly
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('₹${_grandTotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Buttons
            ElevatedButton(
              onPressed: () => _saveInvoice(printAfter: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A5CE1),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, size: 20),
                  SizedBox(width: 8),
                  Text('Save Invoice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _saveInvoice(printAfter: true),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5A5CE1),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: const Color(0xFF5A5CE1).withOpacity(0.2), width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.print, size: 20),
                  SizedBox(width: 8),
                  Text('Print Invoice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountToggle(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isDiscountPercentage = label == 'Percentage';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF5A5CE1) : Colors.grey.shade500,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, [TextInputType? type]) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFixedField(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A))),
    );
  }
}

class _ItemCard extends StatefulWidget {
  final InvoiceItem item;
  final VoidCallback onDelete;
  final Function(String, double, double) onUpdate;
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
  late TextEditingController _qtyController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.itemName);
    _qtyController = TextEditingController(text: widget.item.quantity > 0 ? widget.item.quantity.toString() : '');
    _priceController = TextEditingController(text: widget.item.pricePerUnit > 0 ? widget.item.pricePerUnit.toString() : '');
  }

  void _triggerUpdate() {
    widget.onUpdate(
      _nameController.text,
      double.tryParse(_qtyController.text) ?? 0,
      double.tryParse(_priceController.text) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                    const SizedBox(height: 8),
                    _buildField(_nameController, 'UI/UX Design Services'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Qty', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                    const SizedBox(height: 8),
                    _buildField(_qtyController, '1', type: TextInputType.number),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Price', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                    const SizedBox(height: 8),
                    _buildField(_priceController, '1200', type: TextInputType.number, prefixText: '₹ '),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A5CE1).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL', style: TextStyle(color: Color(0xFF5A5CE1), fontSize: 10, fontWeight: FontWeight.bold)),
                      Text('₹${widget.item.total.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (widget.showDelete)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                  ),
                )
              else
                const SizedBox(width: 48), // Spacer to align
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, {TextInputType? type, String? prefixText}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        onChanged: (_) => _triggerUpdate(),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixText: prefixText,
          prefixStyle: TextStyle(color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
