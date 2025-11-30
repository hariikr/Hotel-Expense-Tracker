import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class SmartInsight {
  final String type; // profit, expense, income, trend, warning, suggestion
  final String title;
  final String message;
  final String icon;

  SmartInsight({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
  });

  factory SmartInsight.fromJson(Map<String, dynamic> json) {
    return SmartInsight(
      type: json['type'] ?? 'summary',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      icon: json['icon'] ?? '📊',
    );
  }
}

class InsightsSummary {
  final double totalIncome;
  final double totalExpense;
  final double profit;
  final double profitMargin;
  final int profitableDays;
  final int totalDays;

  InsightsSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.profit,
    required this.profitMargin,
    required this.profitableDays,
    required this.totalDays,
  });

  factory InsightsSummary.fromJson(Map<String, dynamic> json) {
    return InsightsSummary(
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      totalExpense: (json['totalExpense'] ?? 0).toDouble(),
      profit: (json['profit'] ?? 0).toDouble(),
      profitMargin: (json['profitMargin'] ?? 0).toDouble(),
      profitableDays: json['profitableDays'] ?? 0,
      totalDays: json['totalDays'] ?? 0,
    );
  }
}

class SmartInsightsResponse {
  final List<SmartInsight> insights;
  final InsightsSummary? summary;
  final String period;
  final String? startDate;
  final String? endDate;
  final String? error;

  SmartInsightsResponse({
    required this.insights,
    this.summary,
    required this.period,
    this.startDate,
    this.endDate,
    this.error,
  });

  factory SmartInsightsResponse.fromJson(Map<String, dynamic> json) {
    return SmartInsightsResponse(
      insights: (json['insights'] as List?)
              ?.map((i) => SmartInsight.fromJson(i))
              .toList() ??
          [],
      summary: json['summary'] != null
          ? InsightsSummary.fromJson(json['summary'])
          : null,
      period: json['period'] ?? 'week',
      startDate: json['startDate'],
      endDate: json['endDate'],
      error: json['error'],
    );
  }
}

class SmartInsightsService {
  final _supabase = Supabase.instance.client;

  /// Get smart AI-powered business insights for the dashboard
  ///
  /// [period] can be: 'today', 'week', 'month'
  /// Returns SmartInsightsResponse with AI-generated insights
  Future<SmartInsightsResponse> getSmartInsights({
    String? userId,
    String period = 'week',
  }) async {
    try {
      print('📊 Fetching smart insights for period: $period');

      final response = await _supabase.functions.invoke(
        'smart-insights',
        body: {
          'userId': userId,
          'period': period,
        },
      );

      print('📊 Smart insights response status: ${response.status}');
      print('📊 Smart insights response data: ${response.data}');

      // Check for error responses
      if (response.status == 404) {
        throw Exception(
            'Edge function not deployed. Run: supabase functions deploy smart-insights');
      }

      if (response.status != 200) {
        throw Exception('Failed to get insights: ${response.status}');
      }

      final data = response.data;

      // Handle null or empty data
      if (data == null) {
        throw Exception('No data returned from edge function');
      }

      // Check if data is a Map
      if (data is! Map<String, dynamic>) {
        print('⚠️ Unexpected data type: ${data.runtimeType}');
        throw Exception('Invalid response format');
      }

      // Check if there's an error in the response
      if (data.containsKey('error') && data['error'] != null) {
        final errorDetails = data['details'] ?? data['error'];
        print('❌ Edge function returned error: $errorDetails');
        throw Exception(errorDetails);
      }

      return SmartInsightsResponse.fromJson(data);
    } catch (e, stackTrace) {
      print('❌ Error fetching smart insights: $e');
      print('Stack trace: $stackTrace');

      // Determine error message
      String errorMessage;
      String errorDetails = e.toString();

      if (errorDetails.contains('not deployed')) {
        errorMessage =
            'Smart insights feature അപ്‌ഡേറ്റ് ചെയ്യുന്നു. ദയവായി കുറച്ച് സമയം കഴിഞ്ഞ് വീണ്ടും ശ്രമിക്കൂ.';
      } else if (errorDetails.contains('Database functions not found')) {
        errorMessage = 'Database അപ്‌ഡേറ്റ് ആവശ്യമാണ്. Admin നെ ബന്ധപ്പെടൂ.';
      } else if (errorDetails.contains('GEMINI_API_KEY') ||
          errorDetails.contains('Gemini API')) {
        errorMessage =
            'AI service temporarily unavailable. കുറച്ച് സമയം കഴിഞ്ഞ് ശ്രമിക്കൂ.';
      } else if (errorDetails.contains('No data')) {
        errorMessage =
            'ഈ കാലയളവിൽ ഡാറ്റ ലഭ്യമല്ല. ചെലവുകളും വരുമാനവും ചേർക്കൂ.';
      } else {
        errorMessage =
            'ഇപ്പോൾ insights ലോഡ് ചെയ്യാൻ കഴിഞ്ഞില്ല. കുറച്ച് സമയം കഴിഞ്ഞ് വീണ്ടും ശ്രമിക്കൂ.';
      }

      // Return fallback insights on error
      return SmartInsightsResponse(
        insights: [
          SmartInsight(
            type: 'error',
            title: 'Insights ലഭ്യമല്ല',
            message: errorMessage,
            icon: '⚠️',
          ),
        ],
        summary: null,
        period: period,
        error: errorDetails,
      );
    }
  }

  /// Get insights for today
  Future<SmartInsightsResponse> getTodayInsights({String? userId}) {
    return getSmartInsights(userId: userId, period: 'today');
  }

  /// Get insights for the week
  Future<SmartInsightsResponse> getWeekInsights({String? userId}) {
    return getSmartInsights(userId: userId, period: 'week');
  }

  /// Get insights for the month
  Future<SmartInsightsResponse> getMonthInsights({String? userId}) {
    return getSmartInsights(userId: userId, period: 'month');
  }
}
