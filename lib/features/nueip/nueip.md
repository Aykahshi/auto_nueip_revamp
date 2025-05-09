```mermaid
mindmap
  root((nueip Feature))
    data
      models
        user_sn.dart
          使用者序號資料結構
      repositories
        nueip_repository_impl.dart
          NUEiP 資料倉儲實作
      services
        nueip_services.dart
          與 NUEiP 相關 API 溝通（所有 feature 資料根基，處理最底層 API 交互）（所有 feature 資料根基，處理最底層 API 交互）
    domain
      repositories
        nueip_repository.dart
          NUEiP 倉儲介面定義