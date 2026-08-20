import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/models/TransactionTemplate.dart';
import 'package:finance_tracker/service/OfflineCacheService.dart';

class TemplateFirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _templatesRef(String uid) =>
      firestore.collection("Templates").doc(uid).collection("templates");

  /// Add a new template
  Future<void> addTemplate(String uid, TransactionTemplate template) async {
    await _templatesRef(uid).doc(template.id).set(template.toMap());
  }

  /// Stream all templates for a user
  Stream<List<TransactionTemplate>> getTemplatesStream(String uid) async* {
    final cacheKey = 'templates_$uid';
    final cached = await OfflineCacheService.readList(cacheKey);

    if (cached != null) {
      try {
        yield cached
            .map((map) => TransactionTemplate.fromMap(map))
            .where((t) => t.id.isNotEmpty)
            .toList(growable: false);
      } catch (_) {}
    }

    yield* _templatesRef(uid)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final data = snapshot.docs.map((doc) => doc.data()).toList();
      await OfflineCacheService.saveList(cacheKey, data);

      return snapshot.docs
          .map((doc) =>
              TransactionTemplate.fromMap(doc.data(), fallbackId: doc.id))
          .where((t) => t.id.isNotEmpty)
          .toList(growable: false);
    });
  }

  /// Update an existing template
  Future<void> updateTemplate(String uid, TransactionTemplate template) async {
    await _templatesRef(uid).doc(template.id).update(template.toMap());
  }

  /// Delete a template
  Future<void> deleteTemplate(String uid, String templateId) async {
    await _templatesRef(uid).doc(templateId).delete();
  }
}
