# 数据库设计

完整脚本见 `supabase/schema.sql`。以下为表结构概览。

## 核心表

| 表 | 说明 | 关键字段 |
| --- | --- | --- |
| `profiles` | 用户资料 | id、nickname、avatar_url、default_currency、language、is_admin |
| `accounts` | 资金账户 | name、type、balance、icon、color |
| `categories` | 分类 | type、name、icon、color、is_system、user_id（空为系统分类） |
| `transactions` | 收支记录 | type、amount、category_id、account_id、happened_at、note、image_url、external_id |
| `budgets` | 预算 | scope、amount、period、category_id、notify_80、notify_100 |

## 辅助表

| 表 | 说明 |
| --- | --- |
| `push_tokens` | 推送设备 Token |
| `notifications` | 站内通知 |
| `subscriptions` | 会员订阅 |
| `import_batches` | CSV 导入批次 |
| `app_events` | 行为事件 |

## 安全

所有用户数据表启用 RLS：

- 用户只能读写自己的数据。
- 系统分类对所有登录用户只读。
- 用户自定义分类只能由本人修改。
- 头像和账单截图使用 Supabase Storage，路径首段为用户 ID。
- 删除账户通过服务端 Edge Function 完成，避免客户端越权。

## 索引

为账单按用户 + 时间倒序、分类、账户和预算周期建立索引，保证统计页与日历页查询效率。
