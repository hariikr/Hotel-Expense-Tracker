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
    const { userId, period = 'week' } = await req.json();

    // Initialize Supabase client with service role
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    });

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

    // Fetch financial data using new analytics functions
    const { data: expenseSummary, error: expenseError } = await supabase.rpc('get_expense_summary_by_category', {
      p_user_id: userId,
      p_start_date: startDate,
      p_end_date: endDate
    });

    if (expenseError) throw expenseError;

    const { data: incomeSummary, error: incomeError } = await supabase.rpc('get_income_summary_by_category', {
      p_user_id: userId,
      p_start_date: startDate,
      p_end_date: endDate
    });

    if (incomeError) throw incomeError;

    const { data: dailyTrend, error: trendError } = await supabase.rpc('get_daily_trend', {
      p_user_id: userId,
      p_days_count: 7
    });

    if (trendError) throw trendError;

    const { data: savingsData, error: savingsError } = await supabase.rpc('get_savings_rate', {
      p_user_id: userId,
      p_start_date: startDate,
      p_end_date: endDate
    });

    if (savingsError) throw savingsError;

    // Calculate summary from the data
    const totalIncome = incomeSummary?.reduce((sum: number, item: any) => sum + (item.total_amount || 0), 0) || 0;
    const totalExpense = expenseSummary?.reduce((sum: number, item: any) => sum + (item.total_amount || 0), 0) || 0;
    const profit = totalIncome - totalExpense;
    const profitMargin = totalIncome > 0 ? ((profit / totalIncome) * 100).toFixed(2) : 0;
    const profitableDays = dailyTrend?.filter((day: any) => day.profit > 0).length || 0;
    const totalDays = dailyTrend?.length || 0;
    const avgDailyIncome = totalDays > 0 ? (totalIncome / totalDays).toFixed(2) : 0;

    const summary = {
      total_income: totalIncome,
      total_expense: totalExpense,
      profit: profit,
      profit_margin: profitMargin,
      avg_daily_income: avgDailyIncome,
      profitable_days: profitableDays,
      total_days: totalDays
    };

    if (!summary) {
      return new Response(
        JSON.stringify({
          insights: [],
          summary: null,
          message: 'ഈ കാലയളവിൽ ഡാറ്റ ഇല്ല'
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log('📊 Data summary:', summary);
    console.log('💸 Top expenses:', expenseSummary);
    console.log('💰 Income breakdown:', incomeSummary);
    console.log('📈 Daily trend:', dailyTrend);

    // Get top 5 expense categories
    const topExpenses = expenseSummary?.slice(0, 5) || [];
    
    // Get income breakdown
    const onlineIncome = incomeSummary?.find((item: any) => item.category_name?.toLowerCase() === 'online')?.total_amount || 0;
    const offlineIncome = incomeSummary?.find((item: any) => item.category_name?.toLowerCase() === 'offline')?.total_amount || 0;
    const onlinePercentage = totalIncome > 0 ? ((onlineIncome / totalIncome) * 100).toFixed(1) : 0;
    const offlinePercentage = totalIncome > 0 ? ((offlineIncome / totalIncome) * 100).toFixed(1) : 0;

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
  `• ${day.trend_date}: Profit ₹${day.profit} (Income: ₹${day.total_income}, Expense: ₹${day.total_expense})`
).join('\n') || 'No recent data'}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TASK: Generate exactly 4-6 smart business insights in Malayalam. Each insight must:
1. Start with an emoji relevant to the insight
2. Be specific and actionable
3. Include actual numbers from the data
4. Be encouraging and supportive
5. Focus on one specific aspect (profit, expenses, income, trends, suggestions)

RESPONSE FORMAT (JSON only):
{
  "insights": [
    {
      "type": "profit|expense|income|trend|warning|suggestion",
      "title": "Short title in Malayalam (5-8 words)",
      "message": "Detailed insight in Malayalam (20-40 words with specific numbers)",
      "icon": "emoji"
    }
  ]
}

EXAMPLE INSIGHTS:
{
  "insights": [
    {
      "type": "profit",
      "title": "നല്ല ലാഭം വരുന്നുണ്ട്!",
      "message": "ഈ ആഴ്ച നിങ്ങൾക്ക് ₹15,450 ലാഭമുണ്ട്! കഴിഞ്ഞ ആഴ്ചയേക്കാൾ 12% കൂടുതൽ. നിങ്ങളുടെ കഠിനാധ്വാനം ഫലിക്കുന്നുണ്ട് അമ്മേ! തുടർന്നും ഇതേ രീതിയിൽ പോകൂ!",
      "icon": "💰"
    },
    {
      "type": "expense",
      "title": "മീൻ ചെലവ് കൂടുതലാണ്",
      "message": "ഈ ആഴ്ച മീനിന് ₹8,500 ചെലവായി (മൊത്തം ചെലവിന്റെ 35%). വെള്ളിയാഴ്ച മൊത്തമായി വാങ്ങിയാൽ വില കുറയും. സീസണൽ മീൻ തിരഞ്ഞെടുക്കൂ.",
      "icon": "🐟"
    }
  ]
}

IMPORTANT RULES:
- MUST respond with valid JSON only
- NO markdown, NO code blocks, NO explanations
- Exactly 4-6 insights
- All text in Malayalam
- Include real numbers from the data
- Be encouraging and supportive like a daughter talking to mother
- Focus on actionable advice`;

    console.log('🤖 Calling Gemini API for insights...');

    // Call Gemini API
    const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY');
    if (!GEMINI_API_KEY) {
      throw new Error('GEMINI_API_KEY not configured');
    }

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`;

    const geminiResponse = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{
          role: "user",
          parts: [{ text: prompt }]
        }],
        generationConfig: {
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048
        }
      })
    });

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text();
      throw new Error(`Gemini API error: ${geminiResponse.status} - ${errorText}`);
    }

    const geminiData = await geminiResponse.json();
    const aiResponse = geminiData.candidates?.[0]?.content?.parts?.[0]?.text || '';

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
      // Fallback insights
      insights = [
        {
          type: 'summary',
          title: 'സാമ്പത്തിക സാരാംശം',
          message: `ഈ കാലയളവിൽ നിങ്ങൾക്ക് ₹${summary.profit} ലാഭമുണ്ട്. കഴിഞ്ഞ ദിവസങ്ങളിൽ ${summary.profitable_days} ദിവസം ലാഭകരമായിരുന്നു.`,
          icon: '💰'
        },
        {
          type: 'income',
          title: 'വരുമാന വിശകലനം',
          message: `ഓൺലൈൻ: ₹${onlineIncome}, ഓഫ്‌ലൈൻ: ₹${offlineIncome}. ${parseFloat(onlinePercentage as string) > 50 ? 'ഓൺലൈൻ കൂടുതൽ!' : 'ഓഫ്‌ലൈൻ കൂടുതൽ!'}`,
          icon: '💵'
        }
      ];
    }

    return new Response(
      JSON.stringify({
        insights,
        summary: {
          totalIncome: summary.total_income || 0,
          totalExpense: summary.total_expense || 0,
          profit: summary.profit || 0,
          profitMargin: summary.profit_margin || 0,
          profitableDays: summary.profitable_days || 0,
          totalDays: summary.total_days || 0
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
    console.error('Error stack:', error instanceof Error ? error.stack : 'No stack trace');

    // Provide detailed error message
    let errorMessage = 'Unknown error';
    if (error instanceof Error) {
      errorMessage = error.message;
      
      // Check specific error types
      if (errorMessage.includes('get_expense_summary_by_category') || 
          errorMessage.includes('get_income_summary_by_category') ||
          errorMessage.includes('get_daily_trend') ||
          errorMessage.includes('get_savings_rate')) {
        errorMessage = 'Database analytics functions not found. Please run migration 102: supabase db push';
      } else if (errorMessage.includes('GEMINI_API_KEY')) {
        errorMessage = 'Gemini API key not configured. Please set GEMINI_API_KEY secret.';
      } else if (errorMessage.includes('Gemini API error')) {
        errorMessage = 'Gemini API error. Check API key and quota.';
      }
    }

    return new Response(
      JSON.stringify({
        error: errorMessage,
        details: error instanceof Error ? error.message : String(error),
        insights: [],
        summary: null
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    );
  }
});
