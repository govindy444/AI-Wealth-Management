/// IDBI Wealth AI SDK — plug-and-play AI wealth advisor for digital banking.
///
/// Public API surface. Host apps import this single library:
/// ```dart
/// import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
/// ```
library;

// Entry point
export 'src/wealth_sdk.dart';

// Core — configuration
export 'src/core/config/wealth_sdk_config.dart';

// Core — dependency injection graph
export 'src/core/di/sdk_providers.dart';

// Core — error handling & result types
export 'src/core/error/failures.dart';
export 'src/core/error/exceptions.dart';
export 'src/core/utils/result.dart';
export 'src/core/utils/use_case.dart';

// Core — cross-cutting domain contracts
export 'src/core/domain/explainability.dart';

// Core — logging
export 'src/core/logging/sdk_logger.dart';

// Core — network abstractions
export 'src/core/network/api_client.dart';
export 'src/core/network/api_request.dart';
export 'src/core/network/api_response.dart';
export 'src/core/network/http_method.dart';
export 'src/core/network/token_provider.dart';

// Core — storage abstractions
export 'src/core/storage/key_value_store.dart';
export 'src/core/storage/secure_store.dart';

// Storage — platform-backed impls + DI
export 'src/storage/shared_preferences_key_value_store.dart';
export 'src/storage/flutter_secure_storage_secure_store.dart';
export 'src/storage/storage_providers.dart';

// Networking — production Dio client + DI
export 'src/network/dio_api_client.dart';
export 'src/network/network_providers.dart';

// Core — data-layer helpers
export 'src/core/data/base_repository.dart';

// Profile & Settings
export 'src/profile/profile_providers.dart';
export 'src/profile/domain/entities/user_profile.dart';
export 'src/profile/domain/repositories/profile_repository.dart';
export 'src/profile/domain/usecases/profile_usecases.dart';
export 'src/profile/presentation/state/profile_state.dart';
export 'src/profile/presentation/state/profile_controller.dart';

// Notifications
export 'src/notifications/notifications_providers.dart';
export 'src/notifications/domain/entities/app_notification.dart';
export 'src/notifications/domain/repositories/notification_repository.dart'
    show NotificationRepository, NotificationsPage;
export 'src/notifications/domain/usecases/notification_usecases.dart';
export 'src/notifications/presentation/state/notifications_state.dart';
export 'src/notifications/presentation/state/notifications_controller.dart';

// Fraud Detection
export 'src/fraud/fraud_providers.dart';
export 'src/fraud/domain/entities/fraud_alert.dart';
export 'src/fraud/domain/entities/fraud_reports.dart';
export 'src/fraud/domain/repositories/fraud_repository.dart';
export 'src/fraud/domain/usecases/fraud_usecases.dart';
export 'src/fraud/presentation/state/fraud_state.dart';
export 'src/fraud/presentation/state/fraud_controller.dart';

// Predictive Banking
export 'src/predictive/predictive_providers.dart';
export 'src/predictive/domain/entities/prediction.dart';
export 'src/predictive/domain/entities/forecast.dart';
export 'src/predictive/domain/repositories/predictive_repository.dart';
export 'src/predictive/domain/usecases/get_forecast_usecase.dart';
export 'src/predictive/presentation/state/predictive_state.dart';
export 'src/predictive/presentation/state/predictive_controller.dart';

// Portfolio Intelligence
export 'src/portfolio/portfolio_providers.dart';
export 'src/portfolio/domain/entities/holding.dart';
export 'src/portfolio/domain/entities/portfolio_summary.dart';
export 'src/portfolio/domain/repositories/portfolio_repository.dart';
export 'src/portfolio/domain/usecases/portfolio_usecases.dart';
export 'src/portfolio/presentation/state/portfolio_state.dart';
export 'src/portfolio/presentation/state/portfolio_controller.dart';

