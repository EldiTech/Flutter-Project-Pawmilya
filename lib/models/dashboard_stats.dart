class DashboardStats {
  DashboardStats({
    required this.totalAnimals,
    required this.totalApplications,
    required this.pendingApplications,
    required this.totalAdoptions,
    required this.approvedApplications,
    required this.activeEmployees,
    required this.adoptedAnimals,
    required this.avgTemp,
    required this.avgHumidity,
    required this.successRate,
  });

  final int activeEmployees;
  final int approvedApplications;
  final int adoptedAnimals;
  final int avgHumidity;
  final int avgTemp;
  final int pendingApplications;
  final int successRate;
  final int totalAdoptions;
  final int totalAnimals;
  final int totalApplications;
}
