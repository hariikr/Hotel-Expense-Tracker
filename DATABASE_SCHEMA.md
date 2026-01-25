# Database Schema Documentation

## Current Production Schema

The Hotel Expense Tracker uses a clean, multi-tenant database schema with the following tables:

### Core Tables

#### 1. expenses
Multi-user expense tracking with categories.
```sql
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key -> auth.users)
- category_id: UUID (Foreign Key -> expense_categories)
- amount: DECIMAL(12,2)
- date: DATE
- description: TEXT
- quantity: TEXT (optional)
- created_at: TIMESTAMPTZ
- updated_at: TIMESTAMPTZ
```

#### 2. incomes
Multi-user income tracking with categories.
```sql
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key -> auth.users)
- category_id: UUID (Foreign Key -> income_categories)
- amount: DECIMAL(12,2)
- date: DATE
- description: TEXT
- created_at: TIMESTAMPTZ
- updated_at: TIMESTAMPTZ
```

#### 3. expense_categories
User-defined expense categories.
```sql
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key -> auth.users)
- name: TEXT
- created_at: TIMESTAMPTZ
- UNIQUE(user_id, name)
```

#### 4. income_categories
User-defined income categories.
```sql
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key -> auth.users)
- name: TEXT
- created_at: TIMESTAMPTZ
- UNIQUE(user_id, name)
```

### Additional Tables

- **chat_messages**: AI assistant conversation history
- **profiles**: User profile information
- **daily_summary**: Auto-calculated daily profit/loss summaries

## Security

All tables use Row Level Security (RLS) with policies ensuring:
- Users can only view/edit their own data
- User ID is enforced on all operations
- Categories cannot be deleted if in use by transactions

## Indexes

Performance indexes on:
- `expenses(user_id, date DESC)`
- `incomes(user_id, date DESC)`
- `expenses(category_id)`
- `incomes(category_id)`

## Migration History

The schema has been cleaned and optimized. All legacy tables (`expense_old`, `income_old`) have been removed.

Current migrations:
- `001-008`: Initial schema evolution
- `009`: Refactored to category-based dynamic schema
- `100`: Production cleanup (removed old tables)

## Flutter Models

The app uses these models aligned with the schema:
- `ExpenseModel` (lib/features/transactions/models/expense_model.dart)
- `IncomeModel` (lib/features/transactions/models/income_model.dart)
- `CategoryModel` (lib/features/settings/models/category_model.dart)

All models properly map to/from JSON for Supabase operations.
