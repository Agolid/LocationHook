# LocationHook

LocationHook - Android位置追踪应用，使用Flutter构建，支持地理围栏和后台位置服务。

## 项目简介

基于Flutter开发的Android位置追踪应用，使用geolocator插件获取高精度位置，支持地理围栏检测和后台位置服务。

## 功能特性

- ✅ 高精度位置追踪（geolocator）
- ✅ 实时位置显示（经度、纬度、精度）
- ✅ 地理围栏功能
  - 创建、删除地理围栏
  - 进出检测
  - 进出计数
- ✅ 后台位置服务（flutter_background_service）
- ✅ 位置变化通知（flutter_local_notifications）
- ✅ 位置历史记录（最近100个位置点）
- ✅ 权限管理（位置权限、通知权限）

## 技术栈

- Flutter 3.16.0
- Dart
- geolocator: ^10.1.0
- permission_handler: ^11.0.1
- flutter_background_service: ^5.0.5
- flutter_local_notifications: ^16.3.0
- shared_preferences: ^2.2.2

## 构建说明

### 前置要求

- Flutter SDK 3.0+
- Android SDK 34
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

✅ 已完成v1.0.0功能

- [x] Flutter项目基础架构
- [x] 高精度位置追踪
- [x] 地理围栏功能
- [x] 后台位置服务
- [x] 通知系统
- [x] 位置历史记录
- [x] 权限管理
- [x] Material Design 3 UI

## 使用说明

1. **首次启动**：应用会请求位置权限和通知权限
2. **开始追踪**：点击"Start Tracking"按钮开始后台位置追踪
3. **添加地理围栏**：点击右上角"+"按钮添加地理围栏
   - 输入围栏名称
   - 设置中心点坐标（纬度、经度）
   - 设置半径（米）
4. **地理围栏检测**：
   - 进入围栏：显示绿色通知，"Entered"计数+1
   - 离开围栏：显示红色通知，"Exited"计数+1
5. **停止追踪**：点击"Stop Tracking"按钮停止后台服务

## 注意事项

- 后台位置追踪需要"Always allow"位置权限
- Android 10+需要精确位置权限才能使用高精度定位
- 通知权限用于显示地理围栏进出提醒
