import 'package:cloud_firestore/cloud_firestore.dart';

enum AdvancedServiceType {
  memorialPreview,
  memorialExportPdf,
  memorialExportImage,
  obituaryGenerate,
  obituaryRewrite,
  obituaryExportPdf,
  obituaryExportImage,
}

class AdvancedServiceDefinition {
  const AdvancedServiceDefinition({
    required this.type,
    required this.title,
    required this.cost,
  });

  final AdvancedServiceType type;
  final String title;
  final int cost;
}

class TokenConsumeResult {
  const TokenConsumeResult({
    required this.ok,
    required this.balanceAfter,
    this.message,
  });

  final bool ok;
  final int balanceAfter;
  final String? message;
}

class TokenWalletService {
  TokenWalletService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static final TokenWalletService instance = TokenWalletService();

  static const int starterTokens = 5;

  static const Map<AdvancedServiceType, AdvancedServiceDefinition> definitions = {
    AdvancedServiceType.memorialPreview: AdvancedServiceDefinition(
      type: AdvancedServiceType.memorialPreview,
      title: '紀念頁預覽生成',
      cost: 1,
    ),
    AdvancedServiceType.memorialExportPdf: AdvancedServiceDefinition(
      type: AdvancedServiceType.memorialExportPdf,
      title: '紀念頁匯出 PDF',
      cost: 1,
    ),
    AdvancedServiceType.memorialExportImage: AdvancedServiceDefinition(
      type: AdvancedServiceType.memorialExportImage,
      title: '紀念頁匯出圖片',
      cost: 1,
    ),
    AdvancedServiceType.obituaryGenerate: AdvancedServiceDefinition(
      type: AdvancedServiceType.obituaryGenerate,
      title: '訃聞文案生成',
      cost: 1,
    ),
    AdvancedServiceType.obituaryRewrite: AdvancedServiceDefinition(
      type: AdvancedServiceType.obituaryRewrite,
      title: '訃聞文案重寫',
      cost: 1,
    ),
    AdvancedServiceType.obituaryExportPdf: AdvancedServiceDefinition(
      type: AdvancedServiceType.obituaryExportPdf,
      title: '訃聞匯出 PDF',
      cost: 1,
    ),
    AdvancedServiceType.obituaryExportImage: AdvancedServiceDefinition(
      type: AdvancedServiceType.obituaryExportImage,
      title: '訃聞匯出圖片',
      cost: 1,
    ),
  };

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _tokenLogs(String uid) =>
      _userDoc(uid).collection('tokenLogs');

  Stream<int> balanceStream(String uid) {
    return _userDoc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      return (data?['tokenBalance'] as num?)?.toInt() ?? 0;
    });
  }

  Future<int> getBalance(String uid) async {
    final snapshot = await _userDoc(uid).get();
    return (snapshot.data()?['tokenBalance'] as num?)?.toInt() ?? 0;
  }

  Future<TokenConsumeResult> consume({
    required String uid,
    required AdvancedServiceType type,
    String? note,
  }) async {
    final definition = definitions[type]!;
    final userRef = _userDoc(uid);

    return _firestore.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final balance = (snap.data()?['tokenBalance'] as num?)?.toInt() ?? 0;
      if (balance < definition.cost) {
        return TokenConsumeResult(
          ok: false,
          balanceAfter: balance,
          message: '點數不足，請先加值。',
        );
      }
      final after = balance - definition.cost;
      tx.set(
        userRef,
        {
          'tokenBalance': after,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      tx.set(
        _tokenLogs(uid).doc(),
        {
          'type': 'consume',
          'service': definition.type.name,
          'title': definition.title,
          'cost': definition.cost,
          'balanceBefore': balance,
          'balanceAfter': after,
          'note': note,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
      return TokenConsumeResult(ok: true, balanceAfter: after);
    });
  }
}
