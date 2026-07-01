import 'package:flutter/foundation.dart';

/// Runtime environment the SDK talks to.
enum WealthSdkEnvironment { sandbox, staging, production }

enum WealthLanguage { english, hindi, marathi }


@immutable
class WealthSdkConfig {
  const WealthSdkConfig({
    required this.apiBaseUrl,
    required this.tenantId,
    this.environment = WealthSdkEnvironment.sandbox,
    this.defaultLanguage = WealthLanguage.english,
    this.connectTimeout = const Duration(seconds: 20),
    this.receiveTimeout = const Duration(seconds: 30),
    this.enableAnalytics = true,
    this.enableVoice = true,
    this.enableAvatar = true,
  }) : assert(apiBaseUrl != '', 'apiBaseUrl must not be empty'),
       assert(tenantId != '', 'tenantId must not be empty');

  final String apiBaseUrl;

  final String tenantId;

  final WealthSdkEnvironment environment;
  final WealthLanguage defaultLanguage;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  final bool enableAnalytics;
  final bool enableVoice;
  final bool enableAvatar;

  WealthSdkConfig copyWith({
    String? apiBaseUrl,
    String? tenantId,
    WealthSdkEnvironment? environment,
    WealthLanguage? defaultLanguage,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    bool? enableAnalytics,
    bool? enableVoice,
    bool? enableAvatar,
  }) {
    return WealthSdkConfig(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      tenantId: tenantId ?? this.tenantId,
      environment: environment ?? this.environment,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      enableVoice: enableVoice ?? this.enableVoice,
      enableAvatar: enableAvatar ?? this.enableAvatar,
    );
  }

  @override
  String toString() =>
      'WealthSdkConfig(tenant: $tenantId, env: ${environment.name}, '
      'base: $apiBaseUrl)';
}
