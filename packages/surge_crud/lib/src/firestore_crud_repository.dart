import 'package:cloud_firestore/cloud_firestore.dart';

import 'crud_repository.dart';

/// Firestore-backed [CrudRepository] over one collection. Supply the collection
/// path, how to read an item's id, and map<->model converters; the app model
/// stays free of Firestore types.
class FirestoreCrudRepository<T> implements CrudRepository<T> {
  FirestoreCrudRepository({
    required this.collectionPath,
    required this.idOf,
    required this.toMap,
    required this.fromMap,
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final String collectionPath;
  final String Function(T item) idOf;
  final Map<String, dynamic> Function(T item) toMap;
  final T Function(String id, Map<String, dynamic> data) fromMap;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collectionPath);

  List<T> _mapDocs(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map((d) => fromMap(d.id, d.data())).toList();

  @override
  Stream<List<T>> watchAll() => _col.snapshots().map(_mapDocs);

  @override
  Future<List<T>> fetchAll() async => _mapDocs(await _col.get());

  @override
  Future<T?> fetch(String id) async {
    final doc = await _col.doc(id).get();
    final data = doc.data();
    return data == null ? null : fromMap(doc.id, data);
  }

  @override
  Future<void> upsert(T item) => _col.doc(idOf(item)).set(toMap(item));

  @override
  Future<void> delete(String id) => _col.doc(id).delete();
}
