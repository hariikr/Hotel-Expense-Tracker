import 'package:flutter/widgets.dart';
import 'translations.dart';
import '../services/language_service.dart';

/// Extension to make translations easier to use in widgets
extension TranslationHelper on BuildContext {
  /// Get current language code
  String get lang => LanguageService.getLanguageCode();

  /// Translate a text map
  String translate(Map<String, String> translations) {
    return AppTranslations.get(translations, lang);
  }
}

/// Common translated strings as const maps for reuse
class T {
  // Common actions
  static const save = {'en': 'Save', 'ml': 'സംരക്ഷിക്കുക'};
  static const cancel = {'en': 'Cancel', 'ml': 'റദ്ദാക്കുക'};
  static const delete = {'en': 'Delete', 'ml': 'ഇല്ലാതാക്കുക'};
  static const edit = {'en': 'Edit', 'ml': 'തിരുത്തുക'};
  static const share = {'en': 'Share', 'ml': 'പങ്കിടുക'};
  static const confirm = {'en': 'Confirm', 'ml': 'സ്ഥിരീകരിക്കുക'};
  static const retry = {'en': 'Retry', 'ml': 'വീണ്ടും ശ്രമിക്കുക'};
  static const ok = {'en': 'OK', 'ml': 'ശരി'};
  static const yes = {'en': 'Yes', 'ml': 'അതെ'};
  static const no = {'en': 'No', 'ml': 'ഇല്ല'};

  // Navigation
  static const dashboard = {'en': 'Dashboard', 'ml': 'ഡാഷ്ബോർഡ്'};
  static const calendar = {'en': 'Calendar', 'ml': 'കലണ്ടർ'};
  static const analytics = {'en': 'Analytics', 'ml': 'വിശകലനം'};

  // Quick Actions
  static const quickActions = {
    'en': 'Quick Actions',
    'ml': 'പെട്ടെന്നുള്ള പ്രവർത്തനങ്ങൾ'
  };
  static const addIncome = {'en': 'Add Income', 'ml': 'വരുമാനം ചേർക്കുക'};
  static const addExpense = {'en': 'Add Expense', 'ml': 'ചെലവ് ചേർക്കുക'};
  static const viewReports = {
    'en': 'View Reports',
    'ml': 'റിപ്പോർട്ടുകൾ കാണുക'
  };
  static const settings = {'en': 'Settings', 'ml': 'ക്രമീകരണങ്ങൾ'};

  // Summary
  static const todaySummary = {
    'en': 'Today\'s Summary',
    'ml': 'ഇന്നത്തെ സംഗ്രഹം'
  };
  static const income = {'en': 'Income', 'ml': 'വരുമാനം'};
  static const expense = {'en': 'Expense', 'ml': 'ചെലവ്'};
  static const profit = {'en': 'Profit', 'ml': 'ലാഭം'};
  static const loss = {'en': 'Loss', 'ml': 'നഷ്ടം'};
  static const meals = {'en': 'Meals', 'ml': 'ഭക്ഷണം'};

  // Income
  static const onlineIncome = {'en': 'Online Income', 'ml': 'ഓൺലൈൻ വരുമാനം'};
  static const offlineIncome = {
    'en': 'Offline Income',
    'ml': 'ഓഫ്‌ലൈൻ വരുമാനം'
  };
  static const totalIncome = {'en': 'Total Income', 'ml': 'മൊത്തം വരുമാനം'};
  static const mealsCount = {'en': 'Meals Count', 'ml': 'ഭക്ഷണം എണ്ണം'};

  // Expense
  static const totalExpense = {'en': 'Total Expense', 'ml': 'മൊത്തം ചെലവ്'};
  static const expenseCategory = {
    'en': 'Expense Category',
    'ml': 'ചെലവിന്റെ തരം'
  };
  static const amount = {'en': 'Amount', 'ml': 'തുക'};
  static const description = {'en': 'Description', 'ml': 'വിവരണം'};

  // Calendar
  static const selectDate = {'en': 'Select Date', 'ml': 'തീയതി തിരഞ്ഞെടുക്കുക'};
  static const today = {'en': 'Today', 'ml': 'ഇന്ന്'};
  static const monthSummary = {'en': 'Month Summary', 'ml': 'മാസത്തെ സംഗ്രഹം'};

