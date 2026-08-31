// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: user_model.dart
//
// Purpose:
// Immutable domain entity representing an authenticated user profile in PocketDay.
//
// Responsibilities:
// - Hold profile properties (uid, email, displayName, photoUrl, createdAt).
// - Provide `toMap()` and `fromMap()` for Hive persistence in `userBox`.
// - Provide `copyWith()` for state modification.
//
// Data Flow:
// AuthRepository / AuthNotifier ↔ UserModel ↔ Hive (userBox)
//
// Important Rules:
// - Dates are serialized as ISO 8601 strings.
//
// Main Operations:
// - toMap(): Convert UserModel to Map<String, dynamic>
// - UserModel.fromMap(map): Construct UserModel from Hive Map
// - copyWith(): Return modified copy of UserModel
// ============================================================

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'User',
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
