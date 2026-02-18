class AlarmModel {
  const AlarmModel({
    required this.id,
    required this.scheduledAt,
    this.title = 'Alarm Reminder',
  });

  final int id;
  final DateTime scheduledAt;
  final String title;

  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'] as int,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      title: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'scheduledAt': scheduledAt.toIso8601String(),
      'title': title,
    };
  }
}
