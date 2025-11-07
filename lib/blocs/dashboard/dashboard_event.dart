import 'package:equatable/equatable.dart';
import '../../models/daily_summary.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends DashboardEvent {
  const LoadDashboardData();
}

class RefreshDashboardData extends DashboardEvent {
  const RefreshDashboardData();
}

class LoadWeeklySummary extends DashboardEvent {
  final DateTime weekStart;

  const LoadWeeklySummary(this.weekStart);

  @override
  List<Object?> get props => [weekStart];
}

class LoadMonthlySummary extends DashboardEvent {
  final int year;
  final int month;

  const LoadMonthlySummary(this.year, this.month);

  @override
  List<Object?> get props => [year, month];
}

class DailySummaryUpdated extends DashboardEvent {
  final List<DailySummary> summaries;

  const DailySummaryUpdated(this.summaries);

  @override
  List<Object?> get props => [summaries];
}
