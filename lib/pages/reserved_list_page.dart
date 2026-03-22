import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/yarn_service.dart';
import './qr_code.dart';
import './reserved_yarn_details_page.dart';

class ReservedListPage extends StatefulWidget {
  const ReservedListPage({super.key});

  @override
  State<ReservedListPage> createState() => _ReservedListPageState();
}

class _ReservedListPageState extends State<ReservedListPage>
    with SingleTickerProviderStateMixin {
  final YarnService yarnService = YarnService();

  late AnimationController _controller;

  String _searchQuery = '';

  // ✅ SORT VARIABLE
  String _sortOption = 'id_asc';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // smoother
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ✅ SMART SORT FUNCTION (clean + fast)
  List<QueryDocumentSnapshot> _sortDocs(List<QueryDocumentSnapshot> docs) {
    docs.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      final idA = (dataA['id'] ?? dataA['yarnId'] ?? a.id).toString();
      final idB = (dataB['id'] ?? dataB['yarnId'] ?? b.id).toString();

      final supplierA = (dataA['supplier_name'] ?? '').toString();
      final supplierB = (dataB['supplier_name'] ?? '').toString();

      switch (_sortOption) {
        case 'id_desc':
          return idB.compareTo(idA);
        case 'supplier_asc':
          return supplierA.compareTo(supplierB);
        case 'supplier_desc':
          return supplierB.compareTo(supplierA);
        case 'id_asc':
        default:
          return idA.compareTo(idB);
      }
    });

    return docs;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.green.shade700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Reserved Yarns',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.black),
            color: Colors.white,
            onSelected: (value) {
              setState(() {
                _sortOption = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'date_desc', child: Text('Date ↓ (Newest)')),
              const PopupMenuItem(
                  value: 'date_asc', child: Text('Date ↑ (Oldest)')),
              const PopupMenuItem(
                  value: 'id_asc', child: Text('ID ↑')),
              const PopupMenuItem(
                  value: 'id_desc', child: Text('ID ↓')),
              const PopupMenuItem(
                  value: 'supplier_asc', child: Text('Supplier ↑')),
              const PopupMenuItem(
                  value: 'supplier_desc', child: Text('Supplier ↓')),
            ],
          )
        ],
        centerTitle: true,
      ),

      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search Yarn ID...',
                  prefixIcon: Icon(Icons.search, color: primaryColor),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() => _searchQuery = '');
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                },
              ),
            ),
          ),
          // 📦 LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: yarnService.getReservedYarns(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;

                // 🔍 FILTER
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data =
                    doc.data() as Map<String, dynamic>;
                    final yarnId =
                    (data['id'] ?? data['yarnId'] ?? doc.id)
                        .toString()
                        .toLowerCase();
                    return yarnId
                        .contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                // ✅ SORT
                docs = _sortDocs(docs);

                // ❌ EMPTY
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 70,
                            color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text("No Reserved Yarn"),
                      ],
                    ),
                  );
                }

                // 🔥 RESET ANIMATION EACH BUILD
                _controller.forward(from: 0);

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data =
                    doc.data() as Map<String, dynamic>;

                    final yarnId =
                        data['id'] ?? data['yarnId'] ?? doc.id;

                    final supplier =
                        data['supplier_name'] ?? 'Unknown';

                    // 🔥 SMOOTH STAGGER ANIMATION
                    final animation = Tween<double>(begin: 0, end: 1)
                        .animate(CurvedAnimation(
                      parent: _controller,
                      curve: Interval(
                        (index / docs.length) * 0.7,
                        1,
                        curve: Curves.easeOutCubic,
                      ),
                    ));

                    return FadeTransition(
                      opacity: animation,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - animation.value)),
                        child: Transform.scale(
                          scale: 0.95 + (0.05 * animation.value),
                          child: Dismissible(
                            key: ValueKey(doc.id),
                            background: _swipeLeft(),
                            secondaryBackground: _swipeRight(),
                            confirmDismiss:
                                (direction) async {
                              if (direction ==
                                  DismissDirection.startToEnd) {
                                final scan =
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ScanCodePage(
                                      expectedQr:
                                      supplier.toString(),
                                      title: 'Verify - $yarnId',
                                    ),
                                  ),
                                );

                                if (scan == true) {
                                  await yarnService
                                      .updateYarnStatus(
                                      doc.id, 'moved');
                                }
                                return false;
                              } else {
                                final confirm =
                                await _deleteDialog(
                                    yarnId);
                                if (confirm == true) {
                                  await yarnService
                                      .deleteReservedYarnById(
                                      doc.id);
                                  return true;
                                }
                                return false;
                              }
                            },
                            child: InkWell(
                              borderRadius:
                              BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ReservedYarnDetailsPage(
                                          docId: doc.id,
                                          data: data,
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(
                                    bottom: 14),
                                padding:
                                const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient:
                                  const LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Color(0xFFF9FAFB)
                                    ],
                                  ),
                                  borderRadius:
                                  BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withOpacity(0.04),
                                      blurRadius: 10,
                                      offset:
                                      const Offset(0, 6),
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding:
                                      const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: primaryColor
                                            .withOpacity(0.1),
                                        borderRadius:
                                        BorderRadius.circular(
                                            12),
                                      ),
                                      child: Icon(
                                        Icons.inventory_2,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          Text(
                                            yarnId.toString(),
                                            style:
                                            const TextStyle(
                                              fontWeight:
                                              FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(
                                              height: 6),
                                          Text(
                                            supplier,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors
                                                    .grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.green
                                            .withOpacity(0.12),
                                        borderRadius:
                                        BorderRadius.circular(
                                            20),
                                      ),
                                      child: const Text(
                                        "RESERVED",
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight:
                                            FontWeight.w600,
                                            color:
                                            Colors.green),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _swipeLeft() => Container(
    alignment: Alignment.centerLeft,
    padding:
    const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Colors.greenAccent, Colors.green]),
      borderRadius: BorderRadius.circular(16),
    ),
    child:
    const Icon(Icons.qr_code, color: Colors.white),
  );

  Widget _swipeRight() => Container(
    alignment: Alignment.centerRight,
    padding:
    const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: Colors.redAccent,
      borderRadius: BorderRadius.circular(16),
    ),
    child:
    const Icon(Icons.delete, color: Colors.white),
  );

  Future<bool?> _deleteDialog(dynamic yarnId) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔴 ICON
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete, color: Colors.red, size: 30),
              ),

              const SizedBox(height: 16),

              // TITLE
              const Text(
                "Delete Yarn",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              // MESSAGE
              Text(
                "Delete yarn $yarnId permanently?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 24),

              // BUTTONS
              Row(
                children: [
                  // ❌ CANCEL (TEXT ONLY)
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        overlayColor: Colors.transparent, // no ripple highlight
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 🔥 DELETE BUTTON (RED GLOW)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.6),
                            blurRadius: 12,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Delete",
                          style: TextStyle(
                            color: Colors.white, // ✅ WHITE TEXT
                            fontWeight: FontWeight.w600,
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
  }
}