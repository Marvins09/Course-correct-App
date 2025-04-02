import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart'; // ✅ Import Logger

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger(); // ✅ Initialize Logger

  /// ✅ Get current user's ID
  String? get userId => _auth.currentUser?.uid;

  /// ✅ Fetch a document from Firestore (Optimized with null safety)
  Future<DocumentSnapshot?> getDocument(String collection, String docId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(collection).doc(docId).get();
      if (!doc.exists) {
        _logger.w("⚠️ Document not found: $collection/$docId");
        return null;
      }
      return doc;
    } catch (e) {
      _logger.e("❌ Error fetching document ($collection/$docId): $e");
      return null;
    }
  }

  /// ✅ Fetch a collection from Firestore
  Future<QuerySnapshot?> getCollection(String collection) async {
    try {
      return await _firestore.collection(collection).get();
    } catch (e) {
      _logger.e("❌ Error fetching collection ($collection): $e");
      return null;
    }
  }

  /// ✅ Fetch a subcollection (Optimized with pagination support)
  Future<QuerySnapshot?> getSubCollection(
    String parentCollection,
    String parentDocId,
    String subCollection, {
    int limit = 10,
  }) async {
    try {
      return await _firestore
          .collection(parentCollection)
          .doc(parentDocId)
          .collection(subCollection)
          .limit(limit)
          .get();
    } catch (e) {
      _logger.e(
        "❌ Error fetching subcollection ($subCollection in $parentCollection/$parentDocId): $e",
      );
      return null;
    }
  }

  /// ✅ Update a Firestore document (Optimized with error checks)
  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collection).doc(docId).update(data);
      _logger.i("✅ Document updated ($collection/$docId)");
    } catch (e) {
      _logger.e("❌ Error updating document ($collection/$docId): $e");
    }
  }

  /// ✅ Set (create or update) a Firestore document
  Future<void> setDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection(collection)
          .doc(docId)
          .set(data, SetOptions(merge: true));
      _logger.i("✅ Document set ($collection/$docId)");
    } catch (e) {
      _logger.e("❌ Error setting document ($collection/$docId): $e");
    }
  }

  /// ✅ Delete a Firestore document (Now checks if the document exists first)
  Future<void> deleteDocument(String collection, String docId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(collection).doc(docId).get();
      if (!doc.exists) {
        _logger.w("⚠️ Document does not exist ($collection/$docId)");
        return;
      }
      await _firestore.collection(collection).doc(docId).delete();
      _logger.w("🗑 Document deleted ($collection/$docId)");
    } catch (e) {
      _logger.e("❌ Error deleting document ($collection/$docId): $e");
    }
  }

  /// ✅ Batch update multiple documents (New Feature)
  Future<void> batchUpdateDocuments(
    String collection,
    Map<String, Map<String, dynamic>> updates,
  ) async {
    try {
      WriteBatch batch = _firestore.batch();
      updates.forEach((docId, data) {
        DocumentReference docRef = _firestore.collection(collection).doc(docId);
        batch.update(docRef, data);
      });
      await batch.commit();
      _logger.i("✅ Batch update completed in collection: $collection");
    } catch (e) {
      _logger.e("❌ Error in batch update: $e");
    }
  }

  /// ✅ Batch delete multiple documents (New Feature)
  Future<void> batchDeleteDocuments(
    String collection,
    List<String> docIds,
  ) async {
    try {
      WriteBatch batch = _firestore.batch();
      for (String docId in docIds) {
        batch.delete(_firestore.collection(collection).doc(docId));
      }
      await batch.commit();
      _logger.w("🗑 Batch delete completed in collection: $collection");
    } catch (e) {
      _logger.e("❌ Error in batch delete: $e");
    }
  }
}
