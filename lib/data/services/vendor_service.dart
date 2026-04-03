import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vendor.dart';

class VendorService {
  VendorService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final VendorService instance = VendorService();

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _vendors =>
      _firestore.collection('vendors');

  Stream<List<Vendor>> streamVendors({bool includeInactive = true}) {
    return _vendors.snapshots().map((snapshot) {
      final items =
          snapshot.docs
              .map((doc) => Vendor.fromMap(doc.data(), id: doc.id))
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
      if (includeInactive) return items;
      return items.where((item) => item.isActive).toList();
    });
  }

  Future<String> createVendor(Vendor vendor) async {
    final doc = await _vendors.add(vendor.toMap());
    return doc.id;
  }

  Future<bool> nameExists(String name) async {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    final byLower = await _vendors
        .where('nameLower', isEqualTo: normalized)
        .limit(1)
        .get();
    if (byLower.docs.isNotEmpty) return true;
    final fallback = await _vendors
        .where('name', isEqualTo: name.trim())
        .limit(1)
        .get();
    return fallback.docs.isNotEmpty;
  }

  Future<void> updateVendor(Vendor vendor) {
    if (vendor.id == null || vendor.id!.isEmpty) return Future.value();
    final next = vendor.copyWith(updatedAt: DateTime.now());
    return _vendors.doc(vendor.id).set(next.toMap(), SetOptions(merge: true));
  }

  Future<void> setVendorActive({
    required String vendorId,
    required bool isActive,
  }) {
    return _vendors.doc(vendorId).set({
      'isActive': isActive,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
}
