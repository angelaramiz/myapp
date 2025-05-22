class Folder {
  String id;
  String name;
  String? description;
  DateTime createdAt;

  Folder({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  Folder copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
