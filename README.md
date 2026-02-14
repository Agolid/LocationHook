# LocationHook

LocationHook - Android位置追踪应用，使用Flutter构建，支持地理围栏功能。

## 项目简介

基于Flutter开发的Android位置追踪应用，使用geolocator插件获取高精度位置，支持地理围栏检测和后台位置服务。

## 功能特性

- 高精度位置追踪（geolocator）
- 实时位置显示
- 地理围栏功能（开发中）
- 后台位置服务（开发中）
- 位置变化通知（开发中）

## 技术栈

- Flutter
- Dart
- geolocator: ^10.1.0
- permission_handler: ^11.0.1
- flutter_background_service: ^5.0.5
- flutter_local_notifications: ^16.3.0

## 构建说明

### 前置要求

- Flutter SDK 3.0+
- Android SDK
- Java 17

### 本地构建

```bash
cd LocationHook
flutter pub get
flutter build apk
```

### GitHub Actions

项目配置了GitHub Actions自动构建，每次推送到master分支会自动构建APK。

## 开发状态

🚧 项目重构中 - 从Android原生迁移到Flutter

- [x] Flutter项目基础架构
- [x] 基础UI界面
- [x] 位置获取功能
- [ ] 地理围栏功能
- [ ] 后台服务
- [ ] 通知系统
