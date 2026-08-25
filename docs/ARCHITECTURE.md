# Finora 架构设计

## 分层

应用采用 MVVM + 分层仓库架构：

- `ui`：页面与组件，只消费 `state` 中的控制器。
- `state`：`ChangeNotifier` 控制器，负责加载、变更和通知。
- `domain`：领域实体（用户、账户、分类、账单、预算）。
- `data`：仓库接口、Supabase 数据源、演示数据源、CSV 解析。
- `core`：主题、配置、日期/金额格式化、统计引擎。

页面不直接访问 Supabase，全部通过 `FinanceRepository` / `AuthRepository` 抽象访问，方便后续替换数据源或增加本地离线库。

## 状态管理

使用 Provider：

- `SessionController`：登录态、用户资料、密码、注销、删除账户。
- `FinanceController`：账户、分类、账单、预算的加载与增删改。
- `ThemeController`：主题模式。

所有列表变更后立即更新 UI，并异步写入仓库。

## 数据流

```text
UI -> Controller -> Repository -> Supabase / Demo Data
```

当 `USE_DEMO_DATA=true` 或 Supabase 未配置时，自动使用演示仓库；配置正确后使用 Supabase 仓库。

## 分阶段实施

- 阶段 1：UI 与页面结构（当前完成，含演示数据）
- 阶段 2：用户系统（邮箱注册登录已完成，Google/Apple 已预留）
- 阶段 3：数据库与 RLS（Schema 已提供）
- 阶段 4：记账功能（已完成）
- 阶段 5：日历（已完成）
- 阶段 6：统计（已完成）
- 阶段 7：微信/支付宝 CSV 导入（已完成）
- 阶段 8：AI 助手（本地洞察已完成，云端模型预留）
- 阶段 9：性能与推送（可继续迭代）

## 商业化预留

- `subscriptions` 表支持免费版 / Pro。
- `app_events` 表记录行为事件，供运营分析。
- Edge Functions 可作为后续 AI、导出、报表的后端入口。
