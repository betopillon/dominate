import 'game_stats.dart';

enum AvatarType {
  image,
  avatar,
}

enum AvatarOption {
  astronaut,
  robot,
  alien,
  cat,
  dog,
  dragon,
  wizard,
  knight,
  ninja,
  pirate,
}

class PlayerProfile {
  final String id;
  final String email;
  final String nickname;
  final String? passwordHash;
  final String? salt;
  final AvatarType avatarType;
  final String? imagePath; // Path to uploaded image
  final AvatarOption? avatarOption; // Selected avatar
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEmailVerified;
  final PlayerStats stats; // Game statistics

  PlayerProfile({
    required this.id,
    required this.email,
    required this.nickname,
    this.passwordHash,
    this.salt,
    required this.avatarType,
    this.imagePath,
    this.avatarOption,
    required this.createdAt,
    required this.updatedAt,
    this.isEmailVerified = false,
    PlayerStats? stats,
  }) : stats = stats ?? PlayerStats();

  // Copy constructor for updates
  PlayerProfile copyWith({
    String? email,
    String? nickname,
    String? passwordHash,
    String? salt,
    AvatarType? avatarType,
    String? imagePath,
    AvatarOption? avatarOption,
    bool? isEmailVerified,
    PlayerStats? stats,
  }) {
    return PlayerProfile(
      id: id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      avatarType: avatarType ?? this.avatarType,
      imagePath: imagePath ?? this.imagePath,
      avatarOption: avatarOption ?? this.avatarOption,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      stats: stats ?? this.stats,
    );
  }

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'passwordHash': passwordHash,
      'salt': salt,
      'avatarType': avatarType.name,
      'imagePath': imagePath,
      'avatarOption': avatarOption?.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'stats': stats.toJson(),
    };
  }

  // Create from JSON
  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      id: json['id'],
      email: json['email'],
      nickname: json['nickname'],
      passwordHash: json['passwordHash'],
      salt: json['salt'],
      avatarType: AvatarType.values.firstWhere((e) => e.name == json['avatarType']),
      imagePath: json['imagePath'],
      avatarOption: json['avatarOption'] != null
          ? AvatarOption.values.firstWhere((e) => e.name == json['avatarOption'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isEmailVerified: json['isEmailVerified'] ?? false,
      stats: json['stats'] != null
          ? PlayerStats.fromJson(json['stats'])
          : PlayerStats(),
    );
  }

  // Create temporary profile for unregistered players
  factory PlayerProfile.temporary({
    required String nickname,
    required AvatarOption avatarOption,
  }) {
    final now = DateTime.now();
    return PlayerProfile(
      id: 'temp_${now.millisecondsSinceEpoch}',
      email: '',
      nickname: nickname,
      avatarType: AvatarType.avatar,
      avatarOption: avatarOption,
      createdAt: now,
      updatedAt: now,
      isEmailVerified: false,
      stats: PlayerStats(),
    );
  }

  bool get isTemporary => email.isEmpty;
  bool get isRegistered => email.isNotEmpty;
}

// Helper extension for avatar options
extension AvatarOptionExtension on AvatarOption {
  String get displayName {
    switch (this) {
      case AvatarOption.astronaut:
        return 'Astronaut';
      case AvatarOption.robot:
        return 'Robot';
      case AvatarOption.alien:
        return 'Alien';
      case AvatarOption.cat:
        return 'Space Cat';
      case AvatarOption.dog:
        return 'Space Dog';
      case AvatarOption.dragon:
        return 'Space Dragon';
      case AvatarOption.wizard:
        return 'Space Wizard';
      case AvatarOption.knight:
        return 'Space Knight';
      case AvatarOption.ninja:
        return 'Space Ninja';
      case AvatarOption.pirate:
        return 'Space Pirate';
    }
  }

  String get emoji {
    switch (this) {
      case AvatarOption.astronaut:
        return '👨‍🚀';
      case AvatarOption.robot:
        return '🤖';
      case AvatarOption.alien:
        return '👽';
      case AvatarOption.cat:
        return '🐱';
      case AvatarOption.dog:
        return '🐶';
      case AvatarOption.dragon:
        return '🐉';
      case AvatarOption.wizard:
        return '🧙‍♂️';
      case AvatarOption.knight:
        return '⚔️';
      case AvatarOption.ninja:
        return '🥷';
      case AvatarOption.pirate:
        return '🏴‍☠️';
    }
  }
}