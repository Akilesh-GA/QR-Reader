import 'dart:ui';
import 'package:flutter/material.dart';

class YarnFullDetailsPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const YarnFullDetailsPage({
    super.key,
    required this.data,
  });

  @override
  State<YarnFullDetailsPage> createState() =>
      _YarnFullDetailsPageState();
}

class _YarnFullDetailsPageState extends State<YarnFullDetailsPage>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scale = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.green.shade700;

    // ✅ FIX: preserve order & filter out 'rawQr' key completely
    final orderedKeys = widget.data.keys
        .where((key) => key.toLowerCase() != 'rawqr')
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔙 BACK ARROW CONTAINER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: IconButton(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
                onPressed: () {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Stack(
                        children: [

                          // 🔥 BACK LAYER
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

                                    // 🏷 INVOICE HEADER
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "INVOICE",
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w900,
                                                color: primaryColor,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Yarn Details Summary",
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

                                    // 📊 DETAILS LIST
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: orderedKeys.length,
                                        itemBuilder: (context, index) {
                                          final key = orderedKeys[index];
                                          final value = widget.data[key];

                                          return _invoiceRow(
                                            key.toString(),
                                            value.toString(),
                                          );
                                        },
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🧾 INVOICE ROW
  Widget _invoiceRow(String title, String value) {
    final isImportant = title.toLowerCase().contains("count") ||
        title.toLowerCase().contains("amount") ||
        title.toLowerCase().contains("total");

    final cleanTitle = title.replaceAll('_', ' ').toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  cleanTitle,
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
                    fontSize: isImportant ? 15 : 14,
                    color: isImportant ? Colors.green.shade700 : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }
}