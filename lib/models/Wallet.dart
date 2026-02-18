class WalletModel {
  final String id;
  final String name;
  final String icon; // Icon name identifier
  final double balance;
  final String type; // 'cash', 'bank', 'digital'
  final String userId;

  WalletModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.balance,
    required this.type,
    required this.userId,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'wallet',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] ?? 'cash',
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'balance': balance,
      'type': type,
      'userId': userId,
    };
  }

  WalletModel copyWith({
    String? id,
    String? name,
    String? icon,
    double? balance,
    String? type,
    String? userId,
  }) {
    return WalletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      balance: balance ?? this.balance,
      type: type ?? this.type,
      userId: userId ?? this.userId,
    );
  }

  /// Returns default wallets for a new user
  static List<WalletModel> getDefaultWallets(String userId) {
    return [
      WalletModel(
        id: 'wallet_cash_$userId',
        name: 'Cash',
        icon: 'cash',
        balance: 0.0,
        type: 'cash',
        userId: userId,
      ),
      WalletModel(
        id: 'wallet_bank_$userId',
        name: 'Bank',
        icon: 'bank',
        balance: 0.0,
        type: 'bank',
        userId: userId,
      ),
      WalletModel(
        id: 'wallet_digital_$userId',
        name: 'Digital Wallet',
        icon: 'digital',
        balance: 0.0,
        type: 'digital',
        userId: userId,
      ),
    ];
  }

  static List<Map<String, dynamic>> listToJson(List<WalletModel> wallets) {
    return wallets.map((wallet) => wallet.toJson()).toList();
  }

  static List<WalletModel> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) => WalletModel.fromJson(json)).toList();
  }
}
