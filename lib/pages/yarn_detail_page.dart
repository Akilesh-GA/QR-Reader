import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../services/yarn_service.dart';
import './qr_code.dart';

class YarnDataPage extends StatefulWidget {
  final String qr;
  final String? expectedQr;
  final bool isAddMode;

  const YarnDataPage({
    super.key,
    required this.qr,
    this.expectedQr,
    this.isAddMode = false,
  });

  @override
  State<YarnDataPage> createState() => _YarnDataPageState();
}

class _YarnDataPageState extends State<YarnDataPage> {
  Map<String, dynamic>? yarnData;
  bool isLoading = true;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchYarnData();
  }

  Future<void> _fetchYarnData() async {
    setState(() => isLoading = true);
    try {
      final yarnService = YarnService();
      final doc = await yarnService.findYarnByContent(widget.qr);
      if (doc != null && doc.exists) {
        setState(() => yarnData = doc.data() as Map<String, dynamic>);
      } else {
        setState(() => yarnData = {'id': widget.qr, 'notFound': true});
      }
    } catch (_) {
      setState(() => yarnData = {'id': widget.qr, 'error': 'Failed to fetch'});
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s
        .replaceAll('_', ' ')
        .split(' ')
        .map((str) =>
    str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1)}' : '')
        .join(' ');
  }

  /// ✅ CUSTOM TOAST SNACKBAR MATCHING APPLICATION DESIGN SPECIFICATIONS
  void showAck(BuildContext context, String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        content: Row(
          children: [
            Image.asset(
              'assets/icon/app_icon.png',
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Confirm yarn and go to main page
  Future<void> _confirmYarn() async {
    if (yarnData == null) return;
    setState(() => isProcessing = true);
    try {
      final yarnService = YarnService();
      await yarnService.addYarn(widget.qr, yarnData!);

      if (!mounted) return;

      showAck(context, 'Yarn confirmed successfully!');

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      });
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  /// Navigate to QR scanner page
  void _rescan() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ScanCodePage(),
      ),
    );
  }

  /// ✅ EXPORT WITH UPDATED ADDYARNS SUB-FOLDER PATTERN
  Future<void> _exportAsPdf() async {
    if (yarnData == null) return;
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Yarn Details',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              ...yarnData!.entries
                  .where((e) =>
              !['notfound', 'status', 'createdat', 'rawqr', 'qrimage']
                  .contains(e.key.toLowerCase()))
                  .map(
                    (e) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        _capitalize(e.key).toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        e.value.toString(),
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
                  .toList(),
            ],
          );
        },
      ),
    );

    try {
      final dir = await getApplicationDocumentsDirectory();

      // Fallback evaluation parameters matching standard raw data string conversions
      final rawId = (yarnData!['id'] ?? yarnData!['yarnId'] ?? widget.qr).toString();
      final sanitizedId = rawId.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();

      // ✅ FIX: Formatted explicitly to match YarnScanner/AddYarns pattern setup
      final folder = Directory('${dir.path}/YarnScanner/AddYarns');
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final file = File('${folder.path}/$sanitizedId.pdf');
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      showAck(context, 'PDF saved to /AddYarns/$sanitizedId.pdf successfully!');
    } catch (_) {
      if (!mounted) return;
      showAck(context, 'Failed to export PDF');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.green.shade700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Yarn Invoice',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _exportAsPdf,
            icon: const Icon(Icons.picture_as_pdf, color: Colors.black54),
            tooltip: 'Export as PDF',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : yarnData == null
          ? const Center(child: Text('No Data Found'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // ✅ INVOICE CARD STACK IMPLEMENTATION MATCHING DESIGN PRESETS
            Stack(
              children: [
                // 🔥 BACK LAYER SHADOW EFFECT
                Positioned(
                  top: 12,
                  left: 12,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
                // 🧾 MAIN INVOICE CARD
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.97),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🏷 INVOICE HEADER AREA
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "YARN DATA",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: primaryColor,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Statement Summary",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.receipt_long,
                                color: primaryColor.withOpacity(0.3),
                                size: 36,
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(thickness: 1.2),
                          const SizedBox(height: 10),

                          // 📊 INVOICE ROWS LISTING (Filtered & Formatted)
                          ...yarnData!.entries
                              .where((e) => ![
                            'notfound',
                            'status',
                            'createdat',
                            'rawqr',
                            'qrimage'
                          ].contains(e.key.toLowerCase()))
                              .map((e) => _invoiceRow(_capitalize(e.key), e.value.toString())),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (isProcessing)
              const Center(
                  child: CircularProgressIndicator(color: Colors.orange))
            else
              Row(
                children: [
                  // RESCAN Button
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.redAccent, Colors.red],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.6),
                            blurRadius: 12,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: _rescan,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                'Rescan',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // CONFIRM Button
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.greenAccent, Colors.green],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.6),
                            blurRadius: 12,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: _confirmYarn,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                'Confirm',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // 🧾 INVOICE ROW CONFIGURATION REPLICATING THE UNIFIED METRIC SYSTEM
  Widget _invoiceRow(String title, String value) {
    final isImportant = title.toLowerCase().contains("count") ||
        title.toLowerCase().contains("weight") ||
        title.toLowerCase().contains("id");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 6,
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: isImportant ? FontWeight.bold : FontWeight.w600,
                    fontSize: isImportant ? 14 : 13,
                    color: isImportant ? Colors.green.shade700 : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 1,
            color: Colors.grey.shade100,
          ),
        ],
      ),
    );
  }
}