/// Domain model base contract.
abstract class BaseModel {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BaseModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });

  // Map key pair value
  Map<String, dynamic> toJson();
}
