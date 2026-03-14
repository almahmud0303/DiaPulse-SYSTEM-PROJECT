enum GlucoseTrendPeriod {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly');

  const GlucoseTrendPeriod(this.label);

  final String label;
}
