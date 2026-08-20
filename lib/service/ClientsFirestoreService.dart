import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/models/Client.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientsFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  /// Helper: collection reference for a user
  CollectionReference _clientRef() {
    return _firestore
        .collection("Clients")
        .doc(uid)
        .collection("clients");
  }

  /// CREATE
  Future<String> addClient(Client client) async {
    try {
      DocumentReference docRef = await _clientRef().add(client.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception("Failed to add client: $e");
    }
  }

  /// READ ALL (for a user)
  Stream<List<Client>> getClients() {
    return _clientRef().snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Client.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// READ SINGLE
  Future<Client?> getClientById(String clientId) async {
    try {
      DocumentSnapshot doc =
          await _clientRef().doc(clientId).get();

      if (doc.exists) {
        return Client.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw Exception("Failed to get client: $e");
    }
  }

  /// UPDATE
  Future<void> updateClient(

    String clientId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _clientRef().doc(clientId).update(data);
    } catch (e) {
      throw Exception("Failed to update client: $e");
    }
  }

  /// DELETE
  Future<void> deleteClient(String clientId) async {
    try {
      await _clientRef().doc(clientId).delete();
    } catch (e) {
      throw Exception("Failed to delete client: $e");
    }
  }
}