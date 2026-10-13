/// One reference entry in the Document Assistance Guide.
///
/// The guide provides general preparation information only. It does not replace
/// the official instructions of the issuing school, agency, or provider.
class DocumentGuideEntry {
  final String name;
  final String issuingOffice;
  final String summary;
  final List<String> steps;
  final List<String> reminders;
  final List<String> aliases;

  const DocumentGuideEntry({
    required this.name,
    required this.issuingOffice,
    required this.summary,
    required this.steps,
    required this.reminders,
    this.aliases = const [],
  });

  bool matches(String documentName) {
    final normalized = documentName.toLowerCase();
    if (normalized.contains(name.toLowerCase())) return true;
    return aliases.any((alias) => normalized.contains(alias.toLowerCase()));
  }
}

/// Static reference content for the documents most commonly requested by
/// scholarship providers.
const List<DocumentGuideEntry> documentGuideEntries = [
  DocumentGuideEntry(
    name: 'Grades',
    issuingOffice: 'Registrar or College Office',
    summary:
        'A certified copy of your grades or general weighted average, usually '
        'issued for the current or most recent term.',
    steps: [
      'Request a certification of grades at the registrar or your college office.',
      'State that the copy is for a scholarship application.',
      'Pay any certification or documentary stamp fee and keep the receipt.',
      'Check that the printed GWA matches your official record.',
    ],
    reminders: [
      'Most providers accept only certified copies, not screenshots.',
      'Ask whether the certification must be sealed and signed.',
    ],
    aliases: ['gwa', 'latest grades', 'school records'],
  ),
  DocumentGuideEntry(
    name: 'Certificate of enrollment',
    issuingOffice: 'Registrar',
    summary:
        'Proof that you are currently enrolled for the present school term.',
    steps: [
      'Request the certificate from the registrar during enrollment period.',
      'Confirm the certificate states your course, year level, and term.',
      'Ask for the number of copies your applications require.',
    ],
    reminders: [
      'Enrollment certificates are usually valid for one term only.',
      'Some providers also ask for the assessment form or official receipt.',
    ],
    aliases: ['enrollment certificate', 'certificate of registration'],
  ),
  DocumentGuideEntry(
    name: 'School ID',
    issuingOffice: 'School ID Section or Registrar',
    summary: 'A photocopy or certified copy of your current school identification.',
    steps: [
      'Photocopy the front and back of your current school ID.',
      'Have the copy certified at the registrar if the provider requires it.',
      'Keep the original with you during submission.',
    ],
    reminders: [
      'Expired or old school IDs may be rejected.',
      'Request a replacement early if your ID is lost.',
    ],
    aliases: ['valid school id', 'student id'],
  ),
  DocumentGuideEntry(
    name: 'Proof of household income',
    issuingOffice: 'Employer, Barangay, or BIR',
    summary:
        'Evidence of your family income, such as a certificate of employment, '
        'payslip, income tax return, or barangay certificate of indigency.',
    steps: [
      'Ask your parent or guardian for their certificate of employment or payslip.',
      'If self-employed or unemployed, request a barangay certificate instead.',
      'Prepare a short written statement if the household has no fixed income.',
      'Compile one document per income earner in the household.',
    ],
    reminders: [
      'Providers usually ask for monthly, not annual, amounts.',
      'Barangay certificates may require residency proof such as a utility bill.',
    ],
    aliases: [
      'income document',
      'income documents',
      'family income documents',
      'proof of income',
    ],
  ),
  DocumentGuideEntry(
    name: 'Barangay certificate',
    issuingOffice: 'Barangay Hall',
    summary:
        'A certificate issued by your barangay, commonly used for residency or '
        'indigency verification.',
    steps: [
      'Go to the barangay hall where you currently reside.',
      'Request a certificate of residency or indigency and state its purpose.',
      'Present a valid ID and pay the corresponding fee.',
      'Ask the barangay staff to sign and seal the certificate.',
    ],
    reminders: [
      'Some barangays require the applicant to appear personally.',
      'Barangay certificates often expire after six months.',
    ],
    aliases: ['certificate of residency', 'certificate of indigency'],
  ),
  DocumentGuideEntry(
    name: 'Valid government ID',
    issuingOffice: 'PSA, PhilSys, LTO, or other issuing agency',
    summary:
        'An unexpired identification card or supporting document issued by a '
        'government agency.',
    steps: [
      'Use an unexpired ID such as a passport, PhilSys ID, or driver\'s license.',
      'Photocopy the ID clearly, including the ID number and expiry date.',
      'Bring the original when submitting in person.',
    ],
    reminders: [
      'A PSA birth certificate is often accepted when no ID is available yet.',
      'Confirm which IDs the provider accepts before travelling.',
    ],
    aliases: ['government id', 'valid id', 'psa birth certificate'],
  ),
  DocumentGuideEntry(
    name: 'Birth certificate',
    issuingOffice: 'Philippine Statistics Authority (PSA)',
    summary: 'A PSA-issued copy of your certificate of live birth.',
    steps: [
      'Order a copy online through the PSA Serbilis portal, or visit a PSA outlet.',
      'Provide your complete name, birth date, and parents\' names.',
      'Pay the fee and keep the reference number for follow-up.',
      'Check that all entries are legible before submitting.',
    ],
    reminders: [
      'Processing can take several days, so order early.',
      'A local civil registrar copy may be accepted by some providers.',
    ],
    aliases: ['certificate of live birth'],
  ),
  DocumentGuideEntry(
    name: 'Personal statement',
    issuingOffice: 'Written by the student',
    summary:
        'A short written piece describing your background, goals, and why you '
        'are applying for the scholarship.',
    steps: [
      'Answer every prompt the provider lists, in the order given.',
      'Write about your own circumstances using specific examples.',
      'Keep the tone formal and proofread before finalising.',
      'Stay within any stated word or character limit.',
    ],
    reminders: [
      'Do not copy text from another applicant or an online sample.',
      'Save a copy in case the provider asks for revisions.',
    ],
    aliases: [
      'statement of purpose',
      'personal essay',
      'community reference',
      'recommendation letter',
    ],
  ),
  DocumentGuideEntry(
    name: 'Certificate of admission',
    issuingOffice: 'Registrar or Admissions Office',
    summary:
        'Proof that you have been accepted into a degree program at the institution.',
    steps: [
      'Request the certificate from the admissions or registrar office.',
      'Confirm it names the degree program you are enrolling in.',
      'Ask for an extra copy for other applications.',
    ],
    reminders: [
      'Some programs require admission to a priority or accredited program.',
    ],
    aliases: ['letter of admission', 'notice of admission'],
  ),
];

/// Fallback shown when a requirement has no dedicated guide entry.
const DocumentGuideEntry genericDocumentGuideEntry = DocumentGuideEntry(
  name: 'General document preparation',
  issuingOffice: 'Issuing office depends on the requirement',
  summary:
      'Follow the requirement exactly as the scholarship provider lists it. '
      'Request the document from the office that issues it and keep a copy for '
      'your records.',
  steps: [
    'Read the requirement wording carefully and note any format it specifies.',
    'Identify the office or agency that issues the document.',
    'Request the document early and ask how long processing will take.',
    'Check the spelling of your name and other details before submitting.',
    'Keep a scanned copy of the final document.',
  ],
  reminders: [
    'Requirements and formats vary between scholarship providers.',
    'Always follow the latest official instructions of the provider.',
  ],
);

/// Finds the guide entry that best matches a requirement name.
DocumentGuideEntry guideEntryFor(String documentName) {
  for (final entry in documentGuideEntries) {
    if (entry.matches(documentName)) return entry;
  }
  return genericDocumentGuideEntry;
}
