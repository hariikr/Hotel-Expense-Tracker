-- ============================================
-- Migration: Create billing tables
-- ============================================

-- bills: stores bill header (customer info, totals, date)
CREATE TABLE IF NOT EXISTS bills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  bill_number TEXT NOT NULL,
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  bill_date DATE NOT NULL DEFAULT CURRENT_DATE,
  subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
  tax_percent DECIMAL(5,2) DEFAULT 0,
  tax_amount DECIMAL(12,2) DEFAULT 0,
  discount DECIMAL(12,2) DEFAULT 0,
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  notes TEXT,
  income_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- bill_items: individual dishes/items on a bill
CREATE TABLE IF NOT EXISTS bill_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id UUID REFERENCES bills(id) ON DELETE CASCADE NOT NULL,
  item_name TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price DECIMAL(12,2) NOT NULL,
  total_price DECIMAL(12,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE bill_items ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can manage own bills" ON bills
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own bill items" ON bill_items
  FOR ALL USING (
    bill_id IN (SELECT id FROM bills WHERE user_id = auth.uid())
  );

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_bills_user_date ON bills(user_id, bill_date DESC);
CREATE INDEX IF NOT EXISTS idx_bills_bill_number ON bills(user_id, bill_number);
CREATE INDEX IF NOT EXISTS idx_bill_items_bill ON bill_items(bill_id);
