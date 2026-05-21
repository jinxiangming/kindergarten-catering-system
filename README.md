# 幼儿园餐饮管理系统

基于 Next.js 16 + Supabase + Ant Design 构建的幼儿园餐饮管理Web系统。

## 功能模块

### 四大角色工作台
- **保健医**：上传周食谱Excel、提交审核、查看退回原因并修改重提
- **厨房负责人**：审核食谱可制作性、管理每日制作任务
- **财务人员**：审核采购可行性、管理采购单和入库确认
- **园长**：终审拍板、全流程记录查看、人员管理、数据统计

### 通用功能
- 流程追踪看板：所有角色可见的审核状态和时间线
- 通知提醒：待办任务红点提醒

### 核心流程
```
保健医上传食谱 → 厨房审核可制作性 → 财务审核采购可行性 → 园长终审 → 食谱生效
     ↑                ↑                    ↑                 ↑
     └──────── 任何环节均可退回，从退回点重新审核 ────────┘
```

## 技术栈

- **前端**：Next.js 16 (App Router) + React 19 + TypeScript 5 + Ant Design
- **后端**：Supabase (Auth + Postgres + RLS)
- **Excel处理**：xlsx (SheetJS)
- **部署**：Netlify

## 快速开始

### 1. 配置 Supabase

1. 在 [Supabase](https://supabase.com) 创建免费项目
2. 在 SQL Editor 中执行 `supabase_init.sql` 初始化表结构和RLS策略
3. 在 Authentication > Settings 中：
   - 关闭 "Enable email confirmations"（简化开发流程）
   - 启用 "Enable sign ups"
4. 通过 Supabase Dashboard 创建管理员账户：
   - 邮箱：`admin@kindergarten.com`
   - 密码：`Admin123456`
5. 创建后，在 `profiles` 表中手动设置该用户的 `role` 为 `principal`

### 2. 配置环境变量

复制 `.env.local.example` 为 `.env.local` 并填入你的 Supabase 连接信息：

```bash
cp .env.local.example .env.local
```

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
COZE_SUPABASE_SERVICE_ROLE_KEY=your-service-role-key  # 可选，用于服务端操作
```

### 3. 安装依赖并启动

```bash
pnpm install
pnpm dev
```

访问 http://localhost:3000 即可使用系统。

### 4. 部署到 Netlify

1. 将代码推送到 Git 仓库
2. 在 Netlify 中导入项目
3. 配置环境变量（同上 `.env.local` 中的变量）
4. 构建命令自动识别为 `pnpm run build`
5. 部署完成

## 环境变量说明

| 变量名 | 必填 | 说明 |
|--------|------|------|
| `NEXT_PUBLIC_SUPABASE_URL` | 是 | Supabase 项目 URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | 是 | Supabase 匿名密钥 |
| `COZE_SUPABASE_SERVICE_ROLE_KEY` | 否 | Supabase 服务端密钥（绕过RLS） |

## 数据库表结构

详见 `supabase_init.sql`，包含以下表：

1. `profiles` - 用户资料（关联 auth.users）
2. `recipes` - 食谱主表
3. `recipe_details` - 食谱明细
4. `approval_records` - 审核记录
5. `purchase_orders` - 采购单
6. `daily_tasks` - 每日制作任务
7. `notifications` - 通知

所有表已配置 RLS 策略，确保数据安全。

## 食谱模板格式

Excel 模板字段：

| 日期 | 餐别 | 菜品 | 食材 | 带量克 | 备注 |
|------|------|------|------|--------|------|
| 2024-01-15 | 早餐 | 小米粥 | 小米 | 50 | |
| 2024-01-15 | 早餐 | 小米粥 | 水 | 200 | |

餐别可选值：早餐、早点、午餐、午点、晚餐

## License

MIT
