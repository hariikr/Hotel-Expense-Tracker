# Fix "AI Not Available" Error ⚠️

## Problem
The AI chat is showing **"AI is not available right now"** error because:
- The AI Edge Function hasn't been deployed to Supabase
- OR the Gemini API key isn't configured

## Quick Fix (Easiest Way) 🚀

Just run the deployment script that's already in your project:

1. **Double-click** `deploy_ai_function.bat` in your project folder
2. Follow the on-screen instructions
3. When asked for API key, get it from: https://makersuite.google.com/app/apikey (FREE)
4. Done! Test the AI in your app

---

## Solution

### Step 1: Get Gemini API Key (FREE)

1. Go to: https://makersuite.google.com/app/apikey
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the key (it starts with `AIza...`)

### Step 2: Set the API Key in Supabase Dashboard

Since you don't have Supabase CLI installed, use the web dashboard:

1. Go to your Supabase project: https://supabase.com/dashboard
2. Select your project
3. Go to **Edge Functions** in the left sidebar
4. Click on **Secrets** or **Environment Variables**
5. Add a new secret:
   - **Name**: `GEMINI_API_KEY`
   - **Value**: Paste your API key from Step 1
6. Click **Save**

### Step 3: Deploy the Edge Function

#### Option A: Using Supabase Dashboard (Easiest)

1. In your Supabase Dashboard, go to **Edge Functions**
2. Click **Deploy a new function**
3. Select **From existing code**
4. Choose the `ai-chat` folder from your project
5. Click **Deploy**

#### Option B: Install Supabase CLI and Deploy

Open PowerShell as Administrator and run:

```powershell
# Install Supabase CLI (Windows)
scoop install supabase

# Or using npm
npm install -g supabase

# Then deploy the function
cd "c:\Users\harik\Desktop\Hotel Expense Tracker"
supabase functions deploy ai-chat
```

### Step 4: Test the AI

1. Open your app
2. Go to AI Chat screen
3. Try asking: "ഇന്നത്തെ ലാഭം എത്ര?" (How much profit today?)
4. The AI should respond!

## Quick Deploy Script

If you have issues with CLI, use this batch file to deploy:

**deploy_ai_function.bat** (Already exists in your project)

```batch
@echo off
echo Deploying AI Chat Function...
supabase functions deploy ai-chat --no-verify-jwt
echo.
echo Deployment complete! Test the AI in your app.
pause
```

## Troubleshooting

### Error: "GEMINI_API_KEY not configured"
- Make sure you set the secret in Supabase Dashboard
- Wait 1-2 minutes after setting the secret
- Redeploy the function

### Error: "Network error"
- Check your internet connection
- Make sure your Supabase project is active
- Verify the Edge Function is deployed

### Error: "Request timed out"
- Gemini API might be slow
- Try again after a few seconds
- Check if your API key is valid

## Verify Deployment

After deployment, check:

1. **Supabase Dashboard** → **Edge Functions** → Should see `ai-chat` listed
2. **Secrets** → Should see `GEMINI_API_KEY` listed
3. **Function Logs** → Check for any errors when you send a message

## Alternative: Local Testing

To test locally before deploying:

```powershell
# Set environment variable
$env:GEMINI_API_KEY = "your_api_key_here"

# Run function locally
supabase functions serve ai-chat
```

Then test with:
```powershell
curl -X POST 'http://localhost:54321/functions/v1/ai-chat' `
  -H 'Content-Type: application/json' `
  -d '{\"message\": \"Test\", \"userId\": null}'
```

## Success!

Once deployed, the AI will:
- Answer questions in Malayalam
- Fetch data from your database
- Give business advice
- Work offline (chats saved locally)
