// job_model.dart

class Job {
  final int id;
  final String updatedAt;
  final String slug;
  final String companyName;
  final String title;
  final int? remote;
  final String url;
  final String tags;
  final String? jobTypes;
  final String location;
  final String jobCreatedAt;
  final String description;
  final String? type; // Added type property
  final bool? isSaved;
  final bool? isApplied;

  Job({
    required this.id,
    required this.updatedAt,
    required this.slug,
    required this.companyName,
    required this.title,
    this.remote,
    required this.url,
    required this.tags,
    this.jobTypes,
    required this.location,
    required this.jobCreatedAt,
    required this.description,
    this.type,
    this.isSaved,
    this.isApplied,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'],
      updatedAt: json['updated_at'] ?? '',
      slug: json['slug'] ?? '',
      companyName: json['company_name'] ?? '',
      title: json['title'] ?? '',
      remote: json['remote'],
      url: json['url'] ?? '',
      tags: json['tags'] ?? '',
      jobTypes: json['job_types'],
      location: json['location'] ?? '',
      jobCreatedAt: json['job_created_at'] ?? '',
      description: json['description'] ?? '',
      type: json['type'], // Parse type from JSON
      isApplied: json['isApplied'], 
      isSaved: json['isSaved'], 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'updated_at': updatedAt,
      'slug': slug,
      'company_name': companyName,
      'title': title,
      'remote': remote,
      'url': url,
      'tags': tags,
      'job_types': jobTypes,
      'location': location,
      'job_created_at': jobCreatedAt,
      'description': description,
      'type': type,
      'isApplied': isApplied,
      'isSaved': isSaved,
    };
  }
    // ✅ COPY WITH METHOD - For updating individual fields
  Job copyWith({
    int? id,
    String? updatedAt,
    String? slug,
    String? companyName,
    String? title,
    int? remote,
    String? url,
    String? tags,
    String? jobTypes,
    String? location,
    String? jobCreatedAt,
    String? description,
    String? type,
    bool? isSaved,
    bool? isApplied,
  }) {
    return Job(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      slug: slug ?? this.slug,
      companyName: companyName ?? this.companyName,
      title: title ?? this.title,
      remote: remote ?? this.remote,
      url: url ?? this.url,
      tags: tags ?? this.tags,
      jobTypes: jobTypes ?? this.jobTypes,
      location: location ?? this.location,
      jobCreatedAt: jobCreatedAt ?? this.jobCreatedAt,
      description: description ?? this.description,
      type: type ?? this.type,
      isSaved: isSaved ?? this.isSaved,
      isApplied: isApplied ?? this.isApplied,
    );
  }

  // ✅ Helper methods for updating status
  // ✅ Helper methods for updating status
  Job markAsApplied() {
    return copyWith(isApplied: true);
  }

  Job markAsNotApplied() {
    return copyWith(isApplied: false);
  }

  Job markAsSaved() {
    return copyWith(isSaved: true);
  }

  Job markAsNotSaved() {
    return copyWith(isSaved: false);
  }

  Job toggleSaved() {
    return copyWith(isSaved: !(isSaved ?? false));
  }

  Job toggleApplied() {
    return copyWith(isApplied: !(isApplied ?? false));
  }
}