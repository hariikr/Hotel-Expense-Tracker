# Quick Start Checklist

## ✅ Pre-Deployment Checklist

- [ ] Get Gemini API Key from https://makersuite.google.com/app/apikey
- [ ] Get Supabase Anon Key from dashboard
- [ ] Install Supabase CLI (optional but recommended)

## 📝 Deployment Steps

### 1. Database Migration
```bash
# Option A: Run in Supabase SQL Editor
# Copy contents of: supabase/migrations/005_ai_chat_setup.sql
# Paste in: https://supabase.com/dashboard/project/khpeuremcbkpdmombtkg/sql

# Option B: Use CLI
supabase db push
```

### 2. Set Gemini API Key
```bash
# In Supabase Dashboard: Settings > Edge Functions > Secrets
# Add: GEMINI_API_KEY = your_key_here

# Or via CLI:
supabase secrets set GEMINI_API_KEY=your_key_here
```

### 3. Deploy Edge Function
```bash
# Login and link project
supabase login
supabase link --project-ref khpeuremcbkpdmombtkg

# Deploy
supabase functions deploy ai-chat
```

### 4. Test Edge Function
```bash
# Edit test_ai_chat.bat and add your ANON_KEY
# Then run it to test
```

### 5. Run Flutter App
```bash
flutter pub get
flutter run
```

## 🎯 Quick Test Questions

### English
- What is today's profit?
- Show this week's expenses
- How much did I spend on fish this month?
- Compare this month with last month

### Malayalam
- ഇന്നത്തെ ലാഭം എത്ര?
- ഈ ആഴ്ചയിലെ ചെലവ് കാണിക്കൂ
- ഈ മാസം മീനിന് എത്ര ചെലവായി?
- ഈ മാസവും കഴിഞ്ഞ മാസവും താരതമ്യം ചെയ്യൂ

## 🔍 Verify Setup

- [ ] Migration applied (check `chat_messages` table exists)
- [ ] Edge function deployed (visible in dashboard)
- [ ] Gemini API key set (check secrets)
- [ ] Test curl command works
- [ ] Flutter app shows AI tab
- [ ] Can send messages in app

## 📊 What Each File Does

| File | Purpose |
|------|---------|
| `005_ai_chat_setup.sql` | Creates database tables and functions |
| `supabase/functions/ai-chat/index.ts` | Edge function with Gemini integration |
| `lib/services/ai_service.dart` | Flutter service to call edge function |
| `lib/screens/ai/ai_chat_screen.dart` | Chat UI screen |
| `lib/screens/main_navigation.dart` | Updated with AI tab |

## 🚨 Common Issues

### "Function not found"
- Deploy edge function: `supabase functions deploy ai-chat`

### "GEMINI_API_KEY not configured"
- Set secret: `supabase secrets set GEMINI_API_KEY=your_key`

### "No data found"
- Add some income/expense data in the app first

### "AI not responding"
- Check function logs: `supabase functions logs ai-chat`
- Verify Gemini API key is valid

## 🎉 Success!

Once everything is working:
1. Open app
2. Tap AI icon (4th tab)
3. Ask questions
4. Get instant answers!

---

**Your Supabase Project**: https://supabase.com/dashboard/project/khpeuremcbkpdmombtkg

**Edge Function URL**: https://khpeuremcbkpdmombtkg.supabase.co/functions/v1/ai-chat
