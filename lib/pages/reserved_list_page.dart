import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/yarn_service.dart';
import './yarn_id_list_view.dart';
import './company_list_view.dart';

class ReservedListPage extends StatefulWidget {
  const ReservedListPage({super.key});

  @override
  State<ReservedListPage> createState() => _ReservedListPageState();
}

class _ReservedListPageState extends State<ReservedListPage> {
  final YarnService yarnService = YarnService();

  bool _isCompanyView = true;
  String _searchQuery = '';
  String _sortOption = 'name_asc'; // Default sort for company view

  // Helper method to reset default sort options when switching views
  void _toggleView(bool isCompany) {
    if (!mounted) return;
    setState(() {
      _isCompanyView = isCompany;
      _sortOption = isCompany ? 'name_asc' : 'id_asc';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () {
            // Guarding against deactivated/unsafe ancestor tree errors during pop navigation
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _isCompanyView ? "Companies" : "Reserved Yarns",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.black),
            onSelected: (val) {
              if (mounted) {
                setState(() => _sortOption = val);
              }
            },
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            color: Colors.white,
            itemBuilder: (_) {
              if (_isCompanyView) {
                return [
                  _buildPopupMenuItem('name_asc', "Name ↑"),
                  _buildPopupMenuItem('name_desc', "Name ↓"),
                  _buildPopupMenuItem('count_asc', "Count ↑"),
                  _buildPopupMenuItem('count_desc', "Count ↓"),
                  _buildPopupMenuItem('date_asc', "Date ↑"),
                  _buildPopupMenuItem('date_desc', "Date ↓"),
                ];
              } else {
                return [
                  _buildPopupMenuItem('id_asc', "ID ↑"),
                  _buildPopupMenuItem('id_desc', "ID ↓"),
                  _buildPopupMenuItem('supplier_asc', "Supplier ↑"),
                  _buildPopupMenuItem('supplier_desc', "Supplier ↓"),
                  _buildPopupMenuItem('date_asc', "Date ↑"),
                  _buildPopupMenuItem('date_desc', "Date ↓"),
                ];
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _searchBar(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _toggle(),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: yarnService.getReservedYarns(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (_isCompanyView) {
                  return CompanyListView(
                    docs: docs,
                    searchQuery: _searchQuery,
                    sortOption: _sortOption,
                    showIconBackground: false,
                  );
                } else {
                  return YarnIdListView(
                    docs: docs,
                    searchQuery: _searchQuery,
                    sortOption: _sortOption,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a stylized PopupMenuItem with a checkmark for the selected item
  PopupMenuItem<String> _buildPopupMenuItem(String value, String text) {
    final isSelected = _sortOption == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: TextStyle(
              color: isSelected ? const Color(0xFF1B5E20) : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_circle,
              color: Color(0xFF43A047),
              size: 18,
            ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: "Search..",
          prefixIcon: Icon(Icons.search, color: Colors.black54),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (val) {
          if (mounted) {
            setState(() => _searchQuery = val);
          }
        },
      ),
    );
  }

  Widget _toggle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.grey.shade200,
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: _isCompanyView
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: width / 2,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _toggleItem("Company", true),
                  _toggleItem("IDs", false),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _toggleItem(String text, bool isCompany) {
    final selected = _isCompanyView == isCompany;

    return Expanded(
      child: GestureDetector(
        onTap: () => _toggleView(isCompany),
        child: Container(
          color: Colors.transparent, // Expands hit testing area
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                color: selected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: selected ? 15 : 14,
              ),
              child: Text(text),
            ),
          ),
        ),
      ),
    );
  }
}