# API 设计

客户端通过 Supabase SDK 直接访问数据库，并配合 Edge Functions 处理需要服务端权限或第三方能力的场景。

## 认证

Supabase Auth 提供：

- 邮箱密码注册 / 登录 / 重置密码
- Google OAuth
- Apple OAuth
- 会话恢复与退出

手机号注册可后续接入 Supabase Phone Auth。

## 数据接口

| 资源 | 方法 | 路径 | 说明 |
| --- | --- | --- | --- |
| 账户 | GET | `/rest/v1/accounts?user_id=eq.X` | 我的账户 |
| 账户 | POST | `/rest/v1/accounts` | 新建账户 |
| 账户 | PATCH | `/rest/v1/accounts?id=eq.X` | 编辑账户 |
| 分类 | GET | `/rest/v1/categories` | 系统 + 我的分类 |
| 账单 | GET | `/rest/v1/transactions?user_id=eq.X` | 我的账单，支持时间/搜索筛选 |
| 账单 | POST | `/rest/v1/transactions` | 新增账单 |
| 账单 | PATCH | `/rest/v1/transactions?id=eq.X` | 编辑账单 |
| 预算 | GET/POST/PATCH | `/rest/v1/budgets` | 预算管理 |

所有接口由 RLS 控制，客户端使用 anon key 即可。

## Realtime

订阅 `transactions` 表的 `INSERT/UPDATE/DELETE` 变更，实现多设备自动同步。

## Edge Functions

| 函数 | 说明 |
| --- | --- |
| `delete-account` | 服务端删除 Auth 用户并级联清理数据 |
| `admin-stats` | 管理员统计：用户数、活跃用户、新增注册、系统状态 |
| `ai-insights` | 预留：调用大模型生成消费分析和建议 |
| `generate-monthly-report` | 预留：生成月度财务总结并推送 |

## 推送

客户端注册 FCM / APNs Token 到 `push_tokens`，服务端按用户偏好触发每日记账提醒、预算提醒和月度总结。
