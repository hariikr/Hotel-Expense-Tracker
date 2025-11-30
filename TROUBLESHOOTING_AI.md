# Troubleshooting AI Chat 500 Error

## Current Issue
Getting 500 Internal Server Error when calling the edge function.

## Most Likely Causes

### 1. ❌ Edge Function Not Deployed Yet
**Solution**: Deploy the function first

### 2. ❌ GEMINI_API_KEY Secret Not Set
**Solution**: Set the API key in Supabase

### 3. ❌ Database Functions Not Created
**Solution**: Run the migration first

---

## Step-by-Step Fix

### ✅ Step 1: Apply Database Migration FIRST

Before deploying the edge function, you MUST create the database functions.

**Using Supabase Dashboard:**

1. Go to: https://supabase.com/dashboard/project/khpeuremcbkpdmombtkg/sql
2. Click "New Query"
3. Copy the ENTIRE contents of `005_ai_chat_setup.sql` (all 363 lines)
4. Paste into the editor
5. Click "Run" (or press Ctrl+Enter)
6. You should see: "Success. No rows returned"

**Verify it worked:**
```sql
-- Run this query to check if functions were created
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name LIKE 'get_%'
AND routine_schema = 'public';
```

You should see these 7 functions:
- get_daily_data
- get_range_data
- get_category_total
- get_top_expense_categories
- get_income_breakdown
- get_recent_transactions
- compare_date_ranges

---

### ✅ Step 2: Get Gemini API Key

1. Go to: https://makersuite.google.com/app/apikey
2. Click "Create API Key"
3. Copy the key (starts with `AIza...`)

---

### ✅ Step 3: Set Gemini API Key in Supabase

**Using Dashboard:**

1. Go to: https://supabase.com/dashboard/project/khpeuremcbkpdmombtkg/settings/functions
2. Scroll down to "Secrets" section
3. Click "Add Secret" or "Add a new secret"
4. Name: `GEMINI_API_KEY`
5. Value: Paste your API key
6. Click "Save"

**Verify:**
- You should see `GEMINI_API_KEY` in the list of secrets
- The value should be hidden (showing as `••••••••`)

---

### ✅ Step 4: Deploy Edge Function

**Option A: Using Supabase CLI (Recommended)**

```bash
# Open terminal in your project directory
cd "c:\Users\harik\Desktop\Hotel Expense Tracker"

# Login to Supabase (if not already)
supabase login

# Link your project
supabase link --project-ref khpeuremcbkpdmombtkg

# Deploy the function
supabase functions deploy ai-chat
```

**Option B: Manual Upload in Dashboard**

1. Go to: https://supabase.com/dashboard/project/khpeuremcbkpdmombtkg/functions
2. Click "Create a new function"
3. Name: `ai-chat`
4. Copy entire contents of `supabase/functions/ai-chat/index.ts`
5. Paste in the editor
6. Click "Deploy"

---

### ✅ Step 5: Test the Function

After deploying, test with curl:

```bash
# Replace YOUR_ANON_KEY with your actual anon key
# Get it from: https://supabase.com/dashboard/project/khpeuremcbkpdmombtkg/settings/api

curl -X POST "https://khpeuremcbkpdmombtkg.supabase.co/functions/v1/ai-chat" ^
  -H "Authorization: Bearer YOUR_ANON_KEY" ^
  -H "Content-Type: application/json" ^
  -d "{\"message\": \"test\", \"userId\": null}"
```

**Expected Success Response:**
```json
{
  "reply": "Some AI response here",
  "toolsUsed": []
}
```

**If Still Getting 500 Error:**

Check function logs:
```bash
supabase functions logs ai-chat
```

Or in dashboard:
https://supabase.com/dashboard/project/khpeuremcbkpdmombtkg/functions

---

## Common Error Messages & Solutions

### Error: "GEMINI_API_KEY not configured"
**Fix**: Set the secret in Step 3 above

### Error: "function get_daily_data does not exist"
**Fix**: Run the migration in Step 1 above

### Error: "Function not found"
**Fix**: Deploy the edge function in Step 4 above

### Error: "Invalid API key"
**Fix**: Get a new Gemini API key and update the secret

---

## Quick Checklist

Before testing the Flutter app, ensure:

- [ ] Migration applied (database functions created)
- [ ] Gemini API key obtained
- [ ] Gemini API key set as Supabase secret
- [ ] Edge function deployed
- [ ] Test curl command works
- [ ] Some data exists in your income/expense tables

---

## Alternative: Test Without AI First

If you want to verify the app UI works without the AI backend:

1. Comment out the actual API call in `ai_service.dart`
2. Return a mock response
3. Test the UI
4. Then fix the backend

Would you like me to create a mock version for testing?

---

## Need the Anon Key?

Your Supabase Anon Key is at:
https://supabase.com/dashboard/project/khpeuremcbkpdmombtkg/settings/api

Copy the "anon" "public" key (NOT the service_role key).

---

## Installation Order Matters!

**CORRECT ORDER:**
1. ✅ Apply database migration (005_ai_chat_setup.sql)
2. ✅ Get Gemini API key
3. ✅ Set GEMINI_API_KEY secret in Supabase
4. ✅ Deploy edge function
5. ✅ Test with curl
6. ✅ Run Flutter app

**WRONG ORDER will cause 500 errors!**
