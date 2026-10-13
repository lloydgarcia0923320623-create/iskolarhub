/// A reference format for a document students commonly prepare.
///
/// Templates are guides only. Providers may require different wording or
/// formats, and students remain responsible for following the latest official
/// instructions.
class ApplicationTemplate {
  final String name;
  final String purpose;
  final List<String> usageNotes;
  final String body;

  const ApplicationTemplate({
    required this.name,
    required this.purpose,
    required this.usageNotes,
    required this.body,
  });
}

const List<ApplicationTemplate> applicationTemplates = [
  ApplicationTemplate(
    name: 'Scholarship application letter',
    purpose:
        'A formal letter to introduce yourself, state the scholarship you are '
        'applying for, and summarise why you qualify.',
    usageNotes: [
      'Replace every bracketed placeholder with your own details.',
      'Keep the letter to one page unless the provider states otherwise.',
      'Attach the letter only when the provider requires a cover letter.',
    ],
    body: '''[Date]

[Scholarship Committee / Office Name]
[Scholarship Provider Name]
[Provider Address]

Dear Sir/Madam:

I am [Full Name], a [Year Level] student of [Course] at [School Name]. I am writing to apply for the [Scholarship Program Name].

I have maintained a general weighted average of [GWA] and my household income falls under [Household Income Bracket]. These details meet the preliminary criteria published for this program. I believe this scholarship will help me continue my studies without the additional burden of tuition and school expenses.

I have prepared the following documents for your review: [List of Requirements].

Thank you for considering my application. I am willing to comply with any additional requirements and to be available for an interview at your convenience.

Respectfully yours,

[Signature over Printed Name]
[Contact Number]
[Email Address]''',
  ),
  ApplicationTemplate(
    name: 'Request for certified grades',
    purpose:
        'A short written request to the registrar for a certified copy of your '
        'grades or general weighted average.',
    usageNotes: [
      'Some registrars accept an online form instead of a letter.',
      'State the purpose so the certification is issued in the correct format.',
    ],
    body: '''[Date]

The Registrar
[School Name]

Dear Sir/Madam:

I would like to request a certified copy of my grades with my general weighted average for [School Term, School Year]. The certification will be used for a scholarship application with [Scholarship Provider Name].

I understand that the corresponding certification and documentary stamp fees will be paid. Please advise me of the processing time and any additional requirements.

Thank you.

Respectfully yours,

[Signature over Printed Name]
[Course and Year Level]
[Student Number]''',
  ),
  ApplicationTemplate(
    name: 'Statement of purpose',
    purpose:
        'A personal narrative explaining your background, goals, and need for '
        'financial assistance.',
    usageNotes: [
      'Answer the provider prompts in order, and stay within any word limit.',
      'Use specific experiences instead of general statements.',
      'Proofread for spelling and grammar before submitting.',
    ],
    body: '''STATEMENT OF PURPOSE

Name: [Full Name]
Course and Year Level: [Course and Year Level]
Scholarship Applied For: [Scholarship Program Name]

1. Academic background
I am enrolled in [Course] at [School Name] and have maintained a general weighted average of [GWA]. [Describe one academic achievement or subject that shaped your interest.]

2. Family and financial situation
My household consists of [Number of Household Members] members with a combined monthly income of approximately [Monthly Household Income]. [Explain the household circumstances that make financial assistance necessary.]

3. Career goals
After graduation I intend to [State Your Goal]. [Explain how the scholarship supports that goal.]

4. Why I am applying
I am applying for [Scholarship Program Name] because [State Your Reason]. I plan to [Describe how you will use the opportunity].

I certify that the information above is true and accurate.

[Signature over Printed Name]''',
  ),
];
