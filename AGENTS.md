# 项目上下文

## 项目概述
幼儿园餐饮管理系统 - 四角色工作流审批系统，管理食谱从上传到生效的全流程。

### 版本技术栈

- **Framework**: Next.js 16 (App Router)
- **Core**: React 19
- **Language**: TypeScript 5
- **UI 组件**: Ant Design (主色 #52c41a)
- **Styling**: Tailwind CSS 4 + Ant Design
- **Backend**: Supabase (Auth + Postgres + RLS)
- **Excel处理**: xlsx (SheetJS)
- **部署**: Netlify

## 目录结构

```
├── public/                 # 静态资源
├── src/
│   ├── app/                # 页面路由与布局
│   │   ├── (auth)/         # 认证相关页面
│   │   │   └── login/      # 登录页
│   │   ├── (dashboard)/    # 仪表盘布局
│   │   │   ├── health-doctor/  # 保健医工作台
│   │   │   ├── kitchen/        # 厨房负责人工作台
│   │   │   ├── finance/        # 财务工作台
│   │   │   ├── principal/      # 园长工作台
│   │   │   └── tracking/       # 流程追踪看板
│   │   └── api/            # API 路由
│   ├── components/         # 组件
│   │   ├── dashboard/      # 仪表盘布局组件
│   │   ├── ui/             # shadcn/ui 组件（备用）
│   │   └── AuthGuard.tsx   # 认证守卫
│   ├── contexts/           # React Context
│   │   └── AuthContext.tsx  # 认证上下文
│   ├── hooks/              # 自定义 Hooks
│   ├── lib/                # 工具库
│   │   ├── supabase.ts     # Supabase 客户端
│   │   └── utils.ts        # 通用工具
│   └── types/              # TypeScript 类型定义
│       └── index.ts        # 全局类型
├── supabase_init.sql       # 数据库初始化SQL
├── netlify.toml            # Netlify 部署配置
└── README.md               # 项目文档
```

## 包管理规范

**仅允许使用 pnpm** 作为包管理器，**严禁使用 npm 或 yarn**。

## 开发规范

### 编码规范
- TypeScript strict 模式
- 禁止隐式 any
- 字段名使用 snake_case（Supabase 规范）
- 错误处理：所有 Supabase 调用检查 error 并 throw

### 四大角色与权限
- `health_doctor` (保健医)：上传食谱、修改重提
- `kitchen` (厨房负责人)：审核可制作性、管理每日任务
- `finance` (财务人员)：审核采购可行性、管理采购单
- `principal` (园长)：终审拍板、人员管理、数据统计

### 食谱状态流转
```
draft → pending_kitchen → pending_finance → pending_principal → effective
  ↑          ↑                  ↑                  ↑
  └──── rejected_kitchen ←─────┘                  │
  └───────────── rejected_finance ←───────────────┘
  └───────────── rejected_principal ←─────────────┘
```
退回后必须从退回点重新审核，不能跳跃。

### Supabase 集成
- 客户端：使用 `getBrowserClient()` 获取带 session 的客户端
- 服务端：使用 `getSupabaseClient()` 获取 service_role 客户端
- 所有数据操作通过 Supabase SDK 完成
- RLS 策略已配置，notifications 表为用户私有数据

## 关键文件
- `supabase_init.sql` - 完整的数据库初始化脚本
- `src/contexts/AuthContext.tsx` - 认证上下文，提供 signIn/signUp/signOut
- `src/components/dashboard/DashboardLayout.tsx` - 主布局，根据角色显示菜单
- `src/types/index.ts` - 全局类型定义和常量映射
