import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String name;
  final List<QueryDocumentSnapshot> yarnDocs;

  CompanyModel({
    required this.name,
    required this.yarnDocs,
  });

  int get count {
    return yarnDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final state = (data['state'] ?? 'RESERVED').toString().toUpperCase();
      return state == 'RESERVED';
    }).length;
  }
}