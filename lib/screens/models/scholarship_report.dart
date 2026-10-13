/// Review state of a student-submitted report about a scholarship record.
enum ReportStatus {
  pending,
  reviewed,
  resolved,
  dismissed;

  static const Map<ReportStatus, String> _labels = {
    ReportStatus.pending: 'Pending review',
    ReportStatus.reviewed: 'Under review',
    ReportStatus.resolved: 'Record updated',
    ReportStatus.dismissed: 'No change needed',
  };

  String get label => _labels[this]!;

  static ReportStatus fromName(String? value) {
    for (final status in ReportStatus.values) {
      if (status.name == value) return status;
    }
    return ReportStatus.pending;
  }
}

/// A student report that a scholarship record looks outdated or inconsistent
/// with the provider's official source.
///
/// A report never modifies the scholarship record by itself. It is queued for
/// administrative review and re-verification.
class ScholarshipReport {
  final int? id;
  final int userId;
  final String scholarshipId;
  final String note;
  final DateTime createdAt;
  final ReportStatus status;
  final String reviewerNote;
  final DateTime? reviewedAt;
  final String ownerUid;
  final String? firestoreId;
  final bool pendingSync;

  const ScholarshipReport({
    this.id,
    required this.userId,
    required this.scholarshipId,
    required this.note,
    required this.createdAt,
    this.status = ReportStatus.pending,
    this.reviewerNote = '',
    this.reviewedAt,
    this.ownerUid = '',
    this.firestoreId,
    this.pendingSync = false,
  });

  ScholarshipReport copyWith({
    ReportStatus? status,
    String? reviewerNote,
    DateTime? reviewedAt,
    String? firestoreId,
    bool? pendingSync,
  }) {
    return ScholarshipReport(
      id: id,
      userId: userId,
      scholarshipId: scholarshipId,
      note: note,
      createdAt: createdAt,
      status: status ?? this.status,
      reviewerNote: reviewerNote ?? this.reviewerNote,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      ownerUid: ownerUid,
      firestoreId: firestoreId ?? this.firestoreId,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }
}
