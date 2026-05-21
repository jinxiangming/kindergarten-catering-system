-- ============================================
-- 幼儿园餐饮管理系统 - Supabase 初始化 SQL
-- 包含：建表、索引、RLS 策略、初始管理员账户
-- ============================================

-- 1. profiles 表（关联 auth.users，扩展角色字段）
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email VARCHAR(255) NOT NULL,
  display_name VARCHAR(100),
  role VARCHAR(20) NOT NULL CHECK (role IN ('health_doctor', 'kitchen', 'finance', 'principal')),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS profiles_role_idx ON profiles(role);
CREATE INDEX IF NOT EXISTS profiles_email_idx ON profiles(email);

-- 2. recipes 表（食谱主表）
CREATE TABLE IF NOT EXISTS recipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  uploader_id UUID NOT NULL REFERENCES profiles(id),
  week_start_date DATE NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'pending_kitchen', 'pending_finance', 'pending_principal', 'approved', 'rejected_kitchen', 'rejected_finance', 'rejected_principal', 'effective')),
  excel_url TEXT,
  reject_reason TEXT,
  reject_step VARCHAR(30),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS recipes_uploader_id_idx ON recipes(uploader_id);
CREATE INDEX IF NOT EXISTS recipes_status_idx ON recipes(status);
CREATE INDEX IF NOT EXISTS recipes_week_start_date_idx ON recipes(week_start_date);
CREATE INDEX IF NOT EXISTS recipes_created_at_idx ON recipes(created_at);

