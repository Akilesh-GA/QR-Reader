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

  String? _ackMessage;

  // ✅ LOCAL STATE
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

  // ✅ DELETE CONFIRM
  Future<bool> _confirmDelete(BuildContext context, String yarnId) async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Confirm Delete",
                  style: TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 12),

              Text("Yarn ID: $yarnId"),

              const SizedBox(height: 12),

              TextField(
                controller: controller,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: "Type Yarn ID",
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        if (controller.text.trim() == yarnId) {
                          Navigator.pop(context, true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("ID does not match")),
                          );
                        }
                      },
                      child: const Text("Delete"),
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
    final primaryColor = Colors.green;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.companyName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.docs.length,
            itemBuilder: (context, index) {

              final doc = widget.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final yarnId = data['id'] ?? doc.id;
              final supplier = data['supplier_name'] ?? 'Unknown';

              final state = data['state'] ?? 'RESERVED';

              final isVerified = state == 'VERIFIED';

              final isScanned = isVerified
                  ? true
                  : _localScanState[doc.id] ??
                  (data['is_scanned'] ?? false);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),

                child: Dismissible(
                  key: ValueKey(doc.id),

                  background: _swipeLeft(),
                  secondaryBackground: _swipeRight(),

                  confirmDismiss: (direction) async {

                    // ✅ LEFT SWIPE → SCAN / VERIFY
                    if (direction == DismissDirection.startToEnd) {

                      // 🚫 BLOCK IF ALREADY SCANNED / VERIFIED
                      if (isScanned || isVerified) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Already Verified")),
                        );
                        return false;
                      }

                      final alreadyScanned =
                      await yarnService.isAlreadyScanned(doc.id);

                      if (alreadyScanned) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Already Verified")),
                        );
                        return false;
                      }

                      // 👉 OPEN QR PAGE
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VerifyQRPage(
                            expectedQr: yarnId.toString(),
                            yarnId: yarnId.toString(),
                          ),
                        ),
                      );

                      if (result == true) {
                        await yarnService.markAsVerified(doc.id);

                        setState(() {
                          _localScanState[doc.id] = true;
                          _ackMessage = "Verified $yarnId";
                        });
                      }

                      return false;
                    }

                    // ✅ RIGHT SWIPE → DELETE
                    else {
                      final confirm =
                      await _confirmDelete(context, yarnId.toString());

                      if (confirm) {
                        await yarnService.deleteReservedYarnById(doc.id);

                        setState(() {
                          widget.docs.removeAt(index); // ✅ REMOVE LOCALLY
                          _ackMessage = "Deleted $yarnId";
                        });
                      }

                      return false;
                    }
                  },

                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReservedYarnDetailsPage(
                            docId: doc.id,
                            data: data,
                          ),
                        ),
                      );
                    },

                    child: Opacity(
                      opacity: isScanned ? 0.6 : 1,

                      child: Container(
                        padding: const EdgeInsets.all(16),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),

                          border: isScanned
                              ? Border.all(color: Colors.blue)
                              : null,

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),

                        child: Row(
                          children: [

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isVerified
                                    ? Colors.blue.withOpacity(0.1)
                                    : primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.inventory_2,
                                color: isVerified
                                    ? Colors.blue
                                    : primaryColor,
                              ),
                            ),

                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
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
                                        color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isVerified
                                    ? Colors.blue.withOpacity(0.15)
                                    : Colors.green.withOpacity(0.15),
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: Text(
                                isVerified ? "VERIFIED" : "RESERVED",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isVerified
                                      ? Colors.blue
                                      : Colors.green,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // ✅ ACK MESSAGE
          if (_ackMessage != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_ackMessage!),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _swipeLeft() => Container(
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Colors.green, Colors.greenAccent]),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Icon(Icons.qr_code, color: Colors.white),
  );

  Widget _swipeRight() => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: Colors.redAccent,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Icon(Icons.delete, color: Colors.white),
  );
}