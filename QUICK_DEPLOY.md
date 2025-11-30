# ⚡ Quick Deployment - 5 Steps

## 1️⃣ Set Gemini API Key (2 minutes)
```
URL: https://supabase.com/dashboard/project/khpeuremcbkpdmombtkg/settings/functions
→ Click "Add new secret"
→ Name: GEMINI_API_KEY
→ Value: AIzaSyCrM1EkbqdRUvJ-8jJFJS_lNTUrQwjVpSw
→ Click "Save"
```

## 2️⃣ Apply Database Migration (1 minute)
```
URL: https://supabase.com/dashboard/project/khpeuremcbkpdmombtkg/sql
→ Open: supabase/migrations/005_ai_chat_setup.sql
→ Copy entire file
→ Paste in SQL Editor
→ Click "Run"
→ Verify: "Success. No rows returned"
```

## 3️⃣ Deploy Edge Function (1 minute)
```bash
cd "c:\Users\harik\Desktop\Hotel Expense Tracker"
supabase functions deploy ai-chat
```
OR manually:
```
URL: https://supabase.com/dashboard/project/khpeuremcbkpdmombtkg/functions
→ Click "Deploy new function"
→ Upload: supabase/functions/ai-chat/index.ts
→ Function name: ai-chat
→ Click "Deploy"
```

## 4️⃣ Build Flutter App (3 minutes)
```bash
cd "c:\Users\harik\Desktop\Hotel Expense Tracker"
flutter pub get
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

## 5️⃣ Test on Device (2 minutes)
```bash
# Install
flutter install --release

# Test steps:
1. Open app
2. Go to AI tab (4th icon 🤖)
3. Press microphone 🎤
4. Allow permission
5. Say: "ഇന്നത്തെ ലാഭം എത്ര?"
6. Listen to response 🔊
```

---

## ✅ Verification

### All features working?
- [ ] Voice input recognizes Malayalam
- [ ] Auto-sends after 3 seconds
- [ ] AI responds in Malayalam
- [ ] Response is spoken aloud
- [ ] Auto-clears after 10 minutes
- [ ] All UI in Malayalam

### If something fails:
```bash
# Check edge function logs
supabase functions logs ai-chat

# Check Flutter console
flutter run

# Restart app and try again
```

---

## 🎯 Total Time: ~10 minutes

## 📞 Quick Help

**Microphone not working?**
→ Settings → Apps → Hotel Expense Tracker → Permissions → Microphone → Allow

**No voice output?**
→ Increase volume, turn off silent mode

**Edge function 500 error?**
→ Check GEMINI_API_KEY is set correctly

**Chat not in Malayalam?**
→ Redeploy edge function with latest code

---

**Ready to deploy! Follow steps 1-5 above.** 🚀
