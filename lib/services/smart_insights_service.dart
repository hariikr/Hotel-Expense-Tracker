import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

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

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'message': message,
      'icon': icon,
    };
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

  Map<String, dynamic> toMap() {
    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'profit': profit,
      'profitMargin': profitMargin,
      'profitableDays': profitableDays,
      'totalDays': totalDays,
    };
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
              ?.map((i) => SmartInsight.fromJson(Map<String, dynamic>.from(i)))
              .toList() ??
          [],
      summary: json['summary'] != null
          ? InsightsSummary.fromJson(Map<String, dynamic>.from(json['summary']))
          : null,
      period: json['period'] ?? 'week',
      startDate: json['startDate'],
      endDate: json['endDate'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'insights': insights.map((i) => i.toMap()).toList(),
      'summary': summary?.toMap(),
      'period': period,
      'startDate': startDate,
      'endDate': endDate,
      'error': error,
    };
  }

  String toJson() => jsonEncode(toMap());
}

class SmartInsightsService {
  final _supabase = Supabase.instance.client;

  static const String _cachePrefix = 'smart_insights_';
  static const String _cacheDatePrefix = 'smart_insights_date_';

  /// Get smart AI-powered business insights for the dashboard
  ///
  /// [period] can be: 'today', 'week', 'month'
  /// Returns SmartInsightsResponse with AI-generated insights
  Future<SmartInsightsResponse> getSmartInsights({
    String? userId,
    String period = 'week',
  }) async {
    try {
      final effectiveUserId = userId ?? _supabase.auth.currentUser?.id;
      if (effectiveUserId == null) throw Exception('User not identified');

      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final cacheKey = '${_cachePrefix}${effectiveUserId}_$period';
      final cacheDateKey = '${_cacheDatePrefix}${effectiveUserId}_$period';

      // 1. Check Cache
      final cachedDate = prefs.getString(cacheDateKey);
      final cachedData = prefs.getString(cacheKey);

      if (cachedDate == todayStr && cachedData != null) {
        print('📊 Returning cached smart insights for $period ($todayStr)');
        try {
          final decoded = jsonDecode(cachedData);
          return SmartInsightsResponse.fromJson(Map<String, dynamic>.from(decoded));
        } catch (e) {
          print('⚠️ Error decoding cached insights: $e');
          // Proceed to fetch fresh data if cache is corrupt
        }
      }

      // 2. Fetch Fresh Data (One time per day)
      print('📊 Fetching fresh smart insights for period: $period');

      final response = await _supabase.functions.invoke(
        'smart-insights',
        body: {
          'userId': effectiveUserId,
          'period': period,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to get insights: ${response.status}');
      }

      final data = response.data;
      if (data == null || data is! Map<String, dynamic>) {
        throw Exception('Invalid response format from edge function');
      }

      if (data.containsKey('error') && data['error'] != null) {
        throw Exception(data['details'] ?? data['error']);
      }

      final insightsResponse = SmartInsightsResponse.fromJson(data);

      // 3. Update Cache
      await prefs.setString(cacheKey, insightsResponse.toJson());
      await prefs.setString(cacheDateKey, todayStr);

      return insightsResponse;
    } catch (e) {
      print('❌ Error fetching smart insights: $e');
      
      // Fallback logic remains the same...
      String errorMessage = _getErrorMessage(e.toString());

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
        error: e.toString(),
      );
    }
  }

  String _getErrorMessage(String errorDetails) {
    if (errorDetails.contains('not deployed')) {
      return 'Smart insights feature അപ്‌ഡേറ്റ് ചെയ്യുന്നു. ദയവായി കുറച്ച് സമയം കഴിഞ്ഞ് വീണ്ടും ശ്രമിക്കൂ.';
    } else if (errorDetails.contains('Database functions not found')) {
      return 'Database അപ്‌ഡേറ്റ് ആവശ്യമാണ്. Admin നെ ബന്ധപ്പെടൂ.';
    } else if (errorDetails.contains('GEMINI_API_KEY') ||
        errorDetails.contains('Gemini API')) {
      return 'AI service temporarily unavailable. കുറച്ച് സമയം കഴിഞ്ഞ് ശ്രമിക്കൂ.';
    } else if (errorDetails.contains('No data')) {
      return 'ഈ കാലയളവിൽ ഡാറ്റ ലഭ്യമല്ല. ചെലവുകളും വരുമാനവും ചേർക്കൂ.';
    } else {
      return 'ഇപ്പോൾ insights ലോഡ് ചെയ്യാൻ കഴിഞ്ഞില്ല. കുറച്ച് സമയം കഴിഞ്ഞ് വീണ്ടും ശ്രമിക്കൂ.';
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
