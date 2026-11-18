enum TodoPriority { low, normal, high }

class TodoItem {
  const TodoItem({
    required this.id,
    required this.title,
    required this.done,
    required this.priority,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.hour,
  });

  final String id;
  final String title;
  final bool done;
  final int? hour;
  final TodoPriority priority;

  /// Local calendar day this task belongs to. Time is intentionally ignored.
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'done': done,
    'hour': hour,
    'priority': priority.name,
    'date': date.toIso8601String(),
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
      // Tasks saved before dates were introduced belong to their creation day,
      // rather than reappearing on every later day at the same hour.
      date: _day(
        parseDate(json['date']) ??
            parseDate(json['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      ),
      createdAt:
          parseDate(json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          parseDate(json['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

bool todoAppliesToHour(TodoItem todo, DateTime date, int hour) =>
    !todo.done &&
    todo.hour == hour &&
    todo.date.year == date.year &&
    todo.date.month == date.month &&
    todo.date.day == date.day;
