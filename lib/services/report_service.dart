import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/member_model.dart';

class ReportService {
  static final PdfColor _brand = PdfColor.fromInt(0xFF73B7F1);
  static final PdfColor _green = PdfColor.fromInt(0xFF15803D);
  static final PdfColor _grey = PdfColor.fromInt(0xFF6B7280);
  static final PdfColor _light = PdfColor.fromInt(0xFFF3F4F6);

  final NumberFormat _money = NumberFormat('#,##0');

  String _pkr(double amount) => 'PKR ${_money.format(amount)}';

  // Works on Android, iOS, Windows AND Web.
  // No dart:io, no path_provider — printing package handles the
  // platform-specific save/share/download internally.
  Future<void> saveToDownloads(List<MemberModel> activeMembers) async {
    final bytes = await _buildPaymentReport(activeMembers);
    final month = DateFormat('MMMM_yyyy').format(DateTime.now());
    final fileName = 'Joji_Gym_Fees_$month.pdf';
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  Future<void> sharePaymentReport(List<MemberModel> activeMembers) async {
    final bytes = await _buildPaymentReport(activeMembers);
    final month = DateFormat('MMMM_yyyy').format(DateTime.now());
    await Printing.sharePdf(
        bytes: bytes, filename: 'Joji_Gym_Fees_$month.pdf');
  }

  Future<void> saveMembersListToDownloads(List<MemberModel> allMembers) async {
    final bytes = await _buildMembersReport(allMembers);
    final month = DateFormat('MMMM_yyyy').format(DateTime.now());
    final fileName = 'Joji_Gym_Members_$month.pdf';
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  double _sum(List<MemberModel> list) =>
      list.fold<double>(0, (total, m) => total + m.feeAmount);

  Future<Uint8List> _buildPaymentReport(List<MemberModel> activeMembers) async {
    final paid = activeMembers.where((m) => m.currentMonthPaid).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final unpaid = activeMembers.where((m) => !m.currentMonthPaid).toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    final paidTotal = _sum(paid);
    final unpaidTotal = _sum(unpaid);
    final now = DateTime.now();
    final dateFormat = DateFormat('dd MMM yyyy');

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 9, color: _grey)),
        ),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('JOJI GYM',
                      style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          color: _brand)),
                  pw.SizedBox(height: 2),
                  pw.Text('Monthly Fees Report',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(DateFormat('MMMM yyyy').format(now),
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text(
                      'Generated ${DateFormat('dd MMM yyyy, hh:mm a').format(now)}',
                      style: pw.TextStyle(fontSize: 9, color: _grey)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: _brand, thickness: 2),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              _summaryBox(
                  'Active Members', '${activeMembers.length}', PdfColors.black),
              pw.SizedBox(width: 10),
              _summaryBox('Fees Paid',
                  '${paid.length} members\n${_pkr(paidTotal)}', _green),
              pw.SizedBox(width: 10),
              _summaryBox('Fees Unpaid',
                  '${unpaid.length} members\n${_pkr(unpaidTotal)}', _brand),
              pw.SizedBox(width: 10),
              _summaryBox('Expected Total', _pkr(paidTotal + unpaidTotal),
                  PdfColors.black),
            ],
          ),
          pw.SizedBox(height: 22),
          _sectionTitle('Paid Members (${paid.length})', _green),
          pw.SizedBox(height: 8),
          if (paid.isEmpty)
            pw.Text('No paid members this month.',
                style: pw.TextStyle(color: _grey))
          else
            _table(
              headers: const [
                '#',
                'Name',
                'WhatsApp',
                'Plan',
                'Amount',
                'Next Due'
              ],
              rows: [
                for (int i = 0; i < paid.length; i++)
                  [
                    '${i + 1}',
                    paid[i].name,
                    paid[i].whatsappNumber,
                    paid[i].planName,
                    _pkr(paid[i].feeAmount),
                    dateFormat.format(paid[i].nextDueDate),
                  ],
              ],
              headerColor: _green,
            ),
          pw.SizedBox(height: 8),
          _totalBar(
              'Total Paid (${paid.length} members)', _pkr(paidTotal), _green),
          pw.SizedBox(height: 26),
          _sectionTitle('Unpaid Members (${unpaid.length})', _brand),
          pw.SizedBox(height: 8),
          if (unpaid.isEmpty)
            pw.Text('Every active member has paid.',
                style: pw.TextStyle(color: _grey))
          else
            _table(
              headers: const [
                '#',
                'Name',
                'WhatsApp',
                'Plan',
                'Amount',
                'Due Date',
                'Status'
              ],
              rows: [
                for (int i = 0; i < unpaid.length; i++)
                  [
                    '${i + 1}',
                    unpaid[i].name,
                    unpaid[i].whatsappNumber,
                    unpaid[i].planName,
                    _pkr(unpaid[i].feeAmount),
                    dateFormat.format(unpaid[i].nextDueDate),
                    unpaid[i].isOverdue ? 'Overdue' : 'Pending',
                  ],
              ],
              headerColor: _brand,
            ),
          pw.SizedBox(height: 8),
          _totalBar('Total Unpaid (${unpaid.length} members)',
              _pkr(unpaidTotal), _brand),
        ],
      ),
    );

    return doc.save();
  }

  Future<Uint8List> _buildMembersReport(List<MemberModel> allMembers) async {
    final doc = pw.Document();
    final active = allMembers
        .where((m) => m.status == MemberStatus.active)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final inactive = allMembers
        .where((m) => m.status != MemberStatus.active)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final male = active.where((m) => m.gender == Gender.male).length;
    final female = active.where((m) => m.gender == Gender.female).length;
    final now = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 9, color: _grey)),
        ),
        build: (context) => [
          pw.Text('JOJI GYM',
              style: pw.TextStyle(
                  fontSize: 26, fontWeight: pw.FontWeight.bold, color: _brand)),
          pw.Text('Member Directory',
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Generated ${DateFormat('dd MMM yyyy, hh:mm a').format(now)}',
              style: pw.TextStyle(fontSize: 9, color: _grey)),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              _summaryBox(
                  'Total Members', '${allMembers.length}', PdfColors.black),
              pw.SizedBox(width: 10),
              _summaryBox('Active', '${active.length}', _green),
              pw.SizedBox(width: 10),
              _summaryBox('Male', '$male', PdfColors.blue),
              pw.SizedBox(width: 10),
              _summaryBox('Female', '$female', PdfColors.pink),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('Active Members (${active.length})',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold, color: _green)),
          pw.SizedBox(height: 8),
          _table(
            headers: const [
              '#',
              'Name',
              'WhatsApp',
              'Plan',
              'Gender',
              'Due Date'
            ],
            rows: [
              for (int i = 0; i < active.length; i++)
                [
                  '${i + 1}',
                  active[i].name,
                  active[i].whatsappNumber,
                  active[i].planName,
                  active[i].gender == Gender.male ? 'Male' : 'Female',
                  DateFormat('dd MMM yyyy').format(active[i].nextDueDate),
                ],
            ],
            headerColor: _green,
          ),
          if (inactive.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text('Inactive Members (${inactive.length})',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _grey)),
            pw.SizedBox(height: 8),
            _table(
              headers: const ['#', 'Name', 'WhatsApp'],
              rows: [
                for (int i = 0; i < inactive.length; i++)
                  ['${i + 1}', inactive[i].name, inactive[i].whatsappNumber]
              ],
              headerColor: PdfColors.grey600,
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _summaryBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
            color: _light, borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _grey)),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }

  pw.Widget _sectionTitle(String text, PdfColor color) {
    return pw.Text(text,
        style: pw.TextStyle(
            fontSize: 15, fontWeight: pw.FontWeight.bold, color: color));
  }

  pw.Widget _totalBar(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
          color: _light, borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style:
                  pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  pw.Widget _table(
      {required List<String> headers,
      required List<List<String>> rows,
      required PdfColor headerColor}) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
          fontSize: 9.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: headerColor),
      cellStyle: const pw.TextStyle(fontSize: 9.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      rowDecoration: const pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }
}