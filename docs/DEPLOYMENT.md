# 部署说明

## 1. Supabase 初始化

1. 创建 Supabase 项目，区域建议选择靠近用户的地区。
2. 执行 `supabase/schema.sql`。
3. 部署 Edge Functions：

```bash
supabase functions deploy delete-account
supabase functions deploy admin-stats
```

4. 在 Edge Function 设置中为 `delete-account` 配置 `SUPABASE_SERVICE_ROLE_KEY`。

## 2. 第三方登录

### Google

- Supabase Dashboard -> Authentication -> Providers -> Google，填入 OAuth Client ID / Secret。
- Android 配置 SHA-1 指纹到 Google Cloud Console。

### Apple

- Apple Developer 创建 Service ID，配置 `Sign in with Apple`。
- Supabase Dashboard 填入 Team ID、Key ID、Private Key、Service ID。
- iOS 项目启用 Sign in with Apple capability。

## 3. 推送通知

- Android：接入 Firebase Cloud Messaging，客户端注册 Token 到 `push_tokens`。
- iOS：开启 Push Notifications capability，配置 APNs Key。
- 可选用 Supabase 定时任务或 Edge Function 调度每日提醒。

## 4. Android 发布

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=USE_DEMO_DATA=false
```

将 `app-release.apk` 上传到 Google Play Console。上架前建议：

- 配置正式签名密钥
- 更新隐私政策
- 配置数据安全表单

## 5. iOS 发布

在 macOS 上：

```bash
flutter create --platforms=ios --org com.finora --project-name finora .
flutter build ios --release
```

用 Xcode 配置 Team、Bundle ID 后上传 App Store Connect。

## 6. CI

`.github/workflows/build-finora.yml` 会在推送 `main`/`master` 或手动触发时：

- 安装 Flutter stable
- 生成缺失的平台文件
- `flutter analyze`
- `flutter test`
- 构建 release APK
- 上传构建产物

仓库需配置 Secrets：`SUPABASE_URL`、`SUPABASE_ANON_KEY`、`ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`、`ANDROID_KEY_ALIAS`、`ANDROID_KEY_PASSWORD`。
