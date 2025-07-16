# AutoRoute

@knowledge: auto_route

## 概述
AutoRoute 是一個 Flutter 導航包，主要特點包括：
- 強類型參數傳遞
- 簡單的深鏈接
- 代碼生成簡化路由設置

## 安裝與設置

### 1. 添加依賴
在 `pubspec.yaml` 中添加以下依賴：
```yaml
dependencies:
  auto_route: latest

dev_dependencies:
  auto_route_generator: latest
  build_runner: latest
```

### 2. 創建路由配置
```dart
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    // 路由定義
  ];
}
```

## 基本用法

### 1. 定義路由
```dart
@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Home Page')),
    );
  }
}
```

### 2. 配置路由
```dart
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: HomePage.page,
      path: '/',
      initial: true,
    ),
    AutoRoute(
      page: DetailsPage.page,
      path: '/details',
    ),
  ];
}
```

### 3. 導航
```dart
// 推送頁面
context.pushRoute(const DetailsRoute());

// 替換頁面
context.replaceRoute(const DetailsRoute());

// 返回上一頁
context.popRoute();
```

## 進階功能

### 1. 路由守衛
```dart
class AuthGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (isAuthenticated) {
      resolver.next(true);
    } else {
      resolver.redirectUntil(
        LoginRoute(onResult: (success) {
          resolver.next(success);
        }),
      );
    }
  }
}
```

### 2. 路徑參數
```dart
// 定義帶參數的路由
AutoRoute(
  page: ProductPage.page,
  path: '/products/:id',
)

// 使用參數
context.pushRoute(ProductRoute(id: '123'));
```

### 3. 重定向
```dart
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: HomePage.page,
      path: '/',
      initial: true,
    ),
    RedirectRoute(
      path: '/old-path',
      redirectTo: '/',
    ),
  ];
}
```

### 4. 壓縮路由
```dart
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: HomePage.page,
      path: '/',
      initial: true,
    ),
    AutoRoute(
      page: DetailsPage.page,
      path: '/details',
      guards: [AuthGuard()],
    ),
  ];
}
```

## 最佳實踐

1. **使用命名路由**
   ```dart
   @RoutePage()
   class HomePage extends StatelessWidget {
     const HomePage({super.key});
   }
   ```

2. **使用路由守衛**
   ```dart
   class AuthGuard extends AutoRouteGuard {
     @override
     void onNavigation(NavigationResolver resolver, StackRouter router) {
       if (isAuthenticated) {
         resolver.next(true);
       } else {
         resolver.redirectUntil(
           LoginRoute(onResult: (success) => resolver.next(success)),
         );
       }
     }
   }
   ```

3. **使用路徑參數**
   ```dart
   AutoRoute(
     page: ProductPage.page,
     path: '/products/:id',
   )
   ```

## 版本遷移

### 從 v8 到 v9
1. 將 `RootStackRouter` 作為基類
   ```dart
   @AutoRouterConfig()
   class AppRouter extends RootStackRouter {
     // ...
   }
   ```

2. 移除 `@RoutePage<RETURN_TYPE>()`
   ```dart
   bool didLogin = await context.pushRoute<bool>();
   ```

3. 使用 `AutoRouteGuard` 列表
   ```dart
   @AutoRouterConfig()
   class AppRouter extends RootStackRouter {
     final authGuard = AuthGuard();
     
     @override
     late final List<AutoRouteGuard> guards = [
       authGuard,
     ];
   }
   ```

4. 移除 `AutoRouterConfig.module`
   ```dart
   @AutoRouterConfig()
   class MyMicroRouter extends RootStackRouter {}
   ```

## 參考
- [AutoRoute 官方文檔](https://github.com/Milad-Akarie/auto_route_library/blob/master/README.md)
- [遷移指南](https://github.com/Milad-Akarie/auto_route_library/blob/master/migrations/migrating_to_v9.md)

## Tags
- auto_route
- flutter_navigation
- code_generation
- route_guard
- deep_linking
