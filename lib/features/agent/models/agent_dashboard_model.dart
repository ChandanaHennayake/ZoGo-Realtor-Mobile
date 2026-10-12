class AgentDashboardModel {
  final int interestedProperties;
  final int pendingVisits;
  final int pendingDocuments;

  const AgentDashboardModel({
    required this.interestedProperties,
    required this.pendingVisits,
    required this.pendingDocuments,
  });

  factory AgentDashboardModel.fromJson(Map<String, dynamic> json) {
    return AgentDashboardModel(
      interestedProperties: (json['interestedProperties'] as num?)?.toInt() ?? 0,
      pendingVisits: (json['pendingVisits'] as num?)?.toInt() ?? 0,
      pendingDocuments: (json['pendingDocuments'] as num?)?.toInt() ?? 0,
    );
  }

  factory AgentDashboardModel.empty() {
    return const AgentDashboardModel(
      interestedProperties: 0,
      pendingVisits: 0,
      pendingDocuments: 0,
    );
  }
}