// Investment Recommendations
export 'src/recommendations/recommendations_providers.dart';
export 'src/recommendations/domain/entities/investment_product.dart';
export 'src/recommendations/domain/entities/recommendation.dart';
export 'src/recommendations/domain/repositories/recommendation_repository.dart';
export 'src/recommendations/domain/usecases/recommendation_usecases.dart';
export 'src/recommendations/presentation/state/recommendations_state.dart';
export 'src/recommendations/presentation/state/recommendations_controller.dart';

// Goal Planner
export 'src/goals/goals_providers.dart';
export 'src/goals/domain/entities/goal.dart';
export 'src/goals/domain/entities/goal_simulation.dart';
export 'src/goals/domain/repositories/goal_repository.dart';
export 'src/goals/domain/usecases/goal_usecases.dart';
export 'src/goals/presentation/state/goals_state.dart';
export 'src/goals/presentation/state/goals_controller.dart';

// Financial Health Engine
export 'src/financial_health/financial_health_providers.dart';
export 'src/financial_health/domain/entities/health_pillar.dart';
export 'src/financial_health/domain/entities/financial_health.dart';
export 'src/financial_health/domain/repositories/financial_health_repository.dart';
export 'src/financial_health/domain/usecases/get_health_score_usecase.dart';
export 'src/financial_health/presentation/state/financial_health_state.dart';
export 'src/financial_health/presentation/state/financial_health_controller.dart';

// Spending Analytics
export 'src/spending/spending_providers.dart';
export 'src/spending/domain/entities/transaction.dart';
export 'src/spending/domain/entities/spending_summary.dart';
export 'src/spending/domain/entities/budget.dart';
export 'src/spending/domain/repositories/spending_repository.dart';
export 'src/spending/domain/usecases/spending_usecases.dart';
export 'src/spending/presentation/state/spending_state.dart';
export 'src/spending/presentation/state/spending_controller.dart';

// Voice Assistant
export 'src/voice/voice_providers.dart';
export 'src/voice/domain/entities/voice_config.dart';
export 'src/voice/domain/entities/voice_turn.dart';
export 'src/voice/domain/repositories/voice_repository.dart';
export 'src/voice/domain/services/speech_services.dart';
export 'src/voice/domain/usecases/voice_usecases.dart';
export 'src/voice/presentation/state/voice_state.dart';
export 'src/voice/presentation/state/voice_controller.dart';

// AI Avatar
export 'src/avatar/avatar_providers.dart';
export 'src/avatar/domain/entities/avatar_persona.dart';
export 'src/avatar/domain/entities/avatar_presentation.dart';
export 'src/avatar/domain/repositories/avatar_repository.dart';
export 'src/avatar/domain/usecases/avatar_usecases.dart';
export 'src/avatar/presentation/state/avatar_state.dart';
export 'src/avatar/presentation/state/avatar_controller.dart';

// AI Chat
export 'src/chat/chat_providers.dart';
export 'src/chat/domain/entities/chat_message.dart';
export 'src/chat/domain/entities/conversation.dart';
export 'src/chat/domain/repositories/chat_repository.dart';
export 'src/chat/domain/usecases/chat_usecases.dart';
export 'src/chat/presentation/state/chat_state.dart';
export 'src/chat/presentation/state/chat_controller.dart';

// Dashboard
export 'src/dashboard/dashboard_providers.dart';
export 'src/dashboard/domain/entities/account.dart';
export 'src/dashboard/domain/entities/dashboard_summary.dart';
export 'src/dashboard/domain/repositories/dashboard_repository.dart';
export 'src/dashboard/domain/usecases/get_dashboard_usecase.dart';
export 'src/dashboard/presentation/state/dashboard_state.dart';
export 'src/dashboard/presentation/state/dashboard_controller.dart';

// Authentication
export 'src/auth/auth_providers.dart';
export 'src/auth/domain/entities/auth_user.dart';
export 'src/auth/domain/entities/auth_session.dart';
export 'src/auth/domain/repositories/auth_repository.dart';
export 'src/auth/domain/usecases/login_usecase.dart';
export 'src/auth/domain/usecases/register_usecase.dart';
export 'src/auth/domain/usecases/session_usecases.dart';
export 'src/auth/presentation/state/auth_state.dart';
export 'src/auth/presentation/state/auth_controller.dart';
