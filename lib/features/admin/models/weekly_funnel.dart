import '../../../data/models/purchase.dart';

class WeeklyFunnelBucket {
  WeeklyFunnelBucket({
    required this.label,
    required this.proposal,
    required this.approved,
    required this.assigned,
    required this.delivered,
  });

  final String label;
  final int proposal;
  final int approved;
  final int assigned;
  final int delivered;
}

class WeeklyFunnelSnapshot {
  const WeeklyFunnelSnapshot({required this.buckets, required this.maxCount});

  final List<WeeklyFunnelBucket> buckets;
  final int maxCount;
}

WeeklyFunnelSnapshot buildWeeklyFunnelSnapshot(
  List<Purchase> orders, {
  DateTime? now,
  int weeks = 8,
}) {
  final current = now ?? DateTime.now();
  final thisWeekStart = _weekStart(current);
  final weekStarts = List<DateTime>.generate(
    weeks,
    (index) => thisWeekStart.subtract(Duration(days: 7 * (weeks - 1 - index))),
  );
  final byWeek = <String, _MutableBucket>{
    for (final week in weekStarts)
      _weekKey(week): _MutableBucket(
        label: _weekLabel(week),
        proposal: 0,
        approved: 0,
        assigned: 0,
        delivered: 0,
      ),
  };

  for (final order in orders) {
    _incrementWeek(
      byWeek,
      _proposalAt(order),
      (bucket) => bucket.proposal += 1,
    );
    _incrementWeek(
      byWeek,
      _approvedAt(order),
      (bucket) => bucket.approved += 1,
    );
    _incrementWeek(
      byWeek,
      _assignedAt(order),
      (bucket) => bucket.assigned += 1,
    );
    _incrementWeek(
      byWeek,
      _deliveredAt(order),
      (bucket) => bucket.delivered += 1,
    );
  }

  final buckets = weekStarts.map((week) {
    final mutable = byWeek[_weekKey(week)]!;
    return WeeklyFunnelBucket(
      label: mutable.label,
      proposal: mutable.proposal,
      approved: mutable.approved,
      assigned: mutable.assigned,
      delivered: mutable.delivered,
    );
  }).toList();

  final maxCount = buckets.fold<int>(1, (prev, bucket) {
    final localMax = [
      bucket.proposal,
      bucket.approved,
      bucket.assigned,
      bucket.delivered,
    ].reduce((a, b) => a > b ? a : b);
    return localMax > prev ? localMax : prev;
  });
  return WeeklyFunnelSnapshot(buckets: buckets, maxCount: maxCount);
}

DateTime _weekStart(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final weekday = normalized.weekday;
  return normalized.subtract(Duration(days: weekday - 1));
}

String _weekKey(DateTime weekStart) =>
    '${weekStart.year}-${weekStart.month}-${weekStart.day}';

String _weekLabel(DateTime weekStart) {
  final weekEnd = weekStart.add(const Duration(days: 6));
  final start = '${weekStart.month}/${weekStart.day}';
  final end = '${weekEnd.month}/${weekEnd.day}';
  return '$start-$end';
}

void _incrementWeek(
  Map<String, _MutableBucket> byWeek,
  DateTime? value,
  void Function(_MutableBucket bucket) increment,
) {
  if (value == null) return;
  final week = _weekStart(value);
  final bucket = byWeek[_weekKey(week)];
  if (bucket == null) return;
  increment(bucket);
}

DateTime? _proposalAt(Purchase order) {
  final proposal = order.proposal;
  if (proposal == null || proposal.isEmpty) return null;
  return proposal.submittedAt ?? order.createdAt;
}

DateTime? _approvedAt(Purchase order) {
  if (!_isApproved(order)) return null;
  return order.verifiedAt ??
      _latestVerificationAt(order) ??
      _proposalAt(order) ??
      order.createdAt;
}

DateTime? _assignedAt(Purchase order) {
  final assigned =
      order.vendorAssignment != null && !order.vendorAssignment!.isEmpty;
  if (!assigned) return null;
  return order.verifiedAt ?? _latestVerificationAt(order) ?? _approvedAt(order);
}

DateTime? _deliveredAt(Purchase order) {
  if (!_isDeliveryCompleted(order)) return null;
  final delivered = order.deliverySchedule
      .where((item) => item.code == 'delivered' && item.status == 'done')
      .toList();
  if (delivered.isNotEmpty) {
    return delivered.last.updatedAt ?? delivered.last.targetDate;
  }
  return order.verifiedAt ?? _assignedAt(order);
}

DateTime? _latestVerificationAt(Purchase order) {
  if (order.verificationLogs.isEmpty) return null;
  return order.verificationLogs.last.actedAt;
}

bool _isApproved(Purchase order) {
  final proposalReady = order.proposal != null && !order.proposal!.isEmpty;
  final vendorReady =
      order.vendorAssignment != null && !order.vendorAssignment!.isEmpty;
  final materialReady =
      order.materialSelection != null && !order.materialSelection!.isEmpty;
  if (!proposalReady) return false;
  return order.status != 'pending' ||
      order.verificationLogs.isNotEmpty ||
      vendorReady ||
      materialReady;
}

bool _isDeliveryCompleted(Purchase order) {
  final deliveredDone = order.deliverySchedule.any(
    (item) => item.code == 'delivered' && item.status == 'done',
  );
  return deliveredDone || order.status == 'complete';
}

class _MutableBucket {
  _MutableBucket({
    required this.label,
    required this.proposal,
    required this.approved,
    required this.assigned,
    required this.delivered,
  });

  final String label;
  int proposal;
  int approved;
  int assigned;
  int delivered;
}
