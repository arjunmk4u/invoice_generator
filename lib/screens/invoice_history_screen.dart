import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import 'create_invoice_screen.dart';
import 'invoice_preview_screen.dart';

class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  final StorageService _storage = StorageService.instance;
  List<Invoice> _invoices = [];
  String _searchQuery = '';
  String _selectedFilter = 'All';
  DateTimeRange? _dateRange;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final invoices = await _storage.getAllInvoices();
      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Invoice> get _filteredInvoices {
    return _invoices.where((inv) {
      final matchesSearch = inv.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inv.clientName.toLowerCase().contains(_searchQuery.toLowerCase());
      
      if (!matchesSearch) return false;

      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Pending') {
        return inv.status == InvoiceStatus.pending;
      }
      if (_selectedFilter == 'Paid') return inv.status == InvoiceStatus.paid;
      if (_selectedFilter == 'Overdue') return inv.status == InvoiceStatus.overdue;
      if (_selectedFilter == 'Date' && _dateRange != null) {
        return !inv.issueDate.isBefore(_dateRange!.start) &&
            !inv.issueDate.isAfter(_dateRange!.end.add(const Duration(days: 1)));
      }
      
      return true;
    }).toList();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF5A5CE1)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _selectedFilter = 'Date';
      });
    }
  }

  Future<void> _navigateToCreateInvoice() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateInvoiceScreen()),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _viewInvoice(Invoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoicePreviewScreen(invoice: invoice),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final displayedInvoices = _filteredInvoices;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final bgText = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final inputBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FA),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateInvoice,
        backgroundColor: const Color(0xFF5A5CE1),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: const Color(0xFF5A5CE1),
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invoices',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: bgText,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Search and Filter button Row
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: inputBg,
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      onChanged: (val) => setState(() => _searchQuery = val),
                                      decoration: InputDecoration(
                                        hintText: 'Search invoices...',
                                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  height: 56,
                                  width: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5A5CE1),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF5A5CE1).withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.tune, color: Colors.white),
                                    onPressed: _pickDateRange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Filters row
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip('All'),
                                  const SizedBox(width: 12),
                                  _buildFilterChip('Pending'),
                                  const SizedBox(width: 12),
                                  _buildFilterChip('Paid'),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: _pickDateRange,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _selectedFilter == 'Date' ? const Color(0xFF5A5CE1) : Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        border: _selectedFilter == 'Date'
                                            ? null
                                            : Border.all(color: Colors.grey.shade200, width: 1.5),
                                        boxShadow: _selectedFilter == 'Date'
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF5A5CE1).withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            size: 14,
                                            color: _selectedFilter == 'Date' ? Colors.white : Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _dateRange != null && _selectedFilter == 'Date'
                                                ? '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}'
                                                : 'Date',
                                            style: TextStyle(
                                              color: _selectedFilter == 'Date' ? Colors.white : Colors.grey.shade600,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (displayedInvoices.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'No invoices found',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final invoice = displayedInvoices[index];
                              return _InvoiceCard(
                                invoice: invoice,
                                onTap: () => _viewInvoice(invoice),
                              );
                            },
                            childCount: displayedInvoices.length,
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)), // extra padding for FAB
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5A5CE1) : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: isSelected ? null : Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF5A5CE1).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade600),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;

  const _InvoiceCard({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(invoice),
                shape: BoxShape.circle,
              ),
              child: Icon(_getIconData(invoice), color: _getIconColor(invoice), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${invoice.invoiceNumber}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _formatDate(invoice.issueDate),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: CircleAvatar(radius: 2, backgroundColor: Colors.grey.shade300),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(invoice),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          invoice.status == InvoiceStatus.paid ? 'PAID' : 'PENDING',
                          style: TextStyle(
                            color: _getStatusColor(invoice),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${invoice.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'INR',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(Invoice invoice) {
    if (invoice.status == InvoiceStatus.paid) return Icons.check_circle;
    return Icons.description;
  }

  Color _getIconColor(Invoice invoice) {
    if (invoice.status == InvoiceStatus.paid) return const Color(0xFF10B981);
    return const Color(0xFF5A5CE1);
  }

  Color _getIconBackgroundColor(Invoice invoice) {
    if (invoice.status == InvoiceStatus.paid) return const Color(0xFF10B981).withOpacity(0.15);
    return const Color(0xFF5A5CE1).withOpacity(0.15);
  }

  Color _getStatusBgColor(Invoice invoice) {
    if (invoice.status == InvoiceStatus.paid) return const Color(0xFF10B981).withOpacity(0.15);
    return const Color(0xFFF59E0B).withOpacity(0.15);
  }

  Color _getStatusColor(Invoice invoice) {
    if (invoice.status == InvoiceStatus.paid) return const Color(0xFF047857); // dark green
    return const Color(0xFFB45309); // dark amber
  }

  String _formatDate(DateTime date) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}
