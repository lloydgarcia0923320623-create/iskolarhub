/// Administrative verification state of a scholarship record.
///
/// Verification means an administrator reviewed the record against an
/// identified official source on a recorded date. It does not guarantee that
/// the provider's information is unchanged after that review.
enum VerificationStatus {
  verified,
  unverified,
  archived;

  static const Map<VerificationStatus, String> _labels = {
    VerificationStatus.verified: 'Verified',
    VerificationStatus.unverified: 'Unverified',
    VerificationStatus.archived: 'Archived',
  };

  static const Map<VerificationStatus, String> _descriptions = {
    VerificationStatus.verified:
        'Reviewed against an official source on the recorded date.',
    VerificationStatus.unverified:
        'Not yet reviewed against an official source by an administrator.',
    VerificationStatus.archived:
        'Withdrawn from active listings and kept for reference only.',
  };

  String get label => _labels[this]!;

  String get description => _descriptions[this]!;

  bool get isArchived => this == VerificationStatus.archived;

  bool get isVerified => this == VerificationStatus.verified;

  static VerificationStatus fromName(String? value) {
    for (final status in VerificationStatus.values) {
      if (status.name == value) return status;
    }
    return VerificationStatus.unverified;
  }
}
