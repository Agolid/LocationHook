# 贡献指南

感谢您对 LocationHook 项目的兴趣！我们欢迎各种形式的贡献。

## 项目概述

LocationHook 是一个基于 Flutter 开发的 Android 位置追踪应用，提供实时定位、地理围栏和位置历史记录等功能。

## 开发环境

### 必要条件

- Flutter SDK 3.16.0 或更高版本
- Dart SDK
- Android Studio / Android SDK (API 21-33)
- Git

### 环境配置

```bash
# 克隆仓库
git clone https://github.com/Agolid/LocationHook.git
cd LocationHook

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

## 代码规范

### 命名约定

- 文件名：使用 snake_case（如 `location_service.dart`）
- 类名：使用 PascalCase（如 `LocationService`）
- 变量/方法名：使用 camelCase（如 `currentLocation`）
- 常量名：使用 lowerCamelCase（如 `maxAge`）或 SCREAMING_SNAKE_CASE（如 `DEFAULT_TIMEOUT`）

### Flutter/Dart 最佳实践

- 遵循 [Effective Dart](https://dart.dev/guides/language/effective-dart) 指南
- 使用 `flutter_lints` 进行代码检查
- 保持 Widget 分离，避免单个文件过大
- 使用 StatefulWidget 时，合理管理生命周期

### Git 提交规范

使用语义化提交信息（Semantic Commits）：

- `feat:` 新功能
- `fix:` Bug 修复
- `docs:` 文档更新
- `style:` 代码格式（不影响功能）
- `refactor:` 重构
- `test:` 测试相关
- `chore:` 构建/工具链相关

示例：

```
feat: 添加实时位置追踪功能

- 集成 flutter_amap SDK
- 实现位置更新监听器
- 添加位置历史记录（最近100条）
```

## 开发流程

### 分支策略

- `master`: 主分支，稳定版本
- `feature/<feature-name>`: 功能开发分支
- `fix/<issue-name>`: Bug 修复分支

### 工作流程

1. 从 `master` 创建功能分支
   ```bash
   git checkout master
   git pull origin master
   git checkout -b feature/your-feature-name
   ```

2. 开发并提交代码
   ```bash
   git add .
   git commit -m "feat: your feature description"
   ```

3. 推送到远程仓库
   ```bash
   git push origin feature/your-feature-name
   ```

4. 创建 Pull Request（如适用）

## 测试

### 本地测试

```bash
# 运行单元测试
flutter test

# 运行集成测试
flutter test integration_test

# 构建 APK 进行测试
flutter build apk --release
```

### 测试覆盖

- 新功能需要添加对应的单元测试
- 关键逻辑需要添加集成测试
- 测试覆盖率应保持在合理水平

## 发布流程

### 版本号规范

遵循 [语义化版本](https://semver.org/lang/zh-CN/)：
- 主版本号.次版本号.修订号（如 1.0.1）

### 发布步骤

1. 更新版本号（`pubspec.yaml`）
2. 更新 CHANGELOG.md
3. 创建 Git Tag
   ```bash
   git tag -a v1.0.1 -m "Release version 1.0.1"
   git push origin v1.0.1
   ```
4. GitHub Actions 自动构建 APK
5. 发布 GitHub Release

## 问题反馈

- Bug 报告：请提供详细的复现步骤和设备信息
- 功能建议：描述预期功能和使用场景
- 代码问题：提供错误日志和环境信息

## 许可证

本项目采用 MIT 许可证。贡献的代码将遵循相同许可。

## 联系方式

- 项目主页：https://github.com/Agolid/LocationHook
- 问题反馈：https://github.com/Agolid/LocationHook/issues

---

感谢您的贡献！🚀
