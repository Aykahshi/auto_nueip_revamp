---
trigger: always_on
globs: *.dart
---

## 命名規範
- 檔案用 `snake_case`，變數/函式用 `camelCase`，布林值用語意化前綴（is/has/can）。
- 常數及 enum 用全大寫並加上 `// ignore: constant_identifier_names`。
- 命名簡潔明確，避免冗長。

## 架構原則
- 採 Clean Architecture（Presentation, Domain, Data），依賴永遠指向內層。
- 每個特徵模組應包含所有三層實作，使用正確抽象（abstract class）。

## 專案結構（特徵優先）
lib/
├── core/ # 共享/通用程式碼
│ ├── config/ # API 設置、LocalStorage Keys
│ ├── extensions/ # 通用擴展 (theme, datetime etc.)
│ ├── network/ # base ApiClient (Dio)、transformer、interceptor、Failure (implements Exception)
│ ├── router/ # Router (Auto Route)
│ ├── theme/ # APP Theme data
│ └── utils/ # 工具函數
├── features/ # 所有應用功能
│ ├── feature_a/ # 單一功能
│ │ ├── data/ # 數據層
│ │ │ ├── models/ # API response DTO
│ │ │ ├── repositories/ # Repository 實現
│ │ │ └── services/ # data source (no matter local/remote)
│ │ ├── domain/ # 領域層
│ │ │ ├── entities/ # 業務對象 (State for Presnter, useful enum)
│ │ │ └── repositories/ # 倉儲介面
│ │ ├── presentation/ # 表現層
│ │ ├── presenter/ # Presenter狀態管理 (usage: FeatureAPresnter extends Presenter<FeatureAState>)
│ │ ├── screens/ # 畫面組件
│ │ └── widgets/ # 特徵專用組件
│ └── feature_b/ # 另一個具有相同結構的功能
├── index.dart # root App widget (處理 ScreenUtil 初始化、AppTheme)
└── main.dart # 入口點

## 依賴注入（使用 Circus）
- 各特徵用獨立檔案註冊依賴，服務用 singleton、臨時對象用 factory。
- `Circus` 使用方式：
  - `hire<T>(T())`：註冊 T 的單例。
  - `hireLazily<T>(() => T())`：懶註冊 T 的單例。
  - `contract<T><T>(() => T())`：以工廠模式註冊 T 的實例。
- 可測試性：介面抽象 + mock-friendly 設計。
```dart
/// register in main.dart if needed
Circus.hire<UserService>(UserService()); // Singleton
Circus.hireLazily<UserService>(()=> UserService()); // Lazy Singleton
Circus.contract<UserService>(()=> UserService()); // Factory
```

## 狀態管理（使用 freezed）
- 聯合類型：初始、加載、成功、錯誤。
- 不變狀態、使用 copyWith（或新實例）、用 `.perform()`/`.focusOn()` 監聽。
- 用 `joker.listen` 處理副作用，保持 Presenter 精簡聚焦。
```dart
@freezed
sealed class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String gender,
    required int age,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) =>
      _$UserFromJson(json);
}
```

## UI 設計
- 使用 `flutter_screenutil: ^6.0.0-alpha.1` 寫法。
- 長、寬、字、角用 `context.w/h/r/sp/i`，正方形用 `context.r`。
- 間距用 `Gap` 或 `spacing`，動畫用 `flutter_animate` 增強 UX。

## 錯誤處理（fpdart）
- 用 `TaskEither<L, R>` 處理 async 錯誤。
- 用 `match()/fold()` 分流成功/失敗處理。
- 強類型失敗（Failure），提升安全與可維護性。
```dart
final class UserService {
  final ApiClient _client;

  UserService({ApiClient? client})
    : _client = client ?? Circus.find<ApiClient>();

  TaskEither<Failure, Response> getUser({
    required String id,
  }) {
    return TaskEither.tryCatch(
      () async => await _client.get(
        APIs.GET_USER,
      ),
      (e, _) => Failure(
        message: e.toString(),
        status: 'failed type',
      ),
    );
  }
}
```

## JokerState 實作與使用
- 使用 `extends Presenter<State>` 搭配 freezed 狀態類型。
```dart
// single state
@freezed
sealed class UserState with _$UserState {
  const factory UserState({
    final User? user,
    @Default(false) final bool isLoading,
    @Default(false) final bool hasError,
    final String? errorMsg,
  }) = _UserState;
}
// union state
@freezed
sealed class UserState with _$UserState {
  const factory UserState.initial() = UserInitial;

  const factory UserState.loading() = UserLoading;

  const factory UserState.loaded({
    required User user,
  }) = UserLoaded;

  const factory UserState.error({
    final String? errorMsg,
  }) = UserError;
}

// UI
final userPresnter = UserPrenster();
// or through CircusRing (must register it in somewhere above)
// example: final userPresnter = Circus.find<UserPrenster>();
return Scaffold(
  body: userPresnter.perform(
    builder: (BuildContext context, UserState state) {
      // --- If UserState is single state ---
      if (state.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state.hasError) {
        return Center(child: Text(state.errorMsg));
      }
      return Center(child: Text(state.user!.name));
      // --- If UserState is union state ---
      return switch (state) {
        UserLoading => const Center(child: CircularProgressIndicator()),
        UserLoaded => Center(child: Text(state.user!.name)),
        UserError => Center(child: Text(state.errorMsg)),
        _ => const SizedBox.shrink(),
      };
    };
  ),
);
```
- 局部變數善用 `Joker<T>`，避免使用 `setState`。
- 事件邏輯與 UI 分離，狀態小而專注。
- 善用 `CueGate` 處理按鈕/API操作邏輯，`CueGate.debounce` 防止重複點擊，`CueGate.throttle` 防止過度請求。
  - 使用方式為 `CueGate.debounce(delay: const Duration(seconds: 1)).trigger((){ someAction() })`。
  - 使用方式為 `CueGate.throttle(interval: const Duration(seconds: 1)).trigger((){ someAction() })`。
  - `StatefulWidget` 可以在 `State` 使用 `CueGateMixin`，並呼叫
    ```dart
    debounceTrigger(
      () => _performSearch(query),
      const Duration(milliseconds: 300),
    );
    throttleTrigger(
      () => _updateScrollPosition(),
      const Duration(milliseconds: 100),
    );
    ```
- `Circus` 註冊 `Joker` 方式：
  - `summon<T>(initialState, tag)`：autoNotify 為 true
  - `recruit<T>(initialState, tag)`：需手動 yell()
  - `spotlight<T>(tag)`：查找 Joker 實例