  // Analytics
  static const overview = {'en': 'Overview', 'ml': 'അവലോകനം'};
  static const trends = {'en': 'Trends', 'ml': 'പ്രവണതകൾ'};
  static const breakdown = {'en': 'Breakdown', 'ml': 'വിശദാംശങ്ങൾ'};
  static const week = {'en': 'Week', 'ml': 'ആഴ്ച'};
  static const month = {'en': 'Month', 'ml': 'മാസം'};
  static const quarter = {'en': 'Quarter', 'ml': 'പാദം'};
  static const year = {'en': 'Year', 'ml': 'വർഷം'};

  // Messages
  static const noData = {'en': 'No data available', 'ml': 'ഡാറ്റ ലഭ്യമല്ല'};
  static const noDataForDay = {
    'en': 'No data for this day',
    'ml': 'ഈ ദിവസത്തേക്ക് ഡാറ്റ ഇല്ല'
  };
  static const loading = {'en': 'Loading...', 'ml': 'ലോഡ് ചെയ്യുന്നു...'};
  static const error = {'en': 'Error', 'ml': 'പിശക്'};
  static const success = {'en': 'Success', 'ml': 'വിജയം'};
  static const savedSuccessfully = {
    'en': 'Saved successfully',
    'ml': 'വിജയകരമായി സംരക്ഷിച്ചു'
  };
  static const deletedSuccessfully = {
    'en': 'Deleted successfully',
    'ml': 'വിജയകരമായി ഇല്ലാതാക്കി'
  };

  // App specific
  static const hotelExpense = {'en': 'Hotel Expense', 'ml': 'ഹോട്ടൽ ചെലവ്'};
  static const calculator = {'en': 'Calculator', 'ml': 'കാൽക്കുലേറ്റർ'};
  static const undo = {'en': 'Undo', 'ml': 'പഴയപടിയാക്കുക'};
  static const undoLastEntry = {
    'en': 'Undo Last Entry',
    'ml': 'അവസാന എൻട്രി പഴയപടിയാക്കുക'
  };
  static const entryRemoved = {
    'en': 'Entry removed successfully',
    'ml': 'എൻട്രി വിജയകരമായി നീക്കം ചെയ്തു'
  };

  // Filter
  static const all = {'en': 'All', 'ml': 'എല്ലാം'};
  static const profitDays = {'en': 'Profit Days', 'ml': 'ലാഭ ദിവസങ്ങൾ'};
  static const lossDays = {'en': 'Loss Days', 'ml': 'നഷ്ട ദിവസങ്ങൾ'};
  static const highIncome = {'en': 'High Income', 'ml': 'ഉയർന്ന വരുമാനം'};
  static const highExpense = {'en': 'High Expense', 'ml': 'ഉയർന്ന ചെലവ്'};

  // Status
  static const profitableDay = {'en': 'Profitable Day', 'ml': 'ലാഭകരമായ ദിവസം'};
  static const lossDay = {'en': 'Loss Day', 'ml': 'നഷ്ട ദിവസം'};
  static const netProfit = {'en': 'Net Profit', 'ml': 'മൊത്തം ലാഭം'};
  static const netLoss = {'en': 'Net Loss', 'ml': 'മൊത്തം നഷ്ടം'};
  static const successRate = {'en': 'Success Rate', 'ml': 'വിജയ നിരക്ക്'};
  static const profitableDays = {
    'en': 'Profitable Days',
    'ml': 'ലാഭകരമായ ദിവസങ്ങൾ'
  };

  // Actions
  static const editIncome = {'en': 'Edit Income', 'ml': 'വരുമാനം തിരുത്തുക'};
  static const editExpense = {'en': 'Edit Expense', 'ml': 'ചെലവ് തിരുത്തുക'};
  static const addIncomeForDay = {
    'en': 'Add Income for This Day',
    'ml': 'ഈ ദിവസത്തേക്ക് വരുമാനം ചേർക്കുക'
  };
  static const viewingPeriod = {
    'en': 'Viewing Period',
    'ml': 'കാണുന്ന കാലയളവ്'
  };

