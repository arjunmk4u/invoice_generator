import '../models/invoice_model.dart';
import '../models/user_profile.dart';
import 'database_helper.dart';

class StorageService {
  static final StorageService instance = StorageService._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  StorageService._init();

  // Invoice operations
  Future<int> createInvoice(Invoice invoice) async {
    final invoiceId = await _dbHelper.createInvoice(invoice.toMap());
    for (var item in invoice.items) {
      await _dbHelper.createInvoiceItem(
        item.copyWith(invoiceId: invoiceId).toMap(),
      );
    }
    return invoiceId;
  }

  Future<Invoice?> getInvoice(int id) async {
    final invoiceMap = await _dbHelper.readInvoice(id);
    if (invoiceMap == null) return null;

    final itemMaps = await _dbHelper.getInvoiceItems(id);
    final items = itemMaps.map((map) => InvoiceItem.fromMap(map)).toList();

    return Invoice.fromMap(invoiceMap, items);
  }

  Future<List<Invoice>> getAllInvoices() async {
    final invoiceMaps = await _dbHelper.readAllInvoices();
    final invoices = <Invoice>[];

    for (var invoiceMap in invoiceMaps) {
      final id = invoiceMap['id'] as int;
      final itemMaps = await _dbHelper.getInvoiceItems(id);
      final items = itemMaps.map((map) => InvoiceItem.fromMap(map)).toList();
      invoices.add(Invoice.fromMap(invoiceMap, items));
    }

    return invoices;
  }

  Future<List<Invoice>> getRecentInvoices({int limit = 5}) async {
    final invoiceMaps = await _dbHelper.getRecentInvoices(limit: limit);
    final invoices = <Invoice>[];

    for (var invoiceMap in invoiceMaps) {
      final id = invoiceMap['id'] as int;
      final itemMaps = await _dbHelper.getInvoiceItems(id);
      final items = itemMaps.map((map) => InvoiceItem.fromMap(map)).toList();
      invoices.add(Invoice.fromMap(invoiceMap, items));
    }

    return invoices;
  }

  Future<List<Invoice>> getInvoicesByStatus(InvoiceStatus status) async {
    final invoiceMaps = await _dbHelper.getInvoicesByStatus(status.name);
    final invoices = <Invoice>[];

    for (var invoiceMap in invoiceMaps) {
      final id = invoiceMap['id'] as int;
      final itemMaps = await _dbHelper.getInvoiceItems(id);
      final items = itemMaps.map((map) => InvoiceItem.fromMap(map)).toList();
      invoices.add(Invoice.fromMap(invoiceMap, items));
    }

    return invoices;
  }

  Future<int> updateInvoice(Invoice invoice) async {
    if (invoice.id == null) {
      throw Exception('Invoice ID cannot be null for update');
    }

    final result = await _dbHelper.updateInvoice(
      invoice.id!,
      invoice.toMap(),
    );

    await _dbHelper.deleteInvoiceItems(invoice.id!);

    for (var item in invoice.items) {
      await _dbHelper.createInvoiceItem(
        item.copyWith(invoiceId: invoice.id).toMap(),
      );
    }

    return result;
  }

  Future<int> deleteInvoice(int id) async {
    return await _dbHelper.deleteInvoice(id);
  }

  Future<int> updateInvoiceStatus(int id, InvoiceStatus status) async {
    final invoice = await getInvoice(id);
    if (invoice == null) {
      throw Exception('Invoice not found');
    }

    return await _dbHelper.updateInvoice(id, {
      ...invoice.toMap(),
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<int> markInvoiceAsPaid(int id) async {
    return await updateInvoiceStatus(id, InvoiceStatus.paid);
  }

  Future<int> markInvoiceAsUnpaid(int id) async {
    return await updateInvoiceStatus(id, InvoiceStatus.pending);
  }

  Future<String> generateNextInvoiceNumber() async {
    final count = await _dbHelper.getInvoiceCount();
    return Invoice.generateInvoiceNumber(count);
  }

  Future<double> getTotalRevenue() async {
    return await _dbHelper.getTotalRevenue();
  }

  Future<int> getInvoiceCount() async {
    return await _dbHelper.getInvoiceCount();
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final totalRevenue = await getTotalRevenue();
    final totalCount = await getInvoiceCount();
    final paidInvoices = await getInvoicesByStatus(InvoiceStatus.paid);
    final pendingInvoices = await getInvoicesByStatus(InvoiceStatus.pending);
    final overdueInvoices = await getInvoicesByStatus(InvoiceStatus.overdue);

    final pendingAmount = pendingInvoices.fold<double>(
      0.0,
      (sum, invoice) => sum + invoice.grandTotal,
    ) + overdueInvoices.fold<double>(
      0.0,
      (sum, invoice) => sum + invoice.grandTotal,
    );

    return {
      'totalRevenue': totalRevenue,
      'totalInvoices': totalCount,
      'pendingAmount': pendingAmount,
      'paidCount': paidInvoices.length,
      'pendingCount': pendingInvoices.length,
      'overdueCount': overdueInvoices.length,
    };
  }

  Future<void> updateOverdueInvoices() async {
    final pendingInvoices = await getInvoicesByStatus(InvoiceStatus.pending);
    final now = DateTime.now();

    for (var invoice in pendingInvoices) {
      // Mark as overdue if 30 days have passed since issue date
      if (now.isAfter(invoice.issueDate.add(const Duration(days: 30)))) {
        await updateInvoiceStatus(invoice.id!, InvoiceStatus.overdue);
      }
    }
  }

  Future<List<Invoice>> searchInvoices(String query) async {
    final allInvoices = await getAllInvoices();
    final lowerQuery = query.toLowerCase();

    return allInvoices.where((invoice) {
      return invoice.clientName.toLowerCase().contains(lowerQuery) ||
             invoice.invoiceNumber.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // User profile operations
  Future<UserProfile> getUserProfile() async {
    final profileMap = await _dbHelper.getUserProfile();
    if (profileMap != null) {
      return UserProfile.fromMap(profileMap);
    }
    return UserProfile.defaultProfile();
  }

  Future<int> updateUserProfile(UserProfile profile) async {
    return await _dbHelper.updateUserProfile(profile.toMap());
  }
}
