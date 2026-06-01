import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/yarn_service.dart';
import './reserved_yarn_details_page.dart';
import './verify_qr_page.dart';

class CompanyYarnListPage extends StatefulWidget {
  final String companyName;
  final List<QueryDocumentSnapshot> docs;

  const CompanyYarnListPage({
    super.key,
    required this.companyName,
    required this.docs,
  });

  @override
  State<CompanyYarnListPage> createState() => _CompanyYarnListPageState();
}

class _CompanyYarnListPageState extends State<CompanyYarnListPage>
    with SingleTickerProviderStateMixin {
  final YarnService yarnService = YarnService();
  late AnimationController _controller;

  // ✅ LOCAL CACHE (to track verified scans locally)
  final Map<String, bool> _localScanState = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
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

  // ✅ CONFIRM DELETE FUNCTION
  Future<bool> _confirmDelete(BuildContext parentContext, String yarnId) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: parentContext,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Confirm Delete",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text("Yarn ID: $yarnId",
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: "Type Yarn ID to confirm",
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Color(0xFFF5F5F5),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // ❌ CANCEL BUTTON
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9E9E9E), Color(0xFF616161)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(dialogContext).pop(false),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 🔥 DELETE BUTTON
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.redAccent, Colors.red],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (controller.text.trim() == yarnId) {
                              Navigator.of(dialogContext).pop(true);
                            } else {
                              // ✅ FIX: Uses parent screen context for solid snackbar execution
                              showAck(parentContext, "Yarn ID does not match!");
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            child: const Text(
                              "Delete",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
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
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.green;
    _controller.forward(from: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.companyName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.docs.length,
        itemBuilder: (context, index) {
          final doc = widget.docs[index];
          final data = doc.data() as Map<String, dynamic>;

          final yarnId = data['id'] ?? data['yarnId'] ?? doc.id;
          final supplier = data['supplier_name'] ?? 'Unknown';

          final state = data['state'] ?? 'RESERVED';
          final isVerified = state == 'VERIFIED';
          final isScanned =
          state == 'VERIFIED'
              ? true
              : _localScanState[doc.id] ?? (data['is_scanned'] ?? false);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Dismissible(
                key: ValueKey(doc.id),
                background: _swipeLeft(),
                secondaryBackground: _swipeRight(),
                confirmDismiss: (direction) async {
                  // 👉 SCAN / VERIFY (left swipe)
                  if (direction == DismissDirection.startToEnd) {
                    if (isVerified || isScanned) {
                      showAck(context, "Already Scanned");
                      return false;
                    }

                    final alreadyScanned =
                    await yarnService.isAlreadyScanned(doc.id);

                    if (alreadyScanned) {
                      showAck(context, "Already Scanned");
                      return false;
                    }

                    final scan = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => VerifyQRPage(
                          expectedQr: yarnId.toString(),
                          yarnId: yarnId.toString(),
                        ),
                      ),
                    );

                    if (scan == true) {
                      await yarnService.markAsVerified(doc.id);
                      setState(() {
                        _localScanState[doc.id] = true;
                      });
                      if (context.mounted) {
                        showAck(context, "Scanned Successfully");
                      }
                    }

                    return false;
                  }
                  // 👉 DELETE (right swipe)
                  else {
                    final confirmed = await _confirmDelete(context, yarnId.toString());

                    if (confirmed) {
                      await yarnService.deleteReservedYarnById(doc.id);
                      if (context.mounted) {
                        showAck(context, "Deleted $yarnId");
                      }
                    }
                    return false;
                  }
                },
                child: Material(
                  color: Colors.transparent,
                  child: Ink(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: isVerified || isScanned
                          ? Border.all(color: Colors.blue)
                          : null,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReservedYarnDetailsPage(
                              docId: doc.id,
                              data: data,
                            ),
                          ),
                        );
                      },
                      child: Opacity(
                        opacity: isVerified || isScanned ? 0.6 : 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (isVerified || isScanned)
                                      ? Colors.blue.withOpacity(0.1)
                                      : primaryColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.inventory_2,
                                  color: (isVerified || isScanned) ? Colors.blue : primaryColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      yarnId.toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      supplier,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: (isVerified || isScanned)
                                      ? Colors.blue.withOpacity(0.15)
                                      : Colors.green.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  (isVerified || isScanned) ? "SCANNED" : "RESERVED",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: (isVerified || isScanned) ? Colors.blue : Colors.green,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _swipeLeft() => Container(
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Colors.green, Colors.greenAccent]),
    ),
    child: const Icon(Icons.qr_code, color: Colors.white),
  );

  Widget _swipeRight() => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    color: Colors.redAccent,
    child: const Icon(Icons.delete, color: Colors.white),
  );
}