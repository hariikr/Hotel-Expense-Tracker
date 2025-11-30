# AI Assistant Setup Guide

This guide will walk you through setting up the AI Assistant feature for your Hotel Expense Tracker app.

## 📋 Prerequisites

1. **Supabase Project** - You should already have this set up
2. **Supabase CLI** installed - [Install Guide](https://supabase.com/docs/guides/cli)
3. **Google Gemini API Key** - Free tier available

## 🔑 Step 1: Get Gemini API Key

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the API key (you'll need it in the next step)

## 🗄️ Step 2: Apply Database Migration

The migration file `005_ai_chat_setup.sql` has been created in `supabase/migrations/`. It includes:
- `chat_messages` table for storing chat history
- Multiple helper functions for querying financial data
- Row Level Security policies

**Apply the migration:**

```bash
# Navigate to your project directory
cd "C:\Users\harik\Desktop\Hotel Expense Tracker"

# Login to Supabase (if not already logged in)
supabase login

# Link to your project (if not already linked)
supabase link --project-ref your-project-ref

# Apply the migration
supabase db push
```

Or manually run the SQL in Supabase Dashboard:
1. Go to your Supabase Dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `supabase/migrations/005_ai_chat_setup.sql`
4. Click "Run"

## ☁️ Step 3: Deploy Edge Function

### Set Environment Variable

First, set your Gemini API key as a secret:

```bash
# Set the secret
supabase secrets set GEMINI_API_KEY=your_gemini_api_key_here
```

Or in Supabase Dashboard:
1. Go to Project Settings → Edge Functions
2. Add a new secret:
   - Name: `GEMINI_API_KEY`
   - Value: Your Gemini API key

### Deploy the Function

```bash
# Deploy the ai-chat function
supabase functions deploy ai-chat
```

### Verify Deployment

Test the function with curl:

```bash
curl -X POST 'https://your-project-ref.supabase.co/functions/v1/ai-chat' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"message": "How much profit did I make today?", "userId": null}'
```

## 📱 Step 4: Flutter App Setup

The Flutter code has already been created:

### Files Created:
1. **Service**: `lib/services/ai_service.dart` - Handles communication with Edge Function
2. **Screen**: `lib/screens/ai/ai_chat_screen.dart` - Professional chat UI
3. **Navigation**: Updated `lib/screens/main_navigation.dart` - Added AI tab
4. **Translations**: Updated `lib/utils/translations.dart` - Added AI-related translations

### No Additional Dependencies Needed

All required packages are already in your `pubspec.yaml`:
- `supabase_flutter` - For Edge Function calls
- Other existing dependencies

## 🧪 Step 5: Test the Feature

1. **Run the app**:
   ```bash
   flutter run
   ```

2. **Navigate to AI tab** - Click the AI icon in the bottom navigation

3. **Try these questions**:

   **English:**
   - "How much profit did I make today?"
   - "Show me this week's expenses"
   - "What's my top expense category?"
   - "Compare this month with last month"

   **Malayalam:**
   - "ഇന്നത്തെ ലാഭം എത്ര?"
   - "ഈ ആഴ്ചയിലെ ചെലവ് കാണിക്കൂ"
   - "ഏറ്റവും കൂടുതൽ ചെലവ് ഏത് കാറ്റഗറിയിൽ?"
   - "ഈ മാസവും കഴിഞ്ഞ മാസവും താരതമ്യംചെയ്യൂ"

## 🎯 Features Included

### Database Functions (Available to AI)

1. **get_daily_data** - Get complete summary for a specific date
2. **get_range_data** - Get aggregated summary for a date range
3. **get_category_total** - Get total for specific expense categories
4. **get_top_expense_categories** - Get top spending categories
5. **get_income_breakdown** - Get online vs offline income breakdown
6. **get_recent_transactions** - Get recent transaction history
7. **compare_date_ranges** - Compare two periods

### AI Capabilities

- ✅ Automatic language detection (Malayalam/English)
- ✅ Responds in the same language as user's question
- ✅ Function calling to fetch real data from database
- ✅ Natural language understanding
- ✅ Context-aware responses
- ✅ Error handling in both languages

### UI Features

- ✅ WhatsApp-style chat interface
- ✅ Message history persistence
- ✅ Typing indicator
- ✅ Suggested questions
- ✅ Clear chat history option
- ✅ Beautiful material design
- ✅ Bilingual support

## 🔧 Troubleshooting

### Edge Function Not Working

1. Check if the function is deployed:
   ```bash
   supabase functions list
   ```

2. Check function logs:
   ```bash
   supabase functions logs ai-chat
   ```

3. Verify the API key is set:
   ```bash
   supabase secrets list
   ```

### Database Errors

1. Verify migration was applied:
   ```sql
   SELECT * FROM chat_messages LIMIT 1;
   ```

2. Check if functions exist:
   ```sql
   SELECT proname FROM pg_proc WHERE proname LIKE 'get_%';
   ```

### Flutter Errors

1. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. Check console for errors and verify Supabase URL/keys in `lib/utils/constants.dart`

## 💡 Usage Tips

### For Your Mother

The AI is designed to be simple and conversational. She can ask questions naturally:

**Good questions:**
- "Yesterday income?"
- "This week profit?"
- "Where did I spend the most?"
- "How is this month compared to last month?"

**Malayalam equivalent:**
- "ഇന്നലത്തെ വരുമാനം?"
- "ഈ ആഴ്ചയുടെ ലാഭം?"
- "ഏറ്റവും കൂടുതൽ എവിടെയാണ് ചെലവഴിച്ചത്?"
- "ഈ മാസം കഴിഞ്ഞ മാസവുമായി താരതമ്യപ്പെടുത്തുമ്പോൾ എങ്ങനെയുണ്ട്?"

### Advanced Queries

The AI can handle complex questions:
- Date-specific queries: "What was my profit on January 15th?"
- Category analysis: "How much did I spend on fish this month?"
- Comparisons: "Compare income between January and February"
- Trends: "Show me the last 10 days"

## 🚀 Next Steps

### Optional Enhancements

1. **Voice Input** - Use `speech_to_text` package (already in your pubspec)
2. **Export Chats** - Add option to export chat history
3. **Scheduled Reports** - AI can send daily/weekly summaries
4. **Insights & Recommendations** - AI suggests ways to reduce expenses

## 📊 Cost Estimation

### Gemini API (Free Tier)
- 60 requests per minute
- 1,500 requests per day
- Sufficient for personal use

### Supabase Edge Functions (Free Tier)
- 500K invocations per month
- 2GB bandwidth
- More than enough for this use case

## 🆘 Support

If you encounter any issues:

1. Check the Edge Function logs
2. Verify database migrations are applied
3. Ensure API keys are correctly set
4. Test with simple queries first

## 📝 License

Part of Hotel Expense Tracker project.
