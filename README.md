# Finora

Finora 是一个面向个人用户的财务管理 App，目标形态对标 Money Manager / 钱迹 / Mint。应用采用深色科技金融风格，支持多端登录、云端同步、预算、统计、账单导入和 AI 财务分析。

技术栈：

- Flutter（Material Design 3，深色优先）
- Provider（MVVM 状态管理）
- Supabase（认证、PostgreSQL、Realtime、Storage、Edge Functions）
- fl_chart（统计图表）

## 快速开始

### 演示模式

仓库默认使用演示数据，不需要配置任何后端即可运行：

```bash
flutter pub get
flutter run
```

演示模式内置了示例账户、分类、账单、预算和 AI 洞察。登录页输入任意邮箱和密码即可进入。

### 连接 Supabase

1. 在 [supabase.com](https://supabase.com) 创建项目。
2. 在 SQL Editor 中执行 `supabase/schema.sql`。
3. 部署 Edge Functions：

```bash
cd supabase
supabase functions deploy delete-account
supabase functions deploy admin-stats
```

4. 打开 `Project Settings -> API`，复制 Project URL 和 anon key。
5. 构建或运行时传入配置：

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=USE_DEMO_DATA=false
```

## 构建 Android APK

前置条件：Flutter stable、Android Studio / Android SDK、Java 17。

```bash
flutter create --platforms=android,ios --org com.finora --project-name finora .
flutter pub get
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=USE_DEMO_DATA=false
```

输出文件：`build/app/outputs/flutter-apk/app-release.apk`。

也可以使用仓库内的 `scripts/build_apk.bat` 或 `scripts/build_apk.sh`。

## 构建 iOS

iOS 工程需要在 macOS 上生成：

```bash
flutter create --platforms=ios --org com.finora --project-name finora .
flutter pub get
flutter build ios --release
```

`scripts/generate_ios.ps1` 和 `scripts/generate_ios.sh` 提供一键生成命令。

## 项目结构

```text
lib/
├─ core/          # 主题、配置、常量、格式化、统计引擎
├─ data/          # Supabase 服务、仓库、CSV 解析
├─ domain/        # 用户、账户、分类、账单、预算实体
├─ state/         # 会话、财务数据、主题控制器
└─ ui/            # 登录、首页、日历、统计、账户、账单、预算、导入、AI、我的
supabase/         # 数据库 Schema 与 Edge Functions
docs/             # 架构、数据库、API、部署文档
```

更多细节见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)。
