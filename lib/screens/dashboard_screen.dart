import 'package:flutter/material.dart';
import '../main.dart' show themeNotifier;
import '../models/invoice_model.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import 'create_invoice_screen.dart';
import 'invoice_preview_screen.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int) onNavigateToTab;
  const DashboardScreen({super.key, required this.onNavigateToTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StorageService _storage = StorageService.instance;
  List<Invoice> _recentInvoices = [];
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final invoices = await _storage.getRecentInvoices(limit: 3);
      final profile = await _storage.getUserProfile();
      setState(() {
        _recentInvoices = invoices;
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateInvoiceScreen()),
    );
    if (result == true) {
      _loadData(); // refresh
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgText = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subText = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final scaffoldBg = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FA);
    final gradientColors = isDark
        ? [const Color(0xFF1A1A3E), const Color(0xFF0F0F1A)]
        : [const Color(0xFFE0E7FF), const Color(0xFFF3E8FF), const Color(0xFFF8F9FA)];

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Container(
        constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: isDark ? const [0.0, 1.0] : const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: const Color(0xFF6366F1),
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DASHBOARD',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subText,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _userProfile?.companyName?.isNotEmpty == true 
                                      ? _userProfile!.companyName! 
                                      : (_userProfile?.userName ?? 'My Business'),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: bgText,
                                    letterSpacing: -0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cardBg,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            // child: ValueListenableBuilder(
                            //   valueListenable: themeNotifier,
                            //   builder: (context, mode, _) => IconButton(
                            //     icon: Icon(
                            //       mode == ThemeMode.dark
                            //           ? Icons.light_mode_rounded
                            //           : Icons.dark_mode_rounded,
                            //       color: bgText,
                            //     ),
                            //     onPressed: () {
                            //       themeNotifier.value = themeNotifier.value == ThemeMode.dark
                            //           ? ThemeMode.light
                            //           : ThemeMode.dark;
                            //     },
                            //   ),
                            // ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _navigateToCreate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4F46E5), // Primary solid purple
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4F46E5).withOpacity(0.4),
                                      blurRadius: 24,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.add, color: Colors.white, size: 28),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Create Invoice',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // Select template action
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF5A5CE1).withOpacity(0.08),
                                      blurRadius: 24,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF5A5CE1).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.grid_view_rounded, color: Color(0xFF5A5CE1), size: 28),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Select Template',
                                      style: TextStyle(
                                        color: Color(0xFF5A5CE1),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text( // Removed const
                                    'Recent Invoices',
                                    style: TextStyle( // Removed const
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: bgText, // Changed to theme-aware
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => widget.onNavigateToTab(1),
                                    child: const Text(
                                      'View All',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF5A5CE1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              if (_recentInvoices.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                                    child: Text(
                                      'No recent invoices',
                                      style: TextStyle(color: Colors.grey.shade500),
                                    ),
                                  ),
                                )
                              else
                                ..._recentInvoices.map((inv) => _buildRecentInvoiceCard(inv)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      ),
    );
  }

  Widget _buildRecentInvoiceCard(Invoice invoice) {
    final isDark = themeNotifier.value == ThemeMode.dark;
    return GestureDetector(
      onTap: () => _viewInvoice(invoice),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getIconColor(invoice).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.description_rounded, color: _getIconColor(invoice), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.clientName.isEmpty ? 'Unknown Client' : invoice.clientName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${invoice.invoiceNumber} â€¢ ${_formatDate(invoice.issueDate)}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'â‚¹${invoice.grandTotal.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getIconColor(Invoice invoice) {
    switch (invoice.status) {
      case InvoiceStatus.paid:
        return const Color(0xFF10B981);
      case InvoiceStatus.pending:
        return const Color(0xFF5A5CE1);
      case InvoiceStatus.overdue:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatDate(DateTime date) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month]} ${date.day}';
  }
}
