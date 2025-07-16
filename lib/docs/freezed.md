# Freezed

@knowledge: freezed

## 概述
Freezed 是一個用於 Dart/Flutter 的代碼生成工具，主要用於創建不可變數據類和聯合類型（Union Types）。它能自動生成以下代碼：
- `toString`
- `operator ==`
- `hashCode`
- `copyWith`
- JSON 序列化/反序列化
- 聯合類型的模式匹配

## 安裝與設置

### 1. 添加依賴
在 `pubspec.yaml` 中添加以下依賴：
```yaml
dependencies:
  freezed_annotation: latest
  json_annotation: latest

dev_dependencies:
  build_runner: latest
  freezed: latest
  json_serializable: latest
```

### 2. 初始化生成器
在需要使用 Freezed 的文件中添加：
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'your_file.freezed.dart';
```

### 3. 運行生成器
```bash
dart run build_runner build --delete-conflicting-outputs
```

## 基本用法

### 1. 單一構造函數
```dart
@freezed
sealed class Person with _$Person {
  const factory Person({
    required String firstName,
    required String lastName,
    required int age,
  }) = _Person;

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);
}
```

### 2. 多個構造函數（聯合類型）
```dart
@freezed
sealed class Result with _$Result {
  const factory Result.success(String data) = Success;
  const factory Result.error(String message) = Error;
  const factory Result.loading() = Loading;
}
```

## 關鍵特性

### 1. 不可變性
Freezed 生成的類都是不可變的（immutable），確保數據安全性。

### 2. copyWith
自動生成 `copyWith` 方法，方便創建新實例：
```dart
final person = Person(
  firstName: 'John',
  lastName: 'Doe',
  age: 30,
);

final updated = person.copyWith(
  age: 31,
);
```

### 3. JSON 序列化
自動生成 `fromJson` 和 `toJson` 方法：
```dart
final person = Person.fromJson({
  'firstName': 'John',
  'lastName': 'Doe',
  'age': 30,
});

final json = person.toJson();
```

### 4. 聯合類型
支持多個構造函數，用於表示不同狀態：
```dart
@freezed
sealed class Result with _$Result {
  const factory Result.success(String data) = Success;
  const factory Result.error(String message) = Error;
  const factory Result.loading() = Loading;
}
```

## 模式匹配
Freezed 支持 Dart 的模式匹配語法：

```dart
switch (result) {
  Success(:final data) => print('Success: $data'),
  Error(:final message) => print('Error: $message'),
  Loading() => print('Loading...'),
}
```

## 配置選項

### 1. 更改生成行為
可以在類級別配置 Freezed 的行為：
```dart
@Freezed(
  equal: false, // 禁用 == 操作符
  hashCode: false, // 禁用 hashCode
  copyWith: false, // 禁用 copyWith
)
class Person with _$Person {
  // ...
}
```

### 2. 全局配置
可以在 `pubspec.yaml` 中配置全局設置：
```yaml
freezed:
  generate_for:
    - '**/*.dart'
  generate_when:
    - '**/*.dart'
```

## 最佳實踐

1. **使用 sealed 關鍵字**
   ```dart
   @freezed
   sealed class Person with _$Person {
     // ...
   }
   ```

2. **使用 const factory**
   ```dart
   const factory Person({
     required String firstName,
     required String lastName,
     required int age,
   }) = _Person;
   ```

3. **使用模式匹配**
   ```dart
   switch (result) {
     Success(:final data) => print('Success: $data'),
     Error(:final message) => print('Error: $message'),
     Loading() => print('Loading...'),
   }
   ```

## 版本遷移

### 從 v2 到 v3
1. 添加 `sealed` 或 `abstract` 關鍵字
   ```dart
   @freezed
   sealed class Person with _$Person {
     // ...
   }
   ```

2. 使用 Dart 模式匹配替代 `.map`/`.when`
   ```dart
   switch (model) {
     First(:final a) => 'first $a',
     Second(:final b, :final c) => 'second $b $c',
   }
   ```

## 參考
- [Freezed 官方文檔](https://github.com/rrousselGit/freezed/blob/master/packages/freezed/README.md)
- [遷移指南](https://github.com/rrousselGit/freezed/blob/master/packages/freezed/migration_guide.md)

## Tags
- freezed
- immutable
- union_types
- pattern_matching
- code_generation
- flutter_package