  // Expense Categories
  static const vegetables = {'en': 'Vegetables', 'ml': 'പച്ചക്കറി'};
  static const rice = {'en': 'Rice', 'ml': 'അരി'};
  static const fish = {'en': 'Fish', 'ml': 'മീൻ'};
  static const meat = {'en': 'Meat', 'ml': 'ഇറച്ചി'};
  static const dairy = {'en': 'Dairy', 'ml': 'പാൽ ഉൽപ്പന്നങ്ങൾ'};
  static const oil = {'en': 'Oil', 'ml': 'എണ്ണ'};
  static const groceries = {'en': 'Groceries', 'ml': 'സാധനസാമഗ്രികൾ'};
  static const salary = {'en': 'Salary', 'ml': 'ശമ്പളം'};
  static const electricity = {'en': 'Electricity', 'ml': 'വൈദ്യുതി'};
  static const other = {'en': 'Other', 'ml': 'മറ്റുള്ളവ'};

  // Smart Insights
  static const smartInsights = {
    'en': 'Smart Insights',
    'ml': 'സ്മാർട്ട് സൂചനകൾ'
  };
  static const bestProfitDay = {
    'en': 'Best Profit Day',
    'ml': 'മികച്ച ലാഭ ദിവസം'
  };
  static const avgDailyProfit = {
    'en': 'Avg Daily Profit',
    'ml': 'ശരാശരി ദിനംതോറും ലാഭം'
  };
  static const avgDailyIncome = {
    'en': 'Avg Daily Income',
    'ml': 'ശരാശരി ദിനംതോറും വരുമാനം'
  };
  static const avgDailyExpense = {
    'en': 'Avg Daily Expense',
    'ml': 'ശരാശരി ദിനംതോറും ചെലവ്'
  };
  static const avgMealsPerDay = {
    'en': 'Average Meals/Day',
    'ml': 'ശരാശരി ഭക്ഷണം/ദിവസം'
  };
  static const performanceIndicators = {
    'en': 'Performance Indicators',
    'ml': 'പ്രകടന സൂചകങ്ങൾ'
  };
  static const thisWeek = {'en': 'This Week', 'ml': 'ഈ ആഴ്ച'};
  static const thisMonth = {'en': 'This Month', 'ml': 'ഈ മാസം'};
  static const comparedToLastWeek = {
    'en': 'Compared to last week',
    'ml': 'കഴിഞ്ഞ ആഴ്ചയുമായി താരതമ്യം'
  };
  static const comparedToLastMonth = {
    'en': 'Compared to last month',
    'ml': 'കഴിഞ്ഞ മാസവുമായി താരതമ്യം'
  };
  static const higher = {'en': 'Higher', 'ml': 'ഉയർന്നത്'};
  static const lower = {'en': 'Lower', 'ml': 'താഴ്ന്നത്'};
  static const improving = {'en': 'Improving', 'ml': 'മെച്ചപ്പെടുന്നു'};
  static const declining = {'en': 'Declining', 'ml': 'കുറയുന്നു'};

  // Additional Smart Insights translations
  static const comparedToYesterday = {
    'en': 'Compared to Yesterday',
    'ml': 'ഇന്നലെയുമായി താരതമ്യം'
  };
  static const weeklyPerformance = {
    'en': 'Weekly Performance',
    'ml': 'ആഴ്ചയുടെ പ്രകടനം'
  };
  static const highestExpense = {
    'en': 'Highest Expense',
    'ml': 'ഏറ്റവും ഉയർന്ന ചെലവ്'
  };
  static const profitStreak = {'en': 'Profit Streak', 'ml': 'ലാഭ പരമ്പര'};
  static const monthlyProjection = {
    'en': 'Monthly Projection',
    'ml': 'മാസത്തെ പ്രവചനം'
  };
  static const day = {'en': 'day', 'ml': 'ദിവസം'};
  static const days = {'en': 'days', 'ml': 'ദിവസങ്ങൾ'};
  static const ofProfit = {
    'en': 'of profit! Keep it up!',
    'ml': 'ലാഭം! ഇതുപോലെ തുടരൂ!'
  };
  static const profitIncreased = {
    'en': 'Profit increased by',
    'ml': 'ലാഭം വർദ്ധിച്ചത്'
  };
  static const profitDecreased = {
    'en': 'Profit decreased by',
    'ml': 'ലാഭം കുറഞ്ഞത്'
  };
  static const sameAsYesterday = {
    'en': 'Same as yesterday',
    'ml': 'ഇന്നലെ പോലെ തന്നെ'
  };
  static const basedOnTrend = {
    'en': 'Based on current trend, expect',
    'ml': 'നിലവിലെ പ്രവണതയെ അടിസ്ഥാനമാക്കി, പ്രതീക്ഷിക്കുന്നത്'
  };
  static const improveDailyProfit = {
    'en': 'Improve daily profit to turn monthly profit positive',
    'ml': 'മാസിക ലാഭം പോസിറ്റീവ് ആക്കാൻ ദിനംതോറും ലാഭം മെച്ചപ്പെടുത്തുക'
  };
  static const mealsServed = {'en': 'meals served', 'ml': 'ഭക്ഷണം നൽകി'};

