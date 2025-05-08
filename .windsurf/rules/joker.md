---
trigger: glob
globs: *.dart
---

# 🎪 Joker State 函式庫總結

## 📚 概述

Joker State 是一套為 Flutter 應用程式設計的全方位狀態管理解決方案，包含五大核心模組：狀態管理、依賴注入、事件總線、特殊元件和計時控制。其設計理念是提供簡潔、直覺且高效的 API，讓開發者能輕鬆建立可維護的應用程式。

## 🎭 核心模組

### 1. 狀態管理

狀態管理模組提供了兩種主要容器：

#### Joker

最基本的狀態容器，用於管理任何型別的狀態：

```dart
// 建立一個簡單的計數器
final counterJoker = Joker<int>(0);

// 更新狀態 (自動通知)
counterJoker.trick(42);                       // 直接賦值
counterJoker.trickWith((state) => state + 1); // 用函數轉換
await counterJoker.trickAsync(fetchValue);    // 非同步更新

// 手動通知機制
counterJoker.whisper(42);                     // 只改值不通知
counterJoker.whisperWith((s) => s + 1);       // 靜默轉換
counterJoker.yell();                          // 需要時再通知
```

#### Presenter

建立在 Joker 之上，加入了生命週期管理，適合 BLoC 等架構：

```dart
class CounterPresenter extends Presenter<int> {
  CounterPresenter() : super(0);

  void increment() => trickWith((s) => s + 1);

  // 若為帶有 `copyWith` 的 State
  void update() => trick(state.copyWith(...));

  @override 
  void onInit() { 
    super.onInit();
    print('Presenter initialized!'); 
  }

  @override 
  void onDone() {
    print('Presenter cleaned up!'); 
    super.onDone();
  }
}
```

#### 小部件整合
```dart
// 觀察整個狀態
counterJoker.perform(
  builder: (context, count) => Text('計數: $count'),
);

// 只觀察一部分 (避免不必要重建)
userPresenter.focusOn<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('姓名: $name'),
);

// 組合多個狀態
typedef UserProfile = (String name,

JokerTroupe<UserProfile>(
  jokers: [nameJoker, ageJoker, activeJoker],
  converter: (values) => (values[0] as String, values[1] as int, values[2] as bool),
  builder: (context, profile) {
    final (name, age, active) = profile;
    return ListTile(title: Text(name), subtitle: Text('$age'));
  },
);

// 也可以使用擴展
final jokers = [nameJoker, ageJoker, activeJoker];

jokers.assemble<UserProfile>(
  converter: (values) => (values[0] as String, values[1] as int, values[2] as bool),
  builder: (context, profile) {
    final (name, age, active) = profile;
    return ListTile(title: Text(name), subtitle: Text('$age'));
  },
);
```

#### 注入 widget tree，透過 context 存取
```dart
// 在頂部提供 Joker
JokerPortal<int>(
  tag: 'counter',
  joker: counterJoker,
  child: MaterialApp(...),
)

// 在任何地方存取
JokerCast<int>(
  tag: 'counter',
  builder: (context, count) => Text('計數: $count'),
)

// 或使用擴展
context.joker<int>(tag: 'counter').state
```

### 2. 依賴注入 (CircusRing)

CircusRing 是輕量級的依賴注入容器，管理應用程式中的物件和生命週期：

```dart
// 註冊單例
Circus.hire<UserRepository>(UserRepositoryImpl());

// 使用標籤區分同類型多實例
Circus.hire<ApiClient>(ProductionApiClient(), tag: 'prod');
Circus.hire<ApiClient>(MockApiClient(), tag: 'test');

// 懶加載單例
Circus.hireLazily<Database>(() => Database.connect());

// 非同步單例
Circus.hireLazilyAsync<NetworkService>(() async => await NetworkService.initialize());

// 工廠模式 (每次都新建)
Circus.contract<UserModel>(() => UserModel());

// 建立依賴
Circus.bindDependency<UserRepository, ApiService>();
```

#### 整合狀態管理
```dart
// 註冊 Joker
Circus.summon<int>(0, tag: 'counter'); // 僅限 Joker 可使用

// 註冊 Presenter
Circus.hire<MyPresenter>(MyPresenter(initialState), tag: 'myTag');

// 存取已註冊的實例
final counter = Circus.spotlight<int>(tag: 'counter'); // 僅限 Joker 可使用
final presenter = Circus.find<MyPresenter>(tag: 'myTag');
```

