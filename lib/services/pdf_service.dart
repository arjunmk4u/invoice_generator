import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice_model.dart';
import '../models/user_profile.dart';

class PdfService {
  static Future<pw.Document> generateInvoicePdf(
      Invoice invoice,
      UserProfile userProfile,
      ) async {
    final pdf = pw.Document();

    // ✅ Correct font loading
    final font = await PdfGoogleFonts.robotoRegular();

    final baseText = pw.TextStyle(
      font: font,
      fontSize: 10,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Company name
              if (userProfile.companyName?.isNotEmpty == true)
                pw.Text(
                  userProfile.companyName!,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

              if (userProfile.companyAddress?.isNotEmpty == true) ...[
                pw.SizedBox(height: 4),
                pw.Text(userProfile.companyAddress!, style: baseText),
              ],

              pw.SizedBox(height: 6),

              // Phone & Email
              pw.Row(
                children: [
                  if (userProfile.companyPhone?.isNotEmpty == true)
                    pw.Expanded(
                      child: pw.Text(
                        'Phone: ${userProfile.companyPhone}',
                        style: baseText,
                      ),
                    ),
                  if (userProfile.companyEmail?.isNotEmpty == true)
                    pw.Expanded(
                      child: pw.Text(
                        'Email: ${userProfile.companyEmail}',
                        style: baseText,
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                ],
              ),

              if (userProfile.gstNumber?.isNotEmpty == true) ...[
                pw.SizedBox(height: 4),
                pw.Text('GST: ${userProfile.gstNumber}', style: baseText),
              ],

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 12),

              // INVOICE title
              pw.Center(
                child: pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              pw.SizedBox(height: 16),

              pw.Text('Invoice No: ${invoice.invoiceNumber}', style: baseText),
              pw.Text(
                'Date: ${invoice.issueDate.toIso8601String().split('T')[0]}',
                style: baseText,
              ),
              pw.SizedBox(height: 6),
              pw.Text('Bill To: ${invoice.clientName}', style: baseText),

              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Items table
              pw.Table.fromTextArray(
                headers: ['Item', 'Qty', 'Price', 'Total'],
                headerStyle: pw.TextStyle(
                  font: font,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: baseText,
                data: invoice.items.map((item) {
                  return [
                    item.itemName,
                    item.quantity.toString(),
                    '₹${item.pricePerUnit.toStringAsFixed(2)}',
                    '₹${item.total.toStringAsFixed(2)}',
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 16),

              // Grand Total
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Grand Total: ₹${invoice.grandTotal.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              if (invoice.notes?.isNotEmpty == true) ...[
                pw.SizedBox(height: 16),
                pw.Text('Notes:', style: baseText),
                pw.Text(invoice.notes!, style: baseText),
              ],

              pw.Spacer(),

              pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static Future<void> printPdf(
      Invoice invoice,
      UserProfile userProfile,
      ) async {
    final pdf = await generateInvoicePdf(invoice, userProfile);
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }
}