  // Notification translations
  static const dailyEntryReminder = {
    'en': 'Daily Entry Reminder',
    'ml': 'ദിനംതോറും എൻട്രി ഓർമ്മപ്പെടുത്തൽ'
  };
  static const dontForgetLog = {
    'en': 'Don\'t forget to log today\'s income and expenses!',
    'ml': 'ഇന്നത്തെ വരുമാനവും ചെലവും രേഖപ്പെടുത്താൻ മറക്കരുത്!'
  };
  static const weeklyPerformanceSummary = {
    'en': 'Weekly Performance Summary',
    'ml': 'ആഴ്ചതോറും പ്രകടന സംഗ്രഹം'
  };
  static const tapToSeeWeeklyReport = {
    'en': 'Tap to see this week\'s performance report',
    'ml': 'ഈ ആഴ്ചയുടെ പ്രകടന റിപ്പോർട്ട് കാണാൻ ടാപ്പ് ചെയ്യുക'
  };
  static const lowProfitAlert = {
    'en': 'Low Profit Alert',
    'ml': 'കുറഞ്ഞ ലാഭ മുന്നറിയിപ്പ്'
  };
  static const profitBelowThreshold = {
    'en': 'Today\'s profit is below your threshold',
    'ml': 'ഇന്നത്തെ ലാഭം നിങ്ങളുടെ പരിധിക്ക് താഴെയാണ്'
  };
  static const amazingStreak = {
    'en': 'Amazing! 7-Day Streak!',
    'ml': 'അതിശയകരം! 7 ദിവസത്തെ പരമ്പര!'
  };
  static const incredibleStreak = {
    'en': 'Incredible! 10-Day Streak!',
    'ml': 'അവിശ്വസനീയം! 10 ദിവസത്തെ പരമ്പര!'
  };
  static const legendaryStreak = {
    'en': 'Legendary! 30-Day Streak!',
    'ml': 'ഐതിഹാസികം! 30 ദിവസത്തെ പരമ്പര!'
  };
  static const consecutiveProfitDays = {
    'en': 'consecutive days of profit! Excellent work!',
    'ml': 'തുടർച്ചയായ ദിവസങ്ങൾ ലാഭം! മികച്ച പ്രവർത്തനം!'
  };
  static const weeklyPerformanceNotif = {
    'en': 'Weekly Performance',
    'ml': 'ആഴ്ചതോറും പ്രകടനം'
  };
  static const profitDaysCount = {'en': 'Profit Days', 'ml': 'ലാഭ ദിവസങ്ങൾ'};
  static const missingEntry = {
    'en': 'Missing Entry',
    'ml': 'എൻട്രി നഷ്ടപ്പെട്ടു'
  };
  static const notLoggedToday = {
    'en': 'You haven\'t logged today\'s income and expenses yet!',
    'ml': 'നിങ്ങൾ ഇന്നത്തെ വരുമാനവും ചെലവും ഇതുവരെ രേഖപ്പെടുത്തിയിട്ടില്ല!'
  };

  // Helper to get translation
  static String get(Map<String, String> map, String lang) {
    return AppTranslations.get(map, lang);
  }
}
