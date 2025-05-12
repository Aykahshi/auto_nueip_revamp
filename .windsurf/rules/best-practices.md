---
trigger: always_on
globs: *.dart
---

# 最佳實例規範

## 命名規範
- 檔案用 `snake_case`，變數/函式用 `camelCase`，布林值用語意化前綴（is/has/can）。
- 常數及 enum 用全大寫並加上 `// ignore: constant_identifier_names`。
- 命名簡潔明確，避免冗長。

## 架構原則
- 採 Clean Architecture（Presentation, Domain, Data），依賴永遠指向內層。
- 每個特徵模組應包含所有三層實作，使用正確抽象（abstract class）。

## 專案結構（特徵優先）
```
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
```

## 依賴注入（使用 Circus）
- 各特徵用獨立檔案註冊依賴，服務用 singleton、臨時對象用 factory。
- `Circus` 使用方式：
  - `hire<T>(T())`：註冊 T 的單例。
  - `hireLazily<T>(() => T())`：懶註冊 T 的單例。
  - `contract<T><T>(() => T())`：以工廠模式註冊 T 的實例。
- 可測試性：介面抽象 + mock-friendly 設計。

## 狀態管理（使用 freezed）
- 聯合類型：初始、加載、成功、錯誤。
- 不變狀態、使用 copyWith（或新實例）、用 `.perform()`/`.focusOn()` 監聽。
- 用 `joker.listen` 處理副作用，保持 Presenter 精簡聚焦。

## UI 設計
- 參考 [flutter_screenutil](https://pub.dev/packages/flutter_screenutil/versions/6.0.0-alpha.1) 官方文件寫法。
- 長、寬、字、角用 `context.w/h/i/sp`，正方形用 `context.r`。
- 間距用 `Gap` 或 `spacing`，動畫用 `flutter_animate` 增強 UX。
- 使用 `context.vw`, `context.vh` 代替 `MediaQuery.of(context).size.width`, `MediaQuery.of(context).size.height`。

## 錯誤處理（fpdart）
- 用 `TaskEither<L, R>` 處理 async 錯誤。
- 用 `match()/fold()` 分流成功/失敗處理。
- 強類型失敗（Failure），提升安全與可維護性。

## JokerState 實作與使用
- 使用 `extends Presenter<State>` 搭配 freezed 狀態類型。
- 局部變數善用 `Joker<T>`，避免使用 `setState`。
- 事件邏輯與 UI 分離，狀態小而專注。
- 善用 `CueGate` 處理按鈕/API操作邏輯，`CueGate.debounce` 防止重複點擊，`CueGate.throttle` 防止過度請求。
- 若需要 `Joker` 跨組件使用，考慮兩種方式：
  - `Circus` 註冊 `Joker` 方式，`Circus.spotlight<T>(tag: 'uniqueTag')`, `Circus.summon<int>(0 , tag: 'uniqueTag')` etc.
  - 利用 `JokerPortal` 把 `Joker` 實例注入 Widget Tree，並透過 `JokerCast`, `context.joker` 獲取。