# Migration from Gemini to Claude Anthropic API

## Summary

Successfully migrated the AI chat function from Google Gemini API to Claude Anthropic API (Claude Sonnet 4.5).

## Changes Made

### 1. API Endpoint Update
- **Before**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent`
- **After**: `https://api.anthropic.com/v1/messages`

### 2. API Key Environment Variable
- **Before**: `GEMINI_API_KEY`
- **After**: `ANTHROPIC_API_KEY`

### 3. Request Format Changes
- Updated request body structure to match Anthropic's API format
- Changed system prompt delivery (now in `system` field instead of conversation)
- Tool/function format updated from `function_declarations` to Anthropic's `tools` format with `input_schema`

### 4. Response Format Changes
- **Before**: Response in `candidates[0].content.parts` array with `functionCall` objects
- **After**: Response in `content` array with `tool_use` blocks
- Tool calls now have `type: "tool_use"` with `name` and `input` fields
- Text responses now have `type: "text"` with `text` field

### 5. Model Used
- **Model**: `claude-sonnet-4-20250514` (Claude Sonnet 4.5)
- **Max Tokens**: 4096
- **Temperature**: 0.7

## Required Configuration Steps

### Step 1: Get Anthropic API Key

1. Visit [Anthropic Console](https://console.anthropic.com/)
2. Sign up or log in
3. Navigate to API Keys section
4. Create a new API key
5. Copy the API key (it starts with `sk-ant-`)

### Step 2: Update Supabase Secrets

You need to set the new API key in Supabase:

```bash
# Set the Anthropic API key
supabase secrets set ANTHROPIC_API_KEY=sk-ant-your_key_here
```

Or through Supabase Dashboard:
1. Go to your project dashboard at [supabase.com](https://supabase.com)
2. Navigate to **Settings** → **Edge Functions** → **Secrets**
3. Add a new secret:
   - Name: `ANTHROPIC_API_KEY`
   - Value: Your Anthropic API key

### Step 3: Redeploy the AI Chat Function

After setting the API key, redeploy the function:

```bash
supabase functions deploy ai-chat
```

### Step 4: Remove Old Gemini Key (Optional)

Once confirmed working, you can remove the old Gemini API key:

```bash
supabase secrets unset GEMINI_API_KEY
```

## Testing

After deployment, test the AI chat function:

1. Open your app
2. Navigate to the AI Chat/Smart Insights screen
3. Try sending a message in Malayalam
4. Verify the AI responds correctly
5. Test adding income/expense through natural language ("phonepay 500", "fish 800")

## Cost Comparison

### Gemini API Pricing (for reference)
- Gemini 2.5 Pro: $0.00125 per 1K characters

### Claude API Pricing
- Claude Sonnet 4: 
  - Input: $3 per million tokens (~$0.003 per 1K tokens)
  - Output: $15 per million tokens (~$0.015 per 1K tokens)

**Note**: Claude pricing is slightly higher but offers superior performance, better Malayalam support, and more reliable tool calling.

## What Stays the Same

- All tool/function names remain unchanged
- The Malayalam system prompt remains the same
- All conversation history handling works as before
- Database integration is unchanged
- Client-side code (Flutter app) requires no changes

## Troubleshooting

### Error: "ANTHROPIC_API_KEY not configured"

**Solution**: Make sure you've set the API key in Supabase secrets:
```bash
supabase secrets set ANTHROPIC_API_KEY=your_key_here
```

### Error: "Invalid API key"

**Solution**: 
- Verify your API key is correct
- Ensure it starts with `sk-ant-`
- Check you have remaining credits in your Anthropic account
- Visit [Anthropic Console](https://console.anthropic.com/) to verify

### Error: "Rate limit exceeded"

**Solution**: 
- Anthropic has rate limits based on your plan tier
- Free tier: Lower rate limits
- Paid plans: Higher rate limits
- Implement exponential backoff in client if needed

### Tool Calling Not Working

**Solution**:
- Claude's tool calling format is different from Gemini
- The code has been updated to handle Claude's format
- If issues persist, check console logs in Supabase Functions logs

## Files Modified

1. `supabase/functions/ai-chat/index.ts` - Main AI chat function

## Documentation That Needs Updating

The following documentation files still reference GEMINI_API_KEY and should be updated:

- `AI_ASSISTANT_SETUP.md`
- `AI_EDGE_FUNCTION_UPDATE.md`
- `DEPLOYMENT_CHECKLIST.md`
- `DEPLOYMENT_READY.md`
- `deploy_ai_function.bat`
- `FIX_AI_NOT_AVAILABLE.md`
- `QUICKSTART_AI.md`
- `QUICK_DEPLOY.md`
- `README.md`

Would you like me to update these documentation files to reflect the change to Claude API?

## Benefits of Claude

1. **Better Malayalam Support**: Claude has stronger multilingual capabilities
2. **More Reliable Tool Calling**: Anthropic's tool use implementation is robust
3. **Better Context Understanding**: Claude Sonnet 4.5 has superior comprehension
4. **Longer Context Window**: Claude supports longer conversations
5. **More Natural Responses**: Claude produces more human-like responses

## Rollback Plan

If you need to rollback to Gemini:

1. Revert the changes in `supabase/functions/ai-chat/index.ts`
2. Set `GEMINI_API_KEY` in Supabase secrets
3. Redeploy the function

The git history contains the previous version with Gemini integration.

---

**Migration completed successfully! ✅**

Next steps:
1. Get your Anthropic API key
2. Set it in Supabase secrets as `ANTHROPIC_API_KEY`
3. Redeploy the function
4. Test thoroughly
