# AI Chat Edge Function Setup

## Prerequisites

1. **Google Gemini API Key**
   - Get your free API key from: https://makersuite.google.com/app/apikey
   - Gemini has generous free tier limits

## Deployment Steps

### 1. Set Environment Variables

You need to set the Gemini API key as a secret in your Supabase project:

```bash
# Using Supabase CLI
supabase secrets set GEMINI_API_KEY=your_gemini_api_key_here
```

Or set it in the Supabase Dashboard:
- Go to your project settings
- Navigate to Edge Functions
- Add secret: `GEMINI_API_KEY` with your key

### 2. Deploy the Edge Function

```bash
# Make sure you're in the project root
supabase functions deploy ai-chat
```

### 3. Test the Function

```bash
# Test with curl
curl -X POST 'https://your-project.supabase.co/functions/v1/ai-chat' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "message": "How much profit did I make today?",
    "userId": null
  }'
```

## Available Tools

The AI assistant can call these database functions:

1. **get_daily_summary** - Get data for a specific date
2. **get_range_summary** - Get aggregated data for a date range
3. **get_category_total** - Get total for a specific expense category
4. **get_recent_transactions** - Get recent transaction history
5. **get_top_expense_categories** - Get top spending categories
6. **get_income_breakdown** - Get online vs offline income breakdown
7. **compare_periods** - Compare two date ranges

## Language Support

The AI automatically detects Malayalam and English and responds in the same language.

## Error Handling

- Returns bilingual error messages
- Saves successful chats to `chat_messages` table
- Validates all inputs
- Handles tool execution errors gracefully
