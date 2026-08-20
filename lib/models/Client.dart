class Client {
  final String id;
  final String clientName;
  final String contactPerson;
  final String email;
  final String phoneNumber;
  final String address;
  final String clientType; // individual / business
  final String currencyPreference;
  final String notes;

  Client({
    required this.id,
    required this.clientName,
    required this.contactPerson,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.clientType,
    required this.currencyPreference,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      "clientName": clientName,
      "contactPerson": contactPerson,
      "email": email,
      "phoneNumber": phoneNumber,
      "address": address,
      "clientType": clientType,
      "currencyPreference": currencyPreference,
      "notes": notes,
    };
  }

  factory Client.fromMap(String id, Map<String, dynamic> map) {
    return Client(
      id: id,
      clientName: map["clientName"] ?? "",
      contactPerson: map["contactPerson"] ?? "",
      email: map["email"] ?? "",
      phoneNumber: map["phoneNumber"] ?? "",
      address: map["address"] ?? "",
      clientType: map["clientType"] ?? "",
      currencyPreference: map["currencyPreference"] ?? "",
      notes: map["notes"] ?? "",
    );
  }
}