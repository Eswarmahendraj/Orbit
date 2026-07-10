import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/painting.dart' show Color;

class AuraUser {
  final String uid;
  final String name;
  final String auraName; // unique ambient username e.g. "Midnight Birch"
  final String? email;
  final String? phone;
  final String? photoUrl;
  final List<String> interests;
  final String currentMood;
  final Color auraColor; // stored as hex int
  final String? spotifyTrack;
  final bool isOnline;
  final DateTime? birthday;
  final List<String> rootedConnections;
  final List<String> closeCircle;
  final bool showLikesCount;
  final DateTime createdAt;

  AuraUser({
    required this.uid,
    required this.name,
    required this.auraName,
    this.email,
    this.phone,
    this.photoUrl,
    this.interests = const [],
    this.currentMood = 'calm',
    this.auraColor = const Color(0xFF6C63FF),
    this.spotifyTrack,
    this.isOnline = false,
    this.birthday,
    this.rootedConnections = const [],
    this.closeCircle = const [],
    this.showLikesCount = false,
    required this.createdAt,
  });

  factory AuraUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuraUser(
      uid: doc.id,
      name: data['name'] ?? '',
      auraName: data['auraName'] ?? '',
      email: data['email'],
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      interests: List<String>.from(data['interests'] ?? []),
      currentMood: data['currentMood'] ?? 'calm',
      auraColor: Color(data['auraColor'] ?? 0xFF6C63FF),
      spotifyTrack: data['spotifyTrack'],
      isOnline: data['isOnline'] ?? false,
      birthday: data['birthday'] != null
          ? (data['birthday'] as Timestamp).toDate()
          : null,
      rootedConnections: List<String>.from(data['rootedConnections'] ?? []),
      closeCircle: List<String>.from(data['closeCircle'] ?? []),
      showLikesCount: data['showLikesCount'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'auraName': auraName,
    'email': email,
    'phone': phone,
    'photoUrl': photoUrl,
    'interests': interests,
    'currentMood': currentMood,
    'auraColor': auraColor.value,
    'spotifyTrack': spotifyTrack,
    'isOnline': isOnline,
    'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
    'rootedConnections': rootedConnections,
    'closeCircle': closeCircle,
    'showLikesCount': showLikesCount,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  AuraUser copyWith({
    String? name, String? auraName, String? photoUrl,
    List<String>? interests, String? currentMood,
    Color? auraColor, String? spotifyTrack, bool? isOnline,
    List<String>? rootedConnections, List<String>? closeCircle,
    bool? showLikesCount,
  }) => AuraUser(
    uid: uid, email: email, phone: phone, birthday: birthday,
    createdAt: createdAt,
    name: name ?? this.name,
    auraName: auraName ?? this.auraName,
    photoUrl: photoUrl ?? this.photoUrl,
    interests: interests ?? this.interests,
    currentMood: currentMood ?? this.currentMood,
    auraColor: auraColor ?? this.auraColor,
    spotifyTrack: spotifyTrack ?? this.spotifyTrack,
    isOnline: isOnline ?? this.isOnline,
    rootedConnections: rootedConnections ?? this.rootedConnections,
    closeCircle: closeCircle ?? this.closeCircle,
    showLikesCount: showLikesCount ?? this.showLikesCount,
  );
}

// Tenure emoji milestones
class TenureEmoji {
  static String getEmoji(int days) {
    if (days >= 90) return '🔮';
    if (days >= 61) return '💫';
    if (days >= 31) return '🔥';
    if (days >= 15) return '🌟';
    if (days >= 8)  return '🌸';
    if (days >= 4)  return '🌿';
    return '🌱';
  }

  static String getName(int days) {
    if (days >= 90) return 'Rooted Soul';
    if (days >= 61) return 'Cosmic';
    if (days >= 31) return 'On Fire';
    if (days >= 15) return 'Glowing';
    if (days >= 8)  return 'Blooming';
    if (days >= 4)  return 'Growing';
    return 'Sprout';
  }
}

