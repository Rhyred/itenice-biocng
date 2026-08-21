/// Represents a Bio-CNG project/plant.
class ProjectModel {
  final String id;
  final String name;
  final String location;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.location,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
    };
  }
}
