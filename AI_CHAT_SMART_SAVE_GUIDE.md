# AI Chat Smart Save - User Guide

## 🎯 Overview
The AI can now automatically detect and save income/expense from natural language messages!

## ✅ What's Fixed

### 1. **Automatic Income Detection**
The AI will automatically call `add_income` tool when detecting:

**Examples:**
```
User: "1000 വരുമാനം"
AI: ✅ സേവ് ചെയ്തു അമ്മേ! കൊള്ളാം! 😊
     💰 ഇന്നത്തെ മൊത്തം വരുമാനം: ₹1,000

User: "phonepay 500"
AI: ✅ സേവ് ചെയ്തു! ഫോൺപേ വഴി ₹500 വരുമാനം ചേർത്തു!
     📱 ഓൺലൈൻ: ₹500

User: "swiggy 1000, offline 2000"
AI: ✅ സേവ് ചെയ്തു അമ്മേ!
     📱 ഓൺലൈൻ: ₹1,000
     🏪 ഓഫ്‌ലൈൻ: ₹2,000
     ━━━━━━━━━━━━
     💰 മൊത്തം: ₹3,000
```

**Online Income Keywords:**
- `swiggy`, `zomato`, `phonepay`, `phone pay`, `google pay`, `gpay`, `online`
- `ഓൺലൈൻ`, `സ്വിഗ്ഗി`, `സൊമാറ്റോ`

**Offline Income Keywords:**
- `offline`, `direct`, `cash`, `നേരിട്ട്`, `ഓഫ്‌ലൈൻ`, `കാഷ്`

### 2. **Automatic Expense Detection**
The AI will automatically call `add_expense` tool when detecting:

**Examples:**
```
User: "milk 100"
AI: ✅ സേവ് ചെയ്തു! പാൽ: ₹100 - കണക്കിൽ ചേർന്നു! 📝

User: "മീൻ 500"
AI: ✅ സേവ് ചെയ്തു! മീൻ: ₹500 - ചെലവിൽ ചേർത്തു!

User: "meat-800"
AI: ✅ സേവ് ചെയ്തു! മാംസം: ₹800 - കണക്കിൽ ചേർന്നു!

User: "chicken 2kg 600"
AI: ✅ സേവ് ചെയ്തു! ചിക്കൻ: 2kg - ₹600

User: "parotta 50"
AI: ✅ സേവ് ചെയ്തു! പറോട്ട: ₹50
```

**Category Mapping:**
```
Malayalam → English → Database Category
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
മീൻ / fish → fish
മാംസം / meat → meat
chicken / ചിക്കൻ → chicken
പാൽ / milk → milk
parotta / പറോട്ട → parotta
pathiri / പത്തിരി → pathiri
dosa / ദോശ → dosa
appam / അപ്പം → appam
തേങ്ങ / coconut → coconut
പച്ചക്കറി / vegetables → vegetables
rice / അരി → rice
തൊഴിലാളി മനീഷ / labor manisha → labor_manisha
തൊഴിലാളി മിധുൻ / labor midhun → labor_midhun
മറ്റുള്ളവ / others → others
```

## 🎭 Smart Format Detection

### Multi-format Support:
```
✅ "milk-100" (hyphen)
✅ "milk 100" (space)
✅ "milk:100" (colon)
✅ "പാൽ 100" (Malayalam)
✅ "chicken 2kg 600" (with quantity)
✅ "പാൽ 5 liters 200" (Malayalam with quantity)
```

### Mixed Input:
```
User: "swiggy 1500, offline 3000"
AI: Detects both online and offline income
    → Saves: online_income: 1500, offline_income: 3000

User: "fish 800, meat 1200"
AI: Detects multiple expenses
    → Saves both to database
```

## 📊 Response Format

### Income Saved:
```
✅ സേവ് ചെയ്തു അമ്മേ! കൊള്ളാം! 😊

📱 ഓൺലൈൻ: ₹{amount} ചേർത്തു
🏪 ഓഫ്‌ലൈൻ: ₹{amount} ചേർത്തു
━━━━━━━━━━━━━━━━━━━
💰 ഇന്നത്തെ മൊത്തം വരുമാനം: ₹{total}

നല്ല രീതിയിൽ പോകുന്നു! 👏
```

### Expense Saved:
```
✅ സേവ് ചെയ്തു അമ്മേ!

{category in Malayalam}: {quantity} - ₹{amount}

ഇന്നത്തെ മൊത്തം ചെലവ്: ₹{total}
കണക്കിൽ ചേർന്നു! 📝
```

## 🔧 Technical Details

### Tool Functions:
1. **`add_income(online_income, offline_income, meals_sold?, date?)`**
   - Automatically detects online/offline split
   - Updates `daily_data` table
   - Returns success message with totals

2. **`add_expense(category, amount, quantity?, date?)`**
   - Maps Malayalam/English to database category
   - Adds to `expenses` table
   - Updates `daily_data.total_expense`
   - Returns success message with details

### API Flow:
```
User Message
    ↓
Gemini AI (detects intent)
    ↓
Calls add_income/add_expense tool
    ↓
Supabase Database (saves data)
    ↓
Returns success with details
    ↓
AI formats friendly response
    ↓
User sees "സേവ് ചെയ്തു!"
```

## 🎯 Test Cases

### Test Income:
```bash
1. "1000 വരുമാനം" → offline: 1000
2. "phonepay 500" → online: 500
3. "swiggy 1200, offline 800" → online: 1200, offline: 800
4. "google pay 300" → online: 300
5. "cash 2000" → offline: 2000
```

### Test Expense:
```bash
1. "milk 100" → category: milk, amount: 100
2. "മീൻ 500" → category: fish, amount: 500
3. "chicken 2kg 600" → category: chicken, amount: 600, quantity: 2kg
4. "vegetables-300" → category: vegetables, amount: 300
5. "labor manisha 1000" → category: labor_manisha, amount: 1000
```

## ✨ Features

✅ **Natural Language Processing** - Understands casual text
✅ **Malayalam Support** - Full Malayalam category names
✅ **Multiple Formats** - Hyphen, space, colon separators
✅ **Quantity Detection** - Automatically extracts "2kg", "5 liters"
✅ **Smart Categorization** - Maps to correct database categories
✅ **Friendly Responses** - "സേവ് ചെയ്തു!" confirmation
✅ **Total Tracking** - Shows running totals for the day
✅ **Error Handling** - Graceful error messages in Malayalam

## 🚀 Usage

Your mother can now simply text:
- "പാൽ 100" → Milk expense saved
- "swiggy 2000" → Online income saved
- "മീൻ 800" → Fish expense saved
- "offline 5000" → Offline income saved

No need to click buttons or fill forms - just chat naturally! 💬✨
