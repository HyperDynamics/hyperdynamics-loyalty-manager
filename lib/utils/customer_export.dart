import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/customer.dart';
import 'formatters.dart';

/// Full (unmasked) phone — this is the business's own operational export,
/// distinct from the masked on-screen list.
List<List<String>> _rows(List<Customer> customers) => [
      ['name', 'phone', 'balance', 'date of birth'],
      for (final c in customers) [c.name, digitsOnly(c.phone), '${c.balance}', c.dob ?? ''],
    ];

Future<void> exportCustomersCsv(List<Customer> customers, {required String businessName}) async {
  final csv = Csv().encode(_rows(customers));
  await FileSaver.instance.saveFile(
    name: '${businessName}_customers',
    bytes: Uint8List.fromList(utf8.encode(csv)),
    fileExtension: 'csv',
    mimeType: MimeType.csv,
  );
}

Future<void> exportCustomersPdf(List<Customer> customers, {required String businessName}) async {
  final doc = pw.Document();
  final rows = _rows(customers);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Text(businessName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('customer list — ${customers.length} customers'),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: rows.first,
          data: rows.skip(1).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellAlignment: pw.Alignment.centerLeft,
        ),
      ],
    ),
  );

  await Printing.sharePdf(bytes: await doc.save(), filename: '${businessName}_customers.pdf');
}
