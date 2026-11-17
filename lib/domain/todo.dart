enum TodoPriority { low, normal, high }

class TodoItem {
  const TodoItem({
    required this.id,
    required this.title,
    required this.done,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.hour,
  });

  final String id;
  final String title;
  final bool done;
  final int? hour;
  final TodoPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'done': done,
    'hour': hour,
    'priority': priority.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? value) =>
        value is String ? DateTime.tryParse(value)?.toLocal() : null;
    final priorityName = json['priority'] as String?;
    final priority = TodoPriority.values.firstWhere(
      (item) => item.name == priorityName,
      orElse: () => TodoPriority.normal,
    );
    final hour = (json['hour'] as num?)?.toInt();
    return TodoItem(
      id: json['id'] as String? ?? 'todo',
      title: json['title'] as String? ?? '',
      done: json['done'] as bool? ?? false,
      hour: hour != null && hour >= 0 && hour <= 23 ? hour : null,
      priority: priority,
      createdAt:
          parseDate(json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          parseDate(json['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

bool todoAppliesToHour(TodoItem todo, int hour) =>
    !todo.done && todo.hour == hour;
