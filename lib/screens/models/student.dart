import 'income_bracket.dart';

class Student {
  String name;
  String course;
  int yearLevel;
  double gwa;
  double householdIncome;
  IncomeBracket? incomeBracket;

  Student({
    this.name = '',
    this.course = '',
    this.yearLevel = 1,
    this.gwa = 0,
    this.householdIncome = 0,
    this.incomeBracket,
  });
}
