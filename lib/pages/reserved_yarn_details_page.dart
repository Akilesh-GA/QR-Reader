import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import './yarn_full_details_page.dart';

class ReservedYarnDetailsPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const ReservedYarnDetailsPage({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<ReservedYarnDetailsPage> createState() =>
      _ReservedYarnDetailsPageState();
}

class _ReservedYarnDetailsPageState
    extends State<ReservedYarnDetailsPage>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;
  bool isExporting = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ✅ CUSTOM TOAST SNACKBAR IN THE SAME STYLE
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

  /// ✅ EXPORT WITH UPDATED STRUCTURAL SUB-FOLDER DIRECTORY PATH PATTERN
  Future<void> _exportAsPdf(String yarnId, List<Map<String, String>> rows) async {
    setState(() => isExporting = true);
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RESERVATION INVOICE',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Yarn Details Summary Statement'),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),
              ...rows.map(
                    (row) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        row['title']!.toUpperCase(),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                      ),
                      pw.Text(
                        row['value']!,
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    try {
      final dir = await getApplicationDocumentsDirectory();

      // Sanitizing ID for explicit directory parsing safety patterns
      final sanitizedId = yarnId.toString().replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();

      // ✅ FIX: Updated folder hierarchy directory path mappings to YarnScanner/Reserved/
      final folder = Directory('${dir.path}/YarnScanner/Reserved');
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      // ✅ FIX: Saving format directly as output mapping path name
      final file = File('${folder.path}/$sanitizedId.pdf');
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      showAck(context, 'PDF saved to /Reserved/$sanitizedId.pdf successfully!');
    } catch (_) {
      if (!mounted) return;
      showAck(context, 'Failed to export transaction PDF');
    } finally {
      if (mounted) {
        setState(() => isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.green.shade700;

    final yarnId = (widget.data['id'] ?? widget.data['yarnId'] ?? widget.docId).toString();
    final supplier = (widget.data['supplier_name'] ?? 'N/A').toString();
    final type = (widget.data['yarn_type'] ?? 'N/A').toString();
    final count = (widget.data['yarn_count'] ?? 'N/A').toString();
    final quality = (widget.data['quality_grade'] ?? 'N/A').toString();
    final bin = (widget.data['bin'] ?? widget.data['bin_id'] ?? 'N/A').toString();
    final rack = (widget.data['rack_id'] ?? 'N/A').toString();
    final weight = (widget.data['weight']?.toString() ?? widget.data['net_weight']?.toString() ?? 'N/A');
    final orderId = (widget.data['order_id'] ?? widget.data['orderId'] ?? 'N/A').toString();

    final invoiceRows = [
      {'title': 'Yarn ID', 'value': yarnId},
      {'title': 'Supplier', 'value': supplier},
      {'title': 'Type', 'value': type},
      {'title': 'Count', 'value': count},
      {'title': 'Quality', 'value': quality},
      {'title': 'Bin', 'value': bin},
      {'title': 'Rack', 'value': rack},
      {'title': 'Weight', 'value': weight},
      {'title': 'Order ID', 'value': orderId},
    ];

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
          "Reserved Yarn Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          isExporting
              ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
              ),
            ),
          )
              : IconButton(
            onPressed: () => _exportAsPdf(yarnId, invoiceRows),
            icon: const Icon(Icons.picture_as_pdf, color: Colors.black54),
            tooltip: 'Export Invoice as PDF',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Column(
            children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ScaleTransition(
                  scale: _scale,
                  child: Stack(
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
                                          "RESERVATION",
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

                                // 📊 INVOICE ROWS LISTING
                                ...invoiceRows.map((row) => _invoiceRow(row['title']!, row['value']!)),

                                const SizedBox(height: 10),
                                Divider(color: Colors.grey.shade200),

                                // 🔹 More Details Navigation Row
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => YarnFullDetailsPage(
                                            data: widget.data,
                                          ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 6),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "View Full Details",
                                            style: TextStyle(
                                              color: primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: primaryColor,
                                            size: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  // 🧾 INVOICE ROW ELEMENTS LAYOUT
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