-- 3. recipe_details 表（食谱明细）
CREATE TABLE IF NOT EXISTS recipe_details (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  meal_type VARCHAR(20) NOT NULL CHECK (meal_type IN ('breakfast', 'morning_snack', 'lunch', 'afternoon_snack', 'dinner')),
  dish_name VARCHAR(200) NOT NULL,
  ingredient VARCHAR(200) NOT NULL,
  amount NUMERIC(10,2) NOT NULL,
  remark TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS recipe_details_recipe_id_idx ON recipe_details(recipe_id);
CREATE INDEX IF NOT EXISTS recipe_details_date_idx ON recipe_details(date);
CREATE INDEX IF NOT EXISTS recipe_details_meal_type_idx ON recipe_details(meal_type);
CREATE INDEX IF NOT EXISTS recipe_details_ingredient_idx ON recipe_details(ingredient);

-- 4. approval_records 表（审核记录）
CREATE TABLE IF NOT EXISTS approval_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  approver_id UUID NOT NULL REFERENCES profiles(id),
  step VARCHAR(30) NOT NULL CHECK (step IN ('kitchen', 'finance', 'principal')),
  result VARCHAR(20) NOT NULL CHECK (result IN ('approved', 'rejected')),
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS approval_records_recipe_id_idx ON approval_records(recipe_id);
CREATE INDEX IF NOT EXISTS approval_records_approver_id_idx ON approval_records(approver_id);
CREATE INDEX IF NOT EXISTS approval_records_step_idx ON approval_records(step);
CREATE INDEX IF NOT EXISTS approval_records_created_at_idx ON approval_records(created_at);

-- 5. purchase_orders 表（采购单）
CREATE TABLE IF NOT EXISTS purchase_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  ingredient VARCHAR(200) NOT NULL,
  total_amount NUMERIC(10,2) NOT NULL,
  unit VARCHAR(20) DEFAULT '克',
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'ordered', 'delivered', 'cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS purchase_orders_recipe_id_idx ON purchase_orders(recipe_id);
CREATE INDEX IF NOT EXISTS purchase_orders_status_idx ON purchase_orders(status);
CREATE INDEX IF NOT EXISTS purchase_orders_ingredient_idx ON purchase_orders(ingredient);

-- 6. daily_tasks 表（每日制作任务）
CREATE TABLE IF NOT EXISTS daily_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  meal_type VARCHAR(20) NOT NULL,
  dish_name VARCHAR(200) NOT NULL,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS daily_tasks_recipe_id_idx ON daily_tasks(recipe_id);
CREATE INDEX IF NOT EXISTS daily_tasks_date_idx ON daily_tasks(date);
CREATE INDEX IF NOT EXISTS daily_tasks_is_completed_idx ON daily_tasks(is_completed);

-- 7. notifications 表（通知）
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type VARCHAR(30) NOT NULL,
  title VARCHAR(200) NOT NULL,
  content TEXT,
  related_id UUID,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS notifications_user_id_idx ON notifications(user_id);
CREATE INDEX IF NOT EXISTS notifications_is_read_idx ON notifications(is_read);
CREATE INDEX IF NOT EXISTS notifications_created_at_idx ON notifications(created_at);

-- ============================================
-- RLS 策略（场景 C：仅登录用户可读写）
-- ============================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE approval_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- profiles: 登录用户可读，只能更新自己的
CREATE POLICY "profiles_登录用户可读" ON profiles
  FOR SELECT USING ((SELECT auth.role()) = 'authenticated');
CREATE POLICY "profiles_用户可更新自己" ON profiles
  FOR UPDATE USING ((SELECT auth.uid()) = id)
  WITH CHECK ((SELECT auth.uid()) = id);
CREATE POLICY "profiles_登录用户可插入" ON profiles
  FOR INSERT WITH CHECK ((SELECT auth.role()) = 'authenticated');

-- recipes: 登录用户可读写
CREATE POLICY "recipes_登录用户可读" ON recipes
  FOR SELECT USING ((SELECT auth.role()) = 'authenticated');
CREATE POLICY "recipes_登录用户可写" ON recipes
  FOR INSERT WITH CHECK ((SELECT auth.role()) = 'authenticated');
CREATE POLICY "recipes_登录用户可更新" ON recipes
  FOR UPDATE USING ((SELECT auth.role()) = 'authenticated')
  WITH CHECK ((SELECT auth.role()) = 'authenticated');

-- recipe_details: 登录用户可读写
CREATE POLICY "recipe_details_登录用户可读" ON recipe_details
  FOR SELECT USING ((SELECT auth.role()) = 'authenticated');
CREATE POLICY "recipe_details_登录用户可写" ON recipe_details
  FOR INSERT WITH CHECK ((SELECT auth.role()) = 'authenticated');
CREATE POLICY "recipe_details_登录用户可更新" ON recipe_details
  FOR UPDATE USING ((SELECT auth.role()) = 'authenticated')
  WITH CHECK ((SELECT auth.role()) = 'authenticated');
CREATE POLICY "recipe_details_登录用户可删除" ON recipe_details
  FOR DELETE USING ((SELECT auth.role()) = 'authenticated');

-- approval_records: 登录用户可读写
CREATE POLICY "approval_records_登录用户可读" ON approval_records
  FOR SELECT USING ((SELECT auth.role()) = 'authenticated');
CREATE POLICY "approval_records_登录用户可写" ON approval_records
  FOR INSERT WITH CHECK ((SELECT auth.role()) = 'authenticated');

-- purchase_orders: 登录用户可读写
CREATE POLICY "purchase_orders_登录用户可读" ON purchase_orders
  FOR SELECT USING ((SELECT auth.role()) = 'authenticated');
CREATE POLICY "purchase_orders_登录用户可写" ON purchase_orders
  FOR INSERT WITH CHECK ((SELECT auth.role()) = 'authenticated');
CREATE POLICY "purchase_orders_登录用户可更新" ON purchase_orders
  FOR UPDATE USING ((SELECT auth.role()) = 'authenticated')
  WITH CHECK ((SELECT auth.role()) = 'authenticated');

-- daily_tasks: 登录用户可读写
CREATE POLICY "daily_tasks_登录用户可读" ON daily_tasks
  FOR SELECT USING ((SELECT auth.role()) = 'authenticated');
CREATE POLICY "daily_tasks_登录用户可写" ON daily_tasks
  FOR INSERT WITH CHECK ((SELECT auth.role()) = 'authenticated');
CREATE POLICY "daily_tasks_登录用户可更新" ON daily_tasks
  FOR UPDATE USING ((SELECT auth.role()) = 'authenticated')
  WITH CHECK ((SELECT auth.role()) = 'authenticated');

-- notifications: 用户只能读写自己的通知
CREATE POLICY "notifications_用户读取自己的" ON notifications
  FOR SELECT USING ((SELECT auth.uid()) = user_id);
CREATE POLICY "notifications_登录用户可写" ON notifications
  FOR INSERT WITH CHECK ((SELECT auth.role()) = 'authenticated');
CREATE POLICY "notifications_用户更新自己的" ON notifications
  FOR UPDATE USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- ============================================
-- 触发器：新用户注册时自动创建 profile
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', SPLIT_PART(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'health_doctor')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- 初始管理员账户（需要通过 Supabase Auth API 创建，此处仅插入 profile）
-- 注意：实际使用时需要先通过 Supabase Dashboard 或 API 创建 auth.users 记录
-- ============================================
