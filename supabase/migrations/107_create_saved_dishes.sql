-- ============================================
-- Migration: Create saved_dishes table for dish menu
-- ============================================

CREATE TABLE IF NOT EXISTS saved_dishes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  name TEXT NOT NULL,
  price DECIMAL(12,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, name)
);

ALTER TABLE saved_dishes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own dishes" ON saved_dishes
  FOR ALL USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_saved_dishes_user ON saved_dishes(user_id, name);
