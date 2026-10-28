import 'format.dart';
import 'iso_week.dart';

class CallCredit {
  const CallCredit({
    required this.id,
    required this.when,
    required this.canceled,
    required this.updatedAt,
  });

  final String id;
  final DateTime when;
  final bool canceled;
  final DateTime updatedAt;

  CallCredit copyWith({bool? canceled, DateTime? updatedAt}) {
    return CallCredit(
      id: id,
      when: when,
      canceled: canceled ?? this.canceled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'when': when.toIso8601String(),
    'canceled': canceled,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory CallCredit.fromJson(Map<String, dynamic> json) {
    return CallCredit(
      id: json['id'] as String? ?? 'credit',
      when: parseDate(json['when'] as String),
      canceled: json['canceled'] as bool? ?? false,
      updatedAt: parseDate(json['updatedAt'] as String),
    );
  }
}

/// Free accounts can start one fake call per ISO week. Premium is unlimited.
///
/// The week resets on Monday 00:00 in the device timezone (ISO week).
/// A reservation consumes a credit immediately. Cancelling before it rings
/// marks that credit canceled so the allowance comes back, including after sync.
class FakeCallPolicy {
  const FakeCallPolicy._();

  static const freeWeeklyLimit = 1;

  static int usedInWeek(List<CallCredit> credits, DateTime when) {
    final key = isoWeekKey(when);
    var count = 0;
    for (final credit in credits) {
      if (credit.canceled) continue;
      if (isoWeekKey(credit.when) == key) count++;
    }
    return count;
  }

  static bool canConsume({
    required bool premium,
    required List<CallCredit> credits,
    required DateTime when,
  }) {
    if (premium) return true;
    return usedInWeek(credits, when) < freeWeeklyLimit;
  }
}
