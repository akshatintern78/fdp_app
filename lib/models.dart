class AppUser {
  const AppUser({required this.id, required this.name, required this.email, required this.mobile});

  final int id;
  final String name;
  final String email;
  final String mobile;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: _asInt(json['id']),
      name: json['name'] as String,
      email: json['email'] as String,
      mobile: json['mobile'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'mobile': mobile};
}

class Receipt {
  const Receipt({
    required this.id,
    required this.serialNo,
    required this.date,
    required this.fullName,
    required this.address,
    required this.mobile,
    required this.amount,
    required this.amountInWords,
    required this.paymentRef,
    required this.hasSignature,
    this.signatureBase64,
    required this.createdAt,
  });

  final int id;
  final int serialNo;
  final String date;
  final String fullName;
  final String address;
  final String mobile;
  final double amount;
  final String amountInWords;
  final String paymentRef;
  final bool hasSignature;
  final String? signatureBase64;
  final String createdAt;

  List<String> get addressLines {
    final lines = address.split(RegExp(r'\r?\n')).map((line) => line.trim()).toList();
    while (lines.length < 3) {
      lines.add('');
    }
    return lines.take(3).toList();
  }

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: _asInt(json['id']),
      serialNo: _asInt(json['serialNo']),
      date: json['date'].toString(),
      fullName: json['fullName'] as String,
      address: json['address'] as String,
      mobile: json['mobile'] as String,
      amount: _asDouble(json['amount']),
      amountInWords: json['amountInWords'] as String,
      paymentRef: json['paymentRef'] as String,
      hasSignature: json['hasSignature'] == true,
      signatureBase64: json['signatureBase64'] as String?,
      createdAt: json['createdAt'].toString(),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.parse(value.toString());
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.parse(value.toString());
}
