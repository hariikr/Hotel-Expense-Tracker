// Smart Insights Edge Function
// Analyzes real financial data and provides AI-powered business insights

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { period = 'week' } = await req.json();

    // Initialize Supabase client with service role
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    });

    // The client-sent userId is ignored: the service role bypasses RLS,
    // so the user must come from a verified session token only.
    const token = req.headers.get('Authorization')?.replace('Bearer ', '');
    const { data: authData, error: authError } = token
      ? await supabase.auth.getUser(token)
      : { data: { user: null }, error: null };
    const userId = authError ? null : authData.user?.id;

    if (!userId) {
      return new Response(
        JSON.stringify({ success: false, error: 'Unauthorized: please log in again' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log('📊 Generating smart insights for period:', period);

    // Calculate date range based on period
    const today = new Date();
    let startDate: string;
    let endDate = today.toISOString().split('T')[0];

    switch (period) {
      case 'today':
        startDate = endDate;
        break;
      case 'week':
        const weekAgo = new Date(today);
        weekAgo.setDate(weekAgo.getDate() - 7);
        startDate = weekAgo.toISOString().split('T')[0];
        break;
      case 'month':
        const monthAgo = new Date(today);
        monthAgo.setMonth(monthAgo.getMonth() - 1);
        startDate = monthAgo.toISOString().split('T')[0];
        break;
      default:
        startDate = endDate;
    }

    console.log(`📅 Analyzing data from ${startDate} to ${endDate}`);

    // Fetch financial data using analytics functions
    // Note: Using original parameter names (target_user_id, start_date, end_date)
    const { data: expenseSummary, error: expenseError } = await supabase.rpc('get_expense_summary_by_category', {
      target_user_id: userId,
      start_date: startDate,
      end_date: endDate
    });

    if (expenseError) {
      console.error('❌ Expense summary error:', expenseError);
      throw new Error(`Failed to fetch expense summary: ${expenseError.message}`);
    }

    const { data: incomeSummary, error: incomeError } = await supabase.rpc('get_income_summary_by_category', {
      target_user_id: userId,
      start_date: startDate,
      end_date: endDate
    });

    if (incomeError) {
      console.error('❌ Income summary error:', incomeError);
      throw new Error(`Failed to fetch income summary: ${incomeError.message}`);
    }

    const { data: dailyTrend, error: trendError } = await supabase.rpc('get_daily_trend', {
      target_user_id: userId,
      days_count: period === 'month' ? 30 : 7
    });

    if (trendError) {
      console.error('❌ Daily trend error:', trendError);
      throw new Error(`Failed to fetch daily trend: ${trendError.message}`);
    }

    const { data: savingsData, error: savingsError } = await supabase.rpc('get_savings_rate', {
      target_user_id: userId,
      start_date: startDate,
      end_date: endDate
    });

    if (savingsError) {
      console.error('❌ Savings rate error:', savingsError);
      throw new Error(`Failed to fetch savings rate: ${savingsError.message}`);
    }

    console.log('✅ Data fetched successfully');
    console.log('📊 Expense summary:', expenseSummary);
    console.log('💰 Income summary:', incomeSummary);
    console.log('📈 Daily trend:', dailyTrend);
    console.log('💵 Savings data:', savingsData);

    // Handle empty data
    if ((!expenseSummary || expenseSummary.length === 0) && 
        (!incomeSummary || incomeSummary.length === 0)) {
      return new Response(
        JSON.stringify({
          insights: [{
            type: 'info',
            title: 'ഡാറ്റ ഇല്ല',
            message: 'ഈ കാലയളവിൽ ഇതുവരെ ഇൻകം അല്ലെങ്കിൽ എക്സ്പൻസ് ഡാറ്റ ഇല്ല. ആദ്യം ഇൻകം എക്സ്പൻസ് ചേർക്കൂ.',
            icon: '📊'
          }],
          summary: {
            totalIncome: 0,
            totalExpense: 0,
            profit: 0,
            profitMargin: 0,
            profitableDays: 0,
            totalDays: 0
          },
          period,
          startDate,
          endDate
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Calculate summary from the data
    const totalIncome = incomeSummary?.reduce((sum: number, item: any) => sum + parseFloat(item.total_amount || 0), 0) || 0;
    const totalExpense = expenseSummary?.reduce((sum: number, item: any) => sum + parseFloat(item.total_amount || 0), 0) || 0;
    const profit = totalIncome - totalExpense;
    const profitMargin = totalIncome > 0 ? ((profit / totalIncome) * 100).toFixed(1) : '0';
    const profitableDays = dailyTrend?.filter((day: any) => parseFloat(day.profit || 0) > 0).length || 0;
    const totalDays = dailyTrend?.length || 1;
    const avgDailyIncome = totalDays > 0 ? (totalIncome / totalDays).toFixed(0) : '0';

    const summary = {
      total_income: totalIncome,
      total_expense: totalExpense,
      profit: profit,
      profit_margin: profitMargin,
      avg_daily_income: avgDailyIncome,
      profitable_days: profitableDays,
      total_days: totalDays
    };

    console.log('📊 Data summary:', summary);
    console.log('💸 Expense breakdown:', expenseSummary);
    console.log('💰 Income breakdown:', incomeSummary);

    // Get top 5 expense categories
    const topExpenses = expenseSummary?.slice(0, 5) || [];
    
    // Get income breakdown
    const onlineIncome = incomeSummary?.find((item: any) => item.category_name?.toLowerCase().includes('online'))?.total_amount || 0;
    const offlineIncome = incomeSummary?.find((item: any) => item.category_name?.toLowerCase().includes('offline'))?.total_amount || 0;
    const onlinePercentage = totalIncome > 0 ? ((parseFloat(onlineIncome as any) / totalIncome) * 100).toFixed(1) : '0';
    const offlinePercentage = totalIncome > 0 ? ((parseFloat(offlineIncome as any) / totalIncome) * 100).toFixed(1) : '0';

    // Build prompt for Gemini
    const prompt = `You are a professional business analyst for a small hotel/restaurant in Kerala, India. Analyze this financial data and provide actionable insights in Malayalam.

FINANCIAL DATA (${period === 'today' ? 'Today' : period === 'week' ? 'Last 7 Days' : 'Last 30 Days'}):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 SUMMARY:
• Total Income: ₹${summary.total_income || 0}
• Total Expense: ₹${summary.total_expense || 0}
• Net Profit: ₹${summary.profit || 0}
• Profit Margin: ${summary.profit_margin || 0}%
• Average Daily Income: ₹${summary.avg_daily_income || 0}
• Profitable Days: ${summary.profitable_days || 0} out of ${summary.total_days || 0}

💰 INCOME BREAKDOWN:
• Online Income: ₹${onlineIncome} (${onlinePercentage}%)
• Offline Income: ₹${offlineIncome} (${offlinePercentage}%)

💸 TOP EXPENSE CATEGORIES:
${topExpenses?.map((exp: any, idx: number) => 
  `${idx + 1}. ${exp.category_name}: ₹${exp.total_amount} (${exp.percentage}%)`
).join('\n') || 'No expense data'}

📈 RECENT TREND (Last 7 Days):
${dailyTrend?.slice(0, 5).map((day: any) => 
  `• ${day.date}: Profit ₹${parseFloat(day.profit || 0).toFixed(0)} (Income: ₹${parseFloat(day.total_income || 0).toFixed(0)}, Expense: ₹${parseFloat(day.total_expense || 0).toFixed(0)})`
).join('\n') || 'No recent data'}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TASK: Generate exactly 4-5 smart business insights in Malayalam. Each insight must:
1. Start with a relevant emoji
2. Be specific with actual numbers from the data above
3. Be actionable and helpful
4. Sound encouraging and supportive
5. Focus on: profit trends, expense patterns, income sources, cost-saving tips, or growth opportunities

CRITICAL: Respond with ONLY valid JSON. No markdown, no code blocks, no explanations.

RESPONSE FORMAT:
{
  "insights": [
    {
      "type": "profit|expense|income|trend|suggestion",
      "title": "Short Malayalam title (5-8 words)",
      "message": "Detailed Malayalam message (25-45 words with specific numbers)",
      "icon": "emoji"
    }
  ]
}

EXAMPLE:
{
  "insights": [
    {
      "type": "profit",
      "title": "ഈ ആഴ്ച നല്ല ലാഭം!",
      "message": "നിങ്ങൾക്ക് ₹${Math.round(profit)} ലാഭമുണ്ട്! ലാഭ മാർജിൻ ${profitMargin}% ആണ്. ${profitableDays} ദിവസം ലാഭകരമായി. വളരെ നന്നായി മുന്നോട്ട് പോകുന്നു!",
      "icon": "💰"
    }
  ]
}`;

    console.log('🤖 Calling Gemini API for insights...');

    // Call Gemini API
    const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY');
    if (!GEMINI_API_KEY) {
      throw new Error('GEMINI_API_KEY not configured');
    }

    // Set GEMINI_INSIGHTS_MODEL as a function secret to switch models without a code change.
    const model = Deno.env.get('GEMINI_INSIGHTS_MODEL') || 'gemini-3.8-flash';
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;

    const geminiResponse = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': GEMINI_API_KEY },
      body: JSON.stringify({
        contents: [{
          role: "user",
          parts: [{ text: prompt }]
        }],
        // Thinking tokens count toward maxOutputTokens, so leave headroom for the JSON.
        generationConfig: {
          maxOutputTokens: 8192,
          responseMimeType: 'application/json'
        }
      })
    });

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text();
      throw new Error(`Gemini API error: ${geminiResponse.status} - ${errorText}`);
    }

    const geminiData = await geminiResponse.json();
    const aiResponse = (geminiData.candidates?.[0]?.content?.parts || [])
      .filter((p: any) => p.text && !p.thought)
      .map((p: any) => p.text)
      .join('');

    console.log('🤖 AI Response:', aiResponse);

    // Parse JSON response
    let insights = [];
    try {
      // Extract JSON from response (in case there's markdown)
      const jsonMatch = aiResponse.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        const parsed = JSON.parse(jsonMatch[0]);
        insights = parsed.insights || [];
      } else {
        // Fallback: create default insights
        insights = [
          {
            type: 'summary',
            title: `${period === 'today' ? 'ഇന്നത്തെ' : period === 'week' ? 'ഈ ആഴ്ചയിലെ' : 'ഈ മാസത്തെ'} സാരാംശം`,
            message: `മൊത്തം വരുമാനം ₹${summary.total_income}, ചെലവ് ₹${summary.total_expense}, ലാഭം ₹${summary.profit}`,
            icon: '📊'
          }
        ];
      }
    } catch (parseError) {
      console.error('JSON parse error:', parseError);
      // Fallback insights with actual data
      insights = [
        {
          type: 'summary',
          title: `${period === 'today' ? 'ഇന്നത്തെ' : period === 'week' ? 'ഈ ആഴ്ചയിലെ' : 'ഈ മാസത്തെ'} സാരാംശം`,
          message: `മൊത്തം വരുമാനം ₹${Math.round(totalIncome)}, ചെലവ് ₹${Math.round(totalExpense)}, ലാഭം ₹${Math.round(profit)}. ${profitableDays} ദിവസം ലാഭകരമായി.`,
          icon: '📊'
        }
      ];
      
      if (profit > 0) {
        insights.push({
          type: 'profit',
          title: 'നല്ല ലാഭം ഉണ്ട്!',
          message: `നിങ്ങൾക്ക് ₹${Math.round(profit)} ലാഭമുണ്ട്. ലാഭ മാർജിൻ ${profitMargin}% ആണ്. വളരെ നന്നായി പോകുന്നു!`,
          icon: '💰'
        });
      } else {
        insights.push({
          type: 'warning',
          title: 'ചെലവ് കൂടുതലാണ്',
          message: `ഇപ്പോൾ ₹${Math.round(Math.abs(profit))} നഷ്ടമുണ്ട്. ചെലവ് കുറയ്ക്കാൻ ശ്രദ്ധിക്കൂ.`,
          icon: '⚠️'
        });
      }
      
      if (topExpenses.length > 0) {
        const topExpense = topExpenses[0];
        insights.push({
          type: 'expense',
          title: `${topExpense.category_name} ചെലവ് കൂടുതൽ`,
          message: `${topExpense.category_name} എന്നതിന് ₹${Math.round(parseFloat(topExpense.total_amount))} (${topExpense.percentage}%) ചെലവായി. ഇത് കുറയ്ക്കാൻ ശ്രമിക്കൂ.`,
          icon: '💸'
        });
      }
      
      if (totalIncome > 0) {
        insights.push({
          type: 'income',
          title: 'വരുമാന വിശകലനം',
          message: `ഓൺലൈൻ: ₹${Math.round(parseFloat(onlineIncome as any))}, ഓഫ്‌ലൈൻ: ₹${Math.round(parseFloat(offlineIncome as any))}. ${parseFloat(onlinePercentage) > 50 ? 'ഓൺലൈൻ വരുമാനം കൂടുതൽ!' : 'ഓഫ്‌ലൈൻ വരുമാനം കൂടുതൽ!'}`,
          icon: '💵'
        });
      }
    }

    return new Response(
      JSON.stringify({
        insights,
        summary: {
          totalIncome: Math.round(totalIncome),
          totalExpense: Math.round(totalExpense),
          profit: Math.round(profit),
          profitMargin: parseFloat(profitMargin),
          profitableDays: profitableDays,
          totalDays: totalDays
        },
        period,
        startDate,
        endDate
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    );

  } catch (error) {
    console.error('❌ Error in smart-insights function:', error);
    console.error('Error details:', error instanceof Error ? error.message : String(error));
    if (error instanceof Error && error.stack) {
      console.error('Stack trace:', error.stack);
    }

    // Provide detailed error message
    let errorMessage = 'Unknown error occurred';
    let errorDetails = '';

    if (error instanceof Error) {
      errorMessage = error.message;
      errorDetails = error.stack || '';
      
      // Check specific error types
      if (errorMessage.includes('get_expense_summary_by_category') || 
          errorMessage.includes('get_income_summary_by_category') ||
          errorMessage.includes('get_daily_trend') ||
          errorMessage.includes('get_savings_rate')) {
        errorMessage = 'Database functions not available. Please ensure migrations are applied: supabase db push';
        errorDetails = 'Run migration 103_fix_rpc_function_params.sql';
      } else if (errorMessage.includes('GEMINI_API_KEY')) {
        errorMessage = 'Gemini API key not configured';
        errorDetails = 'Please set GEMINI_API_KEY in Supabase project settings';
      } else if (errorMessage.includes('Gemini API')) {
        errorMessage = 'Gemini API request failed';
        errorDetails = errorMessage;
      } else if (errorMessage.includes('fetch')) {
        errorMessage = 'Failed to fetch data from database';
        errorDetails = errorMessage;
      }
    }

    return new Response(
      JSON.stringify({
        error: errorMessage,
        details: errorDetails,
        insights: [{
          type: 'error',
          title: 'എറർ സംഭവിച്ചു',
          message: 'സ്മാർട്ട് ഇൻസൈറ്റുകൾ ലോഡ് ചെയ്യാൻ കഴിഞ്ഞില്ല. ദയവായി വീണ്ടും ശ്രമിക്കൂ.',
          icon: '⚠️'
        }],
        summary: {
          totalIncome: 0,
          totalExpense: 0,
          profit: 0,
          profitMargin: 0,
          profitableDays: 0,
          totalDays: 0
        }
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    );
  }
});
