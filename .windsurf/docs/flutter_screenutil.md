# Flutter ScreenUtil

@knowledge: flutter_screenutil

## 概述
Flutter ScreenUtil 是一個用於處理響應式 UI 設計的套件，特別適合需要根據不同螢幕尺寸進行適應的應用程式。

## 主要功能

### 1. 尺寸適應
- 使用 `context.w`、`context.h`、`context.r`、`context.i`、`context.sp` 進行尺寸適應
- 自動根據設計稿尺寸進行縮放
- 支援像素、字體、圓角等多種尺寸單位

### 2. 初始化
在 `main.dart` 中初始化 ScreenUtil：
```dart
void main() {
  runApp(
    ScreenUtil(
      options: const ScreenUtilOptions(
        designSize: Size(393, 852),
        // ...其他設定
      ),
      child: MaterialApp(
        // ...其他設定
      ),
    ),
  );
}
```

### 3. 使用方式

#### 長度和寬度
```dart
// 使用 context.w/h 進行寬度/高度適應
Container(
  width: context.w(100),  // 設計稿寬度的 100 單位
  height: context.h(50),  // 設計稿高度的 50 單位
)
```

#### 字體大小
```dart
// 使用 context.sp 進行字體大小適應
Text(
  'Hello',
  style: TextStyle(fontSize: context.sp(16)),  // 設計稿字體大小的 16 單位
)
```

#### 圓角半徑
```dart
// 使用 context.r 進行圓角半徑適應
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(context.r(8)),  // 設計稿圓角的 8 單位
  ),
)
```

### 4. 最佳實踐

1. **統一初始化**
   - 在 `main.dart` 中統一初始化 ScreenUtil
   - 設置設計稿尺寸（建議使用 iPhone 8 的尺寸：375x667）

2. **尺寸命名規範**
   - 使用 `snake_case` 命名常數
   - 將常用尺寸定義為常數

3. **適應策略**
   - 根據設計稿尺寸進行等比例縮放
   - 考慮不同螢幕比例的適應
   - 使用 `minTextAdapt` 避免字體過小

### 5. 注意事項

1. **初始化順序**
   - 確保在應用程式入口處初始化 ScreenUtil
   - 避免在未初始化前使用 context.w/h 等方法

2. **性能考量**
   - 避免在列表項或大量重複元件中使用複雜的尺寸計算
   - 使用常數來優化重複使用的尺寸

3. **設計稿尺寸**
   - 建議使用標準手機尺寸（如 iPhone 8：375x667）
   - 考慮不同螢幕比例的適應

## 參考
- [Flutter ScreenUtil 官方文檔](https://pub.dev/packages/flutter_screenutil)
- [GitHub 倉庫](https://github.com/OpenFlutter/flutter_screenutil)

## 版本
當前使用版本：6.0.0-alpha.1

## Tags
- flutter_screenutil
- responsive_design
- ui_design
- screen_adaptation
- flutter_package
