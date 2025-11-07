import 'package:equatable/equatable.dart';
import '../../models/daily_summary.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final List<DailySummary> allSummaries;
  final DailySummary? bestProfitDay;
  final Map<String, double>? weeklySummary;
  final Map<String, double>? monthlySummary;
  final double totalIncome;
  final double totalExpense;
  final double totalProfit;

  const DashboardLoaded({
    required this.allSummaries,
    this.bestProfitDay,
    this.weeklySummary,
    this.monthlySummary,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalProfit,
  });

  DashboardLoaded copyWith({
    List<DailySummary>? allSummaries,
    DailySummary? bestProfitDay,
    Map<String, double>? weeklySummary,
    Map<String, double>? monthlySummary,
    double? totalIncome,
    double? totalExpense,
    double? totalProfit,
  }) {
    return DashboardLoaded(
      allSummaries: allSummaries ?? this.allSummaries,
      bestProfitDay: bestProfitDay ?? this.bestProfitDay,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      monthlySummary: monthlySummary ?? this.monthlySummary,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      totalProfit: totalProfit ?? this.totalProfit,
    );
  }

  @override
  List<Object?> get props => [
        allSummaries,
        bestProfitDay,
        weeklySummary,
        monthlySummary,
        totalIncome,
        totalExpense,
        totalProfit,
      ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
