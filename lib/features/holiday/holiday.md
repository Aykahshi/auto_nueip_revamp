```mermaid
mindmap
  root((holiday Feature))
    data
      models
        holiday.dart
          假期資料結構
      repositories
        holiday_repository_impl.dart
          假期資料倉儲實作
      services
        holiday_service.dart
          與假期相關 API 溝通
    domain
      entities
        holiday_state.dart
          假期狀態資料結構
      repositories
        holiday_repository.dart
          假期倉儲介面定義
    presentation
      presenters
        holiday_presenter.dart
          假期資料狀態管理與業務邏輯
```
