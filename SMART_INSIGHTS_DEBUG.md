# Smart Insights Debugging Guide

## Current Issue
Edge function is returning 500 error: "Unknown error"

## Updated Files
1. ✅ `supabase/functions/smart-insights/index.ts` - Added detailed error messages
2. ✅ `lib/services/smart_insights_service.dart` - Better error handling and messages

## Steps to Fix

### 1. Deploy Updated Edge Function
```bash
# In your terminal (not PowerShell, use Command Prompt or Git Bash)
cd "c:\Users\harik\Desktop\Hotel Expense Tracker"
supabase functions deploy smart-insights
```

### 2. Check Edge Function Logs
```bash
# View recent logs
supabase functions logs smart-insights --limit 20

# Or follow logs in real-time
supabase functions logs smart-insights --follow
```

### 3. Verify Secrets Are Set
Go to Supabase Dashboard → Project Settings → Edge Functions → Secrets

Required secrets:
- ✅ `GEMINI_API_KEY` - Your Gemini API key
- ✅ `SUPABASE_URL` - Auto-set
- ✅ `SUPABASE_SERVICE_ROLE_KEY` - Auto-set

### 4. Check Database Functions Exist
Run this in Supabase SQL Editor:

```sql
-- Check if all required functions exist
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_type = 'FUNCTION' 
  AND routine_schema = 'public'
  AND routine_name IN (
    'get_range_data',
    'get_top_expense_categories',
    'get_income_breakdown',
    'get_recent_transactions'
  );
```

Expected result: All 4 functions should be listed.

If missing, run migration:
```bash
supabase db reset
# or
supabase migration up
```

### 5. Test Edge Function Manually
```bash
# Test with curl
curl -X POST https://your-project-ref.supabase.co/functions/v1/smart-insights \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"period": "today"}'
```

### 6. Test in App
After deploying, hot reload the app:
```
# In terminal where Flutter is running
r (hot reload)

# Or restart
R (hot restart)
```

## What the Improved Error Handling Does

### Edge Function Now Shows:
- ❌ "Database functions not found" → Run migrations
- ❌ "Gemini API key not configured" → Add secret
- ❌ "Gemini API error" → Check API key and quota
- ❌ Actual error message for debugging

### Flutter App Now Shows:
- ⚠️ "Database അപ്‌ഡേറ്റ് ആവശ്യമാണ്" → Database issue
- ⚠️ "AI service temporarily unavailable" → Gemini issue
- ⚠️ "ഡാറ്റ ലഭ്യമല്ല" → No data for period
- ⚠️ Generic error with fallback insight

## Likely Causes (in order of probability)

### 1. Database Functions Not Found (Most Likely)
**Symptom:** Edge function can't call RPCs
**Solution:** 
```bash
supabase db reset
# or apply specific migration
supabase migration up 005_ai_chat_setup.sql
```

### 2. Gemini API Key Missing
**Symptom:** API calls fail
**Solution:** 
- Go to Supabase Dashboard → Edge Functions → Secrets
- Add `GEMINI_API_KEY` with your API key

### 3. No Data in Database
**Symptom:** Queries return null
**Solution:**
- Add some income/expense entries for today
- Or try different period (week/month)

### 4. Migration Not Applied
**Symptom:** Tables/functions don't exist
**Solution:**
```bash
# Check current migrations
supabase migration list

# Apply all migrations
supabase db reset
```

## Quick Test Sequence

1. **Deploy function:**
   ```bash
   supabase functions deploy smart-insights
   ```

2. **Check logs immediately:**
   ```bash
   supabase functions logs smart-insights --follow
   ```

3. **Trigger in app:**
   - Open dashboard
   - Change period selector
   - Watch logs for detailed error

4. **Read error message:**
   - Logs will show exact error
   - App will show Malayalam message
   - Fix based on error type

## Expected Behavior After Fix

### Success Response:
```json
{
  "insights": [
    {
      "type": "profit",
      "title": "നല്ല ലാഭം!",
      "message": "ഇന്ന് നിങ്ങൾക്ക് ₹1,250 ലാഭമുണ്ട്!",
      "icon": "💰"
    }
  ],
  "summary": {
    "totalIncome": 5000,
    "totalExpense": 3750,
    "profit": 1250,
    "profitMargin": 25.0
  }
}
```

### No Data Response (OK):
```json
{
  "insights": [],
  "summary": null,
  "message": "ഈ കാലയളവിൽ ഡാറ്റ ഇല്ല"
}
```

## Next Steps

1. ✅ Files updated with better error handling
2. ⏳ **YOU NEED TO:** Deploy edge function
3. ⏳ **YOU NEED TO:** Check logs for specific error
4. ⏳ Based on logs, apply fix (migrations or API key)
5. ⏳ Test in app

## Commands Reference

```bash
# Deploy
supabase functions deploy smart-insights

# View logs
supabase functions logs smart-insights --limit 50

# Reset database (apply all migrations)
supabase db reset

# Check migrations status
supabase migration list

# Test function locally
supabase functions serve smart-insights
```

## Contact Points

If still not working after deployment, check:
1. Edge function logs (exact error)
2. Flutter console (detailed error from service)
3. Supabase dashboard → Edge Functions → Logs
4. SQL Editor → Test RPCs manually

---

**Status:** Ready to deploy. Run deployment command and check logs! 🚀
