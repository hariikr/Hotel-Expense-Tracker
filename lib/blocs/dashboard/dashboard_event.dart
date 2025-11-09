import 'package:equatable/equatable.dart';
import '../../models/daily_summary.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends DashboardEvent {
  final String? context;

  const LoadDashboardData({this.context});

  @override
  List<Object?> get props => [context];
}

class RefreshDashboardData extends DashboardEvent {
  final String? context;

  const RefreshDashboardData({this.context});

  @override
  List<Object?> get props => [context];
}

class LoadWeeklySummary extends DashboardEvent {
  final DateTime weekStart;
  final String? context;

  const LoadWeeklySummary(this.weekStart, {this.context});

  @override
  List<Object?> get props => [weekStart, context];
}

class LoadMonthlySummary extends DashboardEvent {
  final int year;
  final int month;
  final String? context;

  const LoadMonthlySummary(this.year, this.month, {this.context});

  @override
  List<Object?> get props => [year, month, context];
}

class DailySummaryUpdated extends DashboardEvent {
  final List<DailySummary> summaries;

  const DailySummaryUpdated(this.summaries);

  @override
  List<Object?> get props => [summaries];
}

class ChangeContext extends DashboardEvent {
  final String context;

  const ChangeContext(this.context);

  @override
  List<Object?> get props => [context];
}

class DeleteDailyData extends DashboardEvent {
  final DateTime date;
  final String context;

  const DeleteDailyData(this.date, {this.context = 'hotel'});

  @override
  List<Object?> get props => [date, context];
}
