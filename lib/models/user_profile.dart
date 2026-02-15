class UserProfile {
  final int? id;
  final String userName;
  final String? companyName;
  final String? companyAddress;
  final String? companyPhone;
  final String? companyEmail;
  final String? gstNumber;

  UserProfile({
    this.id,
    required this.userName,
    this.companyName,
    this.companyAddress,
    this.companyPhone,
    this.companyEmail,
    this.gstNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userName': userName,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'companyPhone': companyPhone,
      'companyEmail': companyEmail,
      'gstNumber': gstNumber,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      userName: map['userName'] as String,
      companyName: map['companyName'] as String?,
      companyAddress: map['companyAddress'] as String?,
      companyPhone: map['companyPhone'] as String?,
      companyEmail: map['companyEmail'] as String?,
      gstNumber: map['gstNumber'] as String?,
    );
  }

  UserProfile copyWith({
    int? id,
    String? userName,
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyEmail,
    String? gstNumber,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      companyPhone: companyPhone ?? this.companyPhone,
      companyEmail: companyEmail ?? this.companyEmail,
      gstNumber: gstNumber ?? this.gstNumber,
    );
  }

  // Default profile
  static UserProfile defaultProfile() {
    return UserProfile(
      userName: 'user',
      companyName: '',
      companyAddress: '',
      companyPhone: '',
      companyEmail: '',
      gstNumber: '',
    );
  }
}
