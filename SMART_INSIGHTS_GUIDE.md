# Smart Insights Integration Guide

## Overview
AI-powered business insights using Gemini API to analyze real financial data and provide actionable Malayalam insights.

## Files Created

### 1. Edge Function: `supabase/functions/smart-insights/index.ts`
- Fetches real financial data from database
- Analyzes trends, income, expenses
- Calls Gemini API with structured prompt
- Returns 4-6 AI-generated insights in Malayalam

### 2. Service: `lib/services/smart_insights_service.dart`
- `SmartInsight` model (type, title, message, icon)
- `InsightsSummary` model (totals, margins, profitable days)
- `SmartInsightsService` class with methods:
  - `getSmartInsights(period)` - Get insights for any period
  - `getTodayInsights()` - Today's insights
  - `getWeekInsights()` - Weekly insights
  - `getMonthInsights()` - Monthly insights

### 3. Widget: Ready to integrate (see below)

## Integration Steps

### Step 1: Deploy Edge Function
```bash
cd "c:\Users\harik\Desktop\Hotel Expense Tracker"
supabase functions deploy smart-insights
```

### Step 2: Add Smart Insights to Dashboard

Update `lib/screens/dashboard_screen.dart`:

```dart
import '../widgets/ai_smart_insights_widget.dart'; // Use AI version

// In the body, add the widget:
body: SingleChildScrollView(
  child: Column(
    children: [
      // Existing widgets...
      
      // Add AI Smart Insights
      AiSmartInsightsWidget(
        period: 'week', // or 'today' or 'month'
      ),
      
      // Rest of widgets...
    ],
  ),
),
```

### Step 3: Add Period Selector (Optional)

```dart
String _insightsPeriod = 'week';

// Add dropdown to switch periods
DropdownButton<String>(
  value: _insightsPeriod,
  items: [
    DropdownMenuItem(value: 'today', child: Text('ഇന്ന്')),
    DropdownMenuItem(value: 'week', child: Text('ഈ ആഴ്ച')),
    DropdownMenuItem(value: 'month', child: Text('ഈ മാസം')),
  ],
  onChanged: (value) {
    setState(() => _insightsPeriod = value!);
  },
),

// Use in widget
AiSmartInsightsWidget(period: _insightsPeriod),
```

## Features

### AI-Generated Insights
Gemini analyzes:
- Profit trends and margins
- Top expense categories
- Income breakdown (online vs offline)
- Day-by-day performance
- Profitable days count

### Insight Types
1. **Profit**: Revenue and profit analysis
2. **Expense**: Cost optimization suggestions
3. **Income**: Revenue stream analysis
4. **Trend**: Performance trends
5. **Warning**: Issues to address
6. **Suggestion**: Actionable recommendations

### Example Insights
```json
{
  "type": "profit",
  "title": "നല്ല ലാഭം വരുന്നുണ്ട്!",
  "message": "ഈ ആഴ്ച ₹15,450 ലാഭം! കഴിഞ്ഞ ആഴ്ചയേക്കാൾ 12% കൂടുതൽ. തുടർന്നും ഇതേ രീതിയിൽ!",
  "icon": "💰"
}
```

## API Response Format

```json
{
  "insights": [
    {
      "type": "profit|expense|income|trend|warning|suggestion",
      "title": "Malayalam title",
      "message": "Detailed message with numbers",
      "icon": "emoji"
    }
  ],
  "summary": {
    "totalIncome": 45000,
    "totalExpense": 30000,
    "profit": 15000,
    "profitMargin": 33.3,
    "profitableDays": 6,
    "totalDays": 7
  },
  "period": "week",
  "startDate": "2025-11-23",
  "endDate": "2025-11-30"
}
```

## Error Handling

The service provides fallback insights if:
- Gemini API fails
- No data available
- Network issues

Fallback insight:
```dart
SmartInsight(
  type: 'error',
  title: 'ഡാറ്റ ലഭ്യമല്ല',
  message: 'കുറച്ച് സമയം കഴിഞ്ഞ് വീണ്ടും ശ്രമിക്കൂ.',
  icon: '⚠️',
)
```

## Testing

1. **Test Edge Function:**
```bash
curl -X POST https://your-project.supabase.co/functions/v1/smart-insights \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"period": "week"}'
```

2. **Check Logs:**
```bash
supabase functions logs smart-insights --follow
```

3. **Test in App:**
- Navigate to dashboard
- Widget should load with AI insights
- Try different periods (today/week/month)
- Tap refresh icon to regenerate

## Customization

### Change Insight Count
In `smart-insights/index.ts`:
```typescript
// Change from 4-6 to any number
TASK: Generate exactly 3 smart business insights...
```

### Change Language
Replace Malayalam prompts with English/Tamil in the prompt.

### Add More Data
Add more data sources in the edge function:
```typescript
const { data: newData } = await supabase.rpc('your_function');
// Add to prompt
```

## Benefits

✅ Real-time AI analysis of actual business data
✅ Actionable insights in Malayalam
✅ Automatic trend detection
✅ Cost optimization suggestions
✅ Revenue growth recommendations
✅ Encouraging, supportive tone
✅ Updates automatically with refresh

## Next Steps

1. Deploy the edge function
2. Integrate widget into dashboard
3. Test with real data
4. Customize insights based on feedback
