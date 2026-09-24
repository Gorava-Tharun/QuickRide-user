/// Represents the user account profile in QuickRide.
class UserProfile {
  const UserProfile({
    required this.userId,
    required this.fullName,
    required this.mobileNumber,
    required this.email,
    required this.createdAt,
    this.profileImage,
  });

  final String userId;
  final String fullName;
  final String mobileNumber;
  final String email;
  final String? profileImage;
  final DateTime createdAt;

  /// Computed 2-letter initials for avatar placeholder (e.g. "AJ").
  String get initials {
    final parts = fullName.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty || parts[0].isEmpty) return "QR";
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Formatted creation date (e.g. "15 Jan 2026").
  String get formattedCreatedAt {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    return "${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}";
  }

  /// Formatted joined label (e.g. "Member since Jan 2026").
  String get formattedJoined {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    return "Member since ${months[createdAt.month - 1]} ${createdAt.year}";
  }

  UserProfile copyWith({
    String? userId,
    String? fullName,
    String? mobileNumber,
    String? email,
    String? profileImage,
    DateTime? createdAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "fullName": fullName,
      "mobileNumber": mobileNumber,
      "email": email,
      "profileImage": profileImage,
      "createdAt": createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json["userId"] as String? ?? "user_default",
      fullName: json["fullName"] as String? ?? "QuickRide User",
      mobileNumber: json["mobileNumber"] as String? ?? "9876543210",
      email: json["email"] as String? ?? "user@quickride.com",
      profileImage: json["profileImage"] as String?,
      createdAt: json["createdAt"] != null
          ? DateTime.tryParse(json["createdAt"] as String) ?? DateTime(2026, 1, 15)
          : DateTime(2026, 1, 15),
    );
  }
}
