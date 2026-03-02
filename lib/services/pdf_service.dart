import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';
import '../models/user_profile.dart';
import '../utils/number_to_words.dart';

class PdfService {
  static Future<pw.Document> generateInvoicePdf(
      Invoice invoice,
      UserProfile userProfile,
      ) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final baseText = pw.TextStyle(font: font, fontSize: 10);
    final boldText = pw.TextStyle(font: fontBold, fontSize: 10);

    // Calculate totals
    double totalQty = invoice.items.fold(0.0, (sum, item) => sum + item.quantity);
    double amountReceived = invoice.status == InvoiceStatus.paid ? invoice.grandTotal : 0.0;
    double balance = invoice.grandTotal - amountReceived;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        (userProfile.companyName?.isNotEmpty == true)
                            ? userProfile.companyName!.toUpperCase()
                            : "COMPANY NAME",
                        style: pw.TextStyle(font: fontBold, fontSize: 14),
                      ),
                      if (userProfile.companyAddress?.isNotEmpty == true) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(userProfile.companyAddress!, style: baseText.copyWith(fontSize: 9)),
                      ],
                      if (userProfile.companyPhone?.isNotEmpty == true) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('Phone no.: ${userProfile.companyPhone}', style: baseText.copyWith(fontSize: 9)),
                      ],
                      if (userProfile.companyEmail?.isNotEmpty == true) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('Email: ${userProfile.companyEmail}', style: baseText.copyWith(fontSize: 9)),
                      ],
                      if (userProfile.gstNumber?.isNotEmpty == true) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('GST: ${userProfile.gstNumber}', style: baseText.copyWith(fontSize: 9)),
                      ],
                    ],
                  ),
                  // Placeholder for logo
                  pw.SizedBox(width: 50, height: 50),
                ],
              ),
              
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1, color: PdfColors.black),
              
              // Title
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Text(
                  'Tax Invoice',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 16,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              
              pw.Divider(thickness: 1, color: PdfColors.black),
              pw.SizedBox(height: 12),

              // Bill To / Invoice Details
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bill To', style: boldText),
                      pw.SizedBox(height: 4),
                      pw.Text(invoice.clientName, style: boldText),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Invoice Details', style: boldText),
                      pw.SizedBox(height: 4),
                      pw.Text('Invoice No.: ${invoice.invoiceNumber}', style: baseText),
                      pw.Text('Date: ${DateFormat('dd-MM-yyyy').format(invoice.issueDate)}', style: baseText),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 16),

              // Table
              pw.Table(
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1.2),
                  4: const pw.FlexColumnWidth(1.2),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey700),
                    children: [
                      _buildHeaderCell('#', fontBold),
                      _buildHeaderCell('Item Name', fontBold),
                      _buildHeaderCell('Quantity', fontBold, align: pw.TextAlign.right),
                      _buildHeaderCell('Price/Unit', fontBold, align: pw.TextAlign.right),
                      _buildHeaderCell('Amount', fontBold, align: pw.TextAlign.right),
                    ],
                  ),
                  // Table Rows
                  ...invoice.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return pw.TableRow(
                      children: [
                        _buildDataCell('${index + 1}', font),
                        _buildDataCell(item.itemName, font),
                        _buildDataCell(
                          item.quantity == item.quantity.toInt() ? item.quantity.toInt().toString() : item.quantity.toString(),
                          font,
                          align: pw.TextAlign.right,
                        ),
                        _buildDataCell('Rs ${item.pricePerUnit.toStringAsFixed(2)}', font, align: pw.TextAlign.right),
                        _buildDataCell('Rs ${item.total.toStringAsFixed(2)}', font, align: pw.TextAlign.right),
                      ],
                    );
                  }),
                  // Total Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(color: PdfColors.black, width: 1.5),
                        bottom: pw.BorderSide(color: PdfColors.black, width: 1.5),
                      ),
                    ),
                    children: [
                      _buildDataCell('', fontBold),
                      _buildDataCell('Total', fontBold),
                      _buildDataCell(
                        totalQty == totalQty.toInt() ? totalQty.toInt().toString() : totalQty.toStringAsFixed(2),
                        fontBold, align: pw.TextAlign.right
                      ),
                      _buildDataCell('', fontBold),
                      _buildDataCell('Rs ${invoice.grandTotal.toStringAsFixed(2)}', fontBold, align: pw.TextAlign.right),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // Bottom Section
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left side annotations
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Invoice Amount In Words', style: boldText),
                        pw.SizedBox(height: 4),
                        pw.Text(NumberToWords.convertAmount(invoice.grandTotal), style: baseText),
                        
                        pw.SizedBox(height: 24),
                        pw.Text('Terms And Conditions', style: boldText),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          invoice.notes?.isNotEmpty == true ? invoice.notes! : 'Thank you for doing business with us.',
                          style: baseText.copyWith(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  
                  pw.SizedBox(width: 24),

                  // Right side totals
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Sub Total', style: baseText.copyWith(fontSize: 9)),
                            pw.Text('Rs ${invoice.grandTotal.toStringAsFixed(2)}', style: baseText.copyWith(fontSize: 9)),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          color: PdfColors.grey700,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Total', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white)),
                              pw.Text('Rs ${invoice.grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white)),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Received', style: baseText.copyWith(fontSize: 9)),
                            pw.Text('Rs ${amountReceived.toStringAsFixed(2)}', style: baseText.copyWith(fontSize: 9)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Divider(color: PdfColors.grey300, thickness: 1),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Balance', style: baseText.copyWith(fontSize: 9)),
                            pw.Text('Rs ${balance.toStringAsFixed(2)}', style: baseText.copyWith(fontSize: 9)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Divider(color: PdfColors.black, thickness: 1),

                        pw.SizedBox(height: 40),
                        
                        // Signatory
                        pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'For: ${userProfile.companyName?.isNotEmpty == true ? userProfile.companyName!.toUpperCase() : ''}',
                                style: pw.TextStyle(font: fontBold, fontSize: 9),
                              ),
                              pw.SizedBox(height: 50), // Space for signature
                              pw.Text('Authorized Signatory', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeaderCell(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildDataCell(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(font: font, fontSize: 9),
      ),
    );
  }

  static Future<void> printPdf(
      Invoice invoice,
      UserProfile userProfile,
      ) async {
    final pdf = await generateInvoicePdf(invoice, userProfile);
    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: '${invoice.invoiceNumber}.pdf',
    );
  }
}
