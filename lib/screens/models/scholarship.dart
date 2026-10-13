import 'verification_status.dart';

/// A scholarship program listed in the IskolarHub directory.
///
/// [courses], [yearLevels], [minGwa], and [maxIncome] are the deterministic
/// criteria evaluated by rule-based matching. [descriptiveRequirements] holds
/// qualitative criteria (essays, interviews, residency, and similar) that are
/// presented for manual review and are never evaluated automatically.
class Scholarship {
  final String id;
  final String name;
  final String provider;
  final String description;
  final double minGwa;
  final List<String> courses;
  final List<int> yearLevels;
  final double maxIncome;
  final DateTime deadline;
  final List<String> requirements;
  final String applicationUrl;

  /// Summary of the benefits granted by the program.
  final String benefits;

  /// Human-readable application window, e.g. `June 1 - September 30, 2026`.
  final String applicationPeriod;

  /// Official source page the record was encoded from.
  final String sourceUrl;

  /// Administrative verification state of this record.
  final VerificationStatus verificationStatus;

  /// When an administrator last reviewed this record against its source.
  final DateTime? lastVerifiedAt;

  /// Qualitative requirements that require manual student review.
  final List<String> descriptiveRequirements;

  const Scholarship({
    required this.id,
    required this.name,
    required this.provider,
    required this.description,
    required this.minGwa,
    required this.courses,
    required this.yearLevels,
    required this.maxIncome,
    required this.deadline,
    required this.requirements,
    required this.applicationUrl,
    this.benefits = '',
    this.applicationPeriod = '',
    this.sourceUrl = '',
    this.verificationStatus = VerificationStatus.unverified,
    this.lastVerifiedAt,
    this.descriptiveRequirements = const [],
  });

  /// `true` when an administrator has archived the listing.
  bool get isArchived => verificationStatus.isArchived;

  Scholarship copyWith({
    String? name,
    String? provider,
    String? description,
    double? minGwa,
    List<String>? courses,
    List<int>? yearLevels,
    double? maxIncome,
    DateTime? deadline,
    List<String>? requirements,
    String? applicationUrl,
    String? benefits,
    String? applicationPeriod,
    String? sourceUrl,
    VerificationStatus? verificationStatus,
    DateTime? lastVerifiedAt,
    List<String>? descriptiveRequirements,
  }) {
    return Scholarship(
      id: id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      description: description ?? this.description,
      minGwa: minGwa ?? this.minGwa,
      courses: courses ?? this.courses,
      yearLevels: yearLevels ?? this.yearLevels,
      maxIncome: maxIncome ?? this.maxIncome,
      deadline: deadline ?? this.deadline,
      requirements: requirements ?? this.requirements,
      applicationUrl: applicationUrl ?? this.applicationUrl,
      benefits: benefits ?? this.benefits,
      applicationPeriod: applicationPeriod ?? this.applicationPeriod,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      descriptiveRequirements:
          descriptiveRequirements ?? this.descriptiveRequirements,
    );
  }
}
