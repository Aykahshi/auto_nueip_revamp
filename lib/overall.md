# 全域架構概覽
```mermaid
mindmap
  root((lib))
    index.dart
      ROOT APP，初始化 APP 頂層項目（ScreenUtil, Theme, MaterialApp.router）
    main.dart
      APP 進入口，統一依賴註冊與初始化（Circus, LocalStorage, NotificationUtils...）
    core
      config
      extensions
      network
      router
      theme
      utils
    features
      nueip
        (所有 presenter 資料來源)
      login
        presenter
          --> nueip
      home
        presenter
          --> nueip
      form
        presenter
          --> nueip
      setting
        presenter
          --> nueip
      calendar
        presenter
          --> nueip
      holiday
        presenter
          (獨立，不依賴 nueip)    
```

```mermaid
mindmap
  pubspec.yaml
      state
        joker_state
      network
        dio
        html
        cookie_jar
        pretty_dio_logger
        dio_cookie_manager
        cached_network_image
      UI
        flutter_screenutil
        gap
        google_fonts
        flutter_animate
        dropdown_button2
        salomon_bottom_bar
        animated_flip_counter
        syncfusion_flutter_calendar
        flutter_staggered_animations
        syncfusion_flutter_datepicker
      utils
        intl
        fpdart
        geocoding
        photo_view
        collection
        auto_route
        url_launcher
        json_annotation
        permission_handler
        freezed_annotation
        shared_preferences
        file_picker
      form
        flutter_form_builder
        form_builder_validators
      notification
        flutter_local_notifications
      background
        flutter_background_service
      dev_dependencies
        flutter_test
        flutter_lints
        flutter_launcher_icons
        flutter_native_splash
        auto_route_generator
        build_runner
        freezed
        json_serializable
      assets
        assets/icons/
        assets/images/
      splash
        flutter_native_splash
      icon
        flutter_launcher_icons
```

---

## 進度說明

- **目前進度**：除了 `hidden` 功能模組尚未完善，其餘 feature 皆已完成架構繪製。
- **特別提醒**：`home` 模組目前缺少公告區塊，`lib/features/home/data/models/announcement.dart` 尚未被實際串接或使用。
- 若需補足公告區塊串接或進行 hidden 模組設計，請再進一步指示。
