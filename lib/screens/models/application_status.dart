/// Student-reported progress of an application submitted through an external
/// scholarship provider channel.
///
/// The value is self-reported. It is a personal monitoring aid and is not an
/// authoritative provider-side status.
enum ApplicationStatus {
  notStarted,
  preparing,
  submitted,
  completed;

  static const Map<ApplicationStatus, String> _labels = {
    ApplicationStatus.notStarted: 'Not Started',
    ApplicationStatus.preparing: 'Preparing',
    ApplicationStatus.submitted: 'Submitted',
    ApplicationStatus.completed: 'Completed',
  };

  String get label => _labels[this]!;

  bool get isActive => this != ApplicationStatus.notStarted;

  static ApplicationStatus fromName(String? value) {
    for (final status in ApplicationStatus.values) {
      if (status.name == value) return status;
    }
    return ApplicationStatus.notStarted;
  }
}