#### 釋放資源
```dart
Circus.fire<UserRepository>();
// 移除並銷毀 (如果 keepAlive 為 false)
Circus.vanish<int>(tag: 'counter');
await Circus.fireAsync<NetworkService>();
```

#### 事件總線

無需直接依賴關係，讓應用程式不同部分互相溝通：
```dart
// 定義事件
class UserLoggedInEvent {
  final String userId;
  final String username;
  UserLoggedInEvent(this.userId, this.username);
}

// 監聽事件
Circus.onCue<UserLoggedInEvent>((event) {
  print('使用者已登入: ${event.username}');
});

// 發送事件
Circus.cue(UserLoggedInEvent('123', 'john_doe'));
```

### 4. 特殊元件

#### JokerReveal

根據布林值條件顯示不同小部件：
```dart
// 直接給元件
JokerReveal(
  condition: isLoggedIn,
  whenTrue: ProfileScreen(),
  whenFalse: LoginScreen(),
)

// 懶加載
JokerReveal.lazy(
  condition: isLoading,
  whenTrueBuilder: (context) => LoadingIndicator(),
  whenFalseBuilder: (context) => ContentView(),
)

// 或用擴展方法
isLoggedIn.reveal(
  whenTrue: ProfileScreen(),
  whenFalse: LoginScreen(),
)
```

#### JokerTrap

小部件從樹上移除時，自動幫你釋放控制器：
```dart
// 一個控制器
textController.trapeze(
  TextField(controller: textController),
)

// 多個控制器
[textController, scrollController, animationController].trapeze(
  ComplexWidget(),
)
```

### 5. 計時控制 (CueGate)

防抖動、節流等時間控制工具：
```dart
// 防抖動
final debounced = CueGate.debounce(
  duration: const Duration(seconds: 1),
  builder: (context) => MyWidget(),
);

// 節流
final throttled = CueGate.throttle(
  duration: const Duration(seconds: 1),
  builder: (context) => MyWidget(),
);
```

#### CueGateMixin

StatefulWidget 可使用 mixin：
```dart
class _MyScreenState extends State<MyScreen> with CueGateMixin {
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (text) {
        debounceTrigger(() {
          // 搜尋邏輯
        }, Duration(milliseconds: 300));
      },
    );
  }
}
```

### 🚀 最佳實踐

#### 狀態管理
- 適當選擇容器類型：
  - 簡單狀態用 Joker
  - 複雜邏輯用 Presenter
- 儘可能使用焦點監聽：
  - 用 focusOn 而非 perform 減少不必要重建
- 謹慎處理批次更新：
  - 多個關聯變更用 batch() 合併通知
- 正確使用通知方法：
  - 需要 UI 更新用 trick
  - 內部狀態變更用 whisper，然後在適當時機 yell

#### 依賴注入
- 標籤命名一致：
  - 同一資源使用一致的標籤命名規則
- 明確依賴關係：
  - 使用 bindDependency 清楚標示依賴關係
- 合理設定 keepAlive：
  - 長壽命元件設為 true
  - 平時元件預設 false
- 優先使用懶加載：
  - 高成本資源用 hireLazily 延遲初始化
- 適時釋放資源：
  - 不再需要時主動呼叫 fire 或 vanish

#### 事件總線
- 事件定義明確：
  - 每個事件類別專注一個領域或功能
- 使用命名空間：
  - 不同領域用不同事件總線，避免混亂
- 避免循環觸發：
  - 防止事件互相無限觸發的循環

#### 計時控制
- 根據場景選擇模式：
  - 輸入即搜尋用 debounce
  - 限制點擊頻率用 throttle
- 資源管理：
  - 使用 dispose 釋放計時器，或用 CueGateMixin
- 適當的時間間隔：
  - 去抖動 300ms~500ms 較合適
  - 節流視場景調整，一般 200ms~1s

#### 整體建議
- 模組化設計：
  - 每個頁面/功能區域用獨立的 Presenter
  - 共用狀態透過 CircusRing 管理
- 生命週期管理：
  - 利用 Presenter 的生命週期鉤子管理資源
  - 使用 JokerTrap 自動釋放控制器
- 測試友好：
  - 邏輯集中在 Presenter，便於單元測試
  - 透過依賴注入容器易於模擬元件
- 效能優化：
  - 善用 focusOn 和 JokerFrame 減少重建
  - 大量數據用 CueGate 控制更新頻率
- 錯誤處理：
  - 在 trickAsync 中妥善處理非同步錯誤
  - 使用 tryFind 安全查找依賴