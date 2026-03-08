class AvatarConfig {
  final String userId;
  final String hair;
  final String beard;
  final String clothes;

  AvatarConfig({
    required this.userId,
    this.hair = 'none',
    this.beard = 'none',
    this.clothes = 'basic_shirt',
  });

  factory AvatarConfig.fromJson(Map<String, dynamic> json) {
    return AvatarConfig(
      userId: json['user_id'] as String,
      hair: json['hair'] as String? ?? 'none',
      beard: json['beard'] as String? ?? 'none',
      clothes: json['clothes'] as String? ?? 'basic_shirt',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'hair': hair,
      'beard': beard,
      'clothes': clothes,
    };
  }

  AvatarConfig copyWith({
    String? userId,
    String? hair,
    String? beard,
    String? clothes,
  }) {
    return AvatarConfig(
      userId: userId ?? this.userId,
      hair: hair ?? this.hair,
      beard: beard ?? this.beard,
      clothes: clothes ?? this.clothes,
    );
  }

  Map<String, String> toMap() {
    return {
      'hair': hair,
      'beard': beard,
      'clothes': clothes,
    };
  }
}
