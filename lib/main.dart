import 'package:flutter/material.dart';
import 'screens/invoice_history_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database and check for overdue invoices
  await StorageService.instance.updateOverdueInvoices();
  
  runApp(const InvoiceApp());
}

class InvoiceApp extends StatelessWidget {
  const InvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Invoice Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: const InvoiceHistoryScreen(),
    );
  }
}
