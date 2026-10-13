# IskolarHub

A Flutter mobile app that helps students explore scholarship opportunities and
compare them with profile information. Built with Dart, Flutter, Firebase, and
SQLite.

**Platforms:** Android and iOS
**Repository:** [github.com/lloydgarcia0923320623-create/iskolarhub](https://github.com/lloydgarcia0923320623-create/iskolarhub)

IskolarHub is a scholarship discovery and tracking project. It combines a
searchable directory with preliminary, rule-based matching, saved-scholarship
checklists, offline access to cached information, and guidance tools.

## Features
- Student profile with GWA, course, year level, and household-income bracket
- Scholarship directory with preliminary rule-based matching, requirements, benefits, application periods, and official links
- Locally cached scholarship listings and student checklist data for offline viewing
- Restores a verified Firebase student session from local profile data when offline
- Student-submitted reports for outdated scholarship records, queued locally when offline
- Administrator review of submitted scholarship-information reports
- Scholarship record change notifications after an online refresh
- Saved-scholarship document checklist with application-readiness percentage and self-reported application status
- Deadline reminders for saved scholarships where the mobile platform permits notifications
- General document-preparation guide and editable reference templates
- Retrieval-based scholarship guidance grounded in records and guides stored in the app
- Gemini-powered, multi-turn AI guidance through Firebase AI Logic
- Administrator interface for managing eligibility, requirements, deadlines, links, benefits, and verification metadata
- Local SQLite persistence, with scholarship records synchronized from Firestore when configured and available

## Technology
- **App:** Flutter and Dart
- **Authentication and cloud data:** Firebase Authentication and Cloud Firestore
- **Local persistence:** SQLite and shared preferences
- **AI guidance:** Firebase AI Logic

## Project status and scope

This is a prototype and portfolio project, not an official scholarship
eligibility checker. Matching is preliminary and only evaluates structured
criteria recorded in the app. Students should verify current requirements and
apply through each scholarship provider's official channel. See
[Thesis alignment](#thesis-alignment) and [Study limitations](#study-limitations)
for details.

## Requirements
- Flutter SDK
- Android Studio / Android SDK
- Visual Studio Code with Flutter and Dart extensions

## Run
1. Open this folder in Visual Studio Code.
2. Open the terminal.
3. Run:
   `flutter pub get`
4. Check a device/emulator:
   `flutter devices`
5. Run:
   `flutter run`

## Accounts and setup

Student accounts use Firebase Authentication. Email/password registration
requires a verified email and a password of at least 12 characters containing
uppercase and lowercase letters, a number, and a symbol. The login screen
supports Firebase password reset. Administrator access requires the
server-managed Firebase custom claim `admin: true`; a local account or a
student-controlled profile cannot grant administrator privileges.

A newly extracted source folder must be run with Flutter using `flutter pub get`
and `flutter run`; the source folder is not itself an installable app.

The Google sign-in button requires the Firebase/Google configuration and an
Android device whose signing certificate is registered in Firebase.
Email/password sign-in and registration do not require Google sign-in.
Firestore scholarship edits and report review require an authenticated
administrator with the server-managed custom claim `admin: true`; the Firestore
rules enforce this.

To enable Gemini responses, enable Firebase AI Logic and the Gemini Developer
API for the configured Firebase project. The AI is configured in the client
through Firebase AI Logic; no Gemini API key is embedded in the app. Usage is
subject to the Firebase project’s model availability, quotas, and billing
settings. AI answers can be inaccurate and should be checked against official
provider information.

Firebase AI Logic uses Firebase App Check. The project currently has AI Logic
App Check enforcement set to **Basic - Unenforced**, but an app using the debug
provider still needs its token registered so Firebase can exchange it. The
connected Android development device's token is registered in Firebase. Each
additional device generates its own token; register it in Firebase Console
under **App Check > Apps > IskolarHub Android > Manage debug tokens**. If app
storage is cleared, the device may generate a new token that must also be
registered. Do not share or commit debug tokens; they bypass device attestation
and must be kept private.
Firebase Console warns that enforcement will be required starting November 2,
2026; before enforcing it, register other development tokens and production
attestation providers. Debug tokens are secrets that bypass device attestation;
remove them when testing is finished. Debug builds use the App Check debug
provider; release builds use Android Play Integrity and Apple App Attest.

Application status is student-reported, not read from scholarship-provider
portals. Status changes sync through Firestore for authenticated students.
Deploy the included Firestore rules to enable owner-only status sync and
administrator-only report review.

## Thesis alignment
Matching is preliminary and compares only profile values recorded by the student
with structured scholarship criteria. Application statuses are self-reported;
they are not synchronized with provider portals. Readiness percentages only
measure checked items in the personal checklist and do not represent official
eligibility, document validity, or approval probability. Guidance, document
information, and templates are references only and do not replace instructions
from scholarship providers or issuing agencies. The app does not submit
documents; students use the official external application channels.

## Study limitations

1. **Preliminary matching only.** Matching evaluates only structured GWA,
   household-income, course, and year-level criteria encoded in scholarship
   records. Essays, interviews, residency, leadership, moral character, and
   other qualitative or non-standard requirements are not automatically
   evaluated; recorded requirements are presented for student review.
2. **No official eligibility or acceptance determination.** Preliminary matches
   do not establish official eligibility or guarantee acceptance. Screening,
   ranking, verification, and award decisions belong to each provider.
3. **Self-reported application readiness.** Readiness reflects only checklist
   items the student marks complete. The app does not use OCR or verify document
   authenticity, quality, or actual completion.
4. **Manually maintained scholarship information.** Authorized administrators
   maintain records from identified sources. The app does not continuously
   scrape or retrieve provider websites, so changes may not appear immediately.
5. **Source verification and information currency.** Records may show source
   links, verification status, and last review date. A review records what was
   checked at that time; it does not guarantee that information remains current.
6. **Outdated-information reporting.** Students can report information that
   appears outdated or inconsistent. Reports require administrative review and
   re-verification; they do not automatically change scholarship records.
7. **Offline access and synchronization.** Offline use requires a previously
   authenticated Firebase session on that device. Viewing and editing locally
   cached profile/checklist data and queuing reports work offline; authentication,
   AI responses, cross-device sync, scholarship refresh, report delivery, and
   external provider links require connectivity. Scholarship cache entries may
   be outdated. When online, the app refreshes records and can notify students
   about detected changes. Refreshing scholarship information does not replace
   checklist progress.
8. **Notification limitations.** Deadline reminders depend on platform
   capabilities, permissions, device settings, and other device-level
   restrictions; delivery cannot be guaranteed.
9. **RAG-constrained AI guidance.** AI guidance uses retrieved scholarship
   records and the in-app document guide only. It does not independently search
   the open web, determine official eligibility, verify documents, or decide
   awards. When relevant stored information is insufficient, it should say so
   rather than provide an unsupported conclusion. Responses are informational
   and do not replace official provider instructions.
10. **Reference template and document-guide limitations.** Guides and templates
    are general references. Requirements and formats vary by provider, school,
    agency, and organization; students must follow the latest official
    instructions.
11. **No direct third-party application submission.** IskolarHub does not
    submit applications to providers. Students use the provider's official
    application channel.
12. **Self-reported application status.** Students enter their own application
    statuses. The app does not verify them with scholarship providers and is a
    personal monitoring tool, not an authoritative provider-status source.
13. **Limited external integration.** Decisions and other information are not
    retrieved from third-party scholarship systems unless an integration is
    specifically implemented and supported in the approved scope.
14. **Scholarship coverage.** Available opportunities depend on records entered
    by authorized administrators; the directory may not include every
    scholarship in the Philippines.
15. **Data privacy and security.** The app collects profile information needed
    for matching and tracking and restricts administrative functions to
    authorized users. Implementation and evaluation remain subject to the
    development environment's technical, resource, and security constraints.
16. **Development constraints.** The final implementation may be affected by
    development time, hardware, software, connectivity, third-party services,
    testing participants, and institutional constraints.
