import 'package:flutter/material.dart';

enum PlatformType { youtube, facebook, instagram, tiktok, twitter, other }

class VideoLink {
  String id;
  String title;
  String description;
  String url;
  String thumbnailUrl;
  PlatformType platform;
  DateTime createdAt;
  DateTime? reminder;
  String folderId;

  VideoLink({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.thumbnailUrl,
    required this.platform,
    required this.createdAt,
    this.reminder,
    required this.folderId,
  });

  VideoLink copyWith({
    String? id,
    String? title,
    String? description,
    String? url,
    String? thumbnailUrl,
    PlatformType? platform,
    DateTime? createdAt,
    DateTime? reminder,
    String? folderId,
  }) {
    return VideoLink(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
      reminder: reminder ?? this.reminder,
      folderId: folderId ?? this.folderId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'platform': platform.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'reminder': reminder?.toIso8601String(),
      'folderId': folderId,
    };
  }

  factory VideoLink.fromJson(Map<String, dynamic> json) {
    return VideoLink(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      url: json['url'],
      thumbnailUrl: json['thumbnailUrl'],
      platform: PlatformType.values.firstWhere(
        (e) => e.toString().split('.').last == json['platform'],
        orElse: () => PlatformType.other,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      reminder: json['reminder'] != null
          ? DateTime.parse(json['reminder'])
          : null,
      folderId: json['folderId'],
    );
  }

  IconData getPlatformIcon() {
    switch (platform) {
      case PlatformType.youtube:
        return Icons.youtube_searched_for;
      case PlatformType.facebook:
        return Icons.facebook;
      case PlatformType.instagram:
        return Icons.camera_alt;
      case PlatformType.tiktok:
        return Icons.music_note;
      case PlatformType.twitter:
        return Icons.campaign;
      case PlatformType.other:
        return Icons.link;
    }
  }

  Color getPlatformColor() {
    switch (platform) {
      case PlatformType.youtube:
        return Colors.red;
      case PlatformType.facebook:
        return Colors.blue;
      case PlatformType.instagram:
        return Colors.purple;
      case PlatformType.tiktok:
        return Colors.black;
      case PlatformType.twitter:
        return Colors.lightBlue;
      case PlatformType.other:
        return Colors.grey;
    }
  }
}
