import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/yarn_service.dart';
import './yarn_full_details_page.dart';
import './dispatch_list_page.dart'; // ✅ added

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

  Future<bool?> _dispatchDialog(String yarnId) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_shipping,
                  color: Colors.green, size: 40),
              const SizedBox(height: 16),
              const Text(
                "Dispatch Yarn",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                "Dispatch yarn $yarnId?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.6),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Dispatch",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final yarnService = YarnService();
    final primaryColor = Colors.green.shade700;

    final yarnId =
        widget.data['id'] ?? widget.data['yarnId'] ?? widget.docId;
    final supplier = widget.data['supplier_name'] ?? 'N/A';
    final type = widget.data['yarn_type'] ?? 'N/A';
    final count = widget.data['yarn_count'] ?? 'N/A';

    final quality = widget.data['quality_grade'] ?? 'N/A';
    final bin = widget.data['bin'] ?? widget.data['bin_id'] ?? 'N/A';
    final rack = widget.data['rack_id'] ?? 'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text("Reserved Yarn Details",
            style: TextStyle(color: Colors.black)),
        centerTitle: true,
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
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row("Yarn ID", yarnId.toString()),
                        _row("Supplier", supplier),
                        _row("Type", type),
                        _row("Count", count),
                        _row("Quality", quality),
                        _row("Bin", bin),
                        _row("Rack Bin", rack),

                        const SizedBox(height: 10),
                        Divider(color: Colors.grey.shade200),

                        // 🔥 MORE DETAILS NAVIGATION
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
                                    "More Details",
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: primaryColor,
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

              const Spacer(),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 50),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.6),
                        blurRadius: 18,
                        spreadRadius: 1,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      final confirm =
                      await _dispatchDialog(yarnId.toString());

                      if (confirm == true) {
                        await yarnService.updateYarnStatus(
                            widget.docId, 'DISPATCHED');

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DispatchListPage(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "DISPATCH",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(title,
                style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            flex: 6,
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}