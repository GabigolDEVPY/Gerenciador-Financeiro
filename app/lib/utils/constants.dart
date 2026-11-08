import 'package:flutter/material.dart';

class AppConstants {
  // Altere para o IP da sua máquina se estiver testando em dispositivo físico
  // Emulador Android: 10.0.2.2
  // iOS Simulator / Web / Desktop: 127.0.0.1
  static const String baseUrl = 'http://127.0.0.1:8000';

  static const String loginEndpoint = '/account/api/auth/login/';
  static const String registerEndpoint = '/account/api/auth/register/';
  static const String dashboardEndpoint = '/transactions/api/all';
  static const String transactionsEndpoint = '/transactions/api/transactions/';
  static const String addTransactionEndpoint = '/transactions/api/add';

  static const String tokenKey = 'access_token';
  static const String usernameKey = 'username';
}

class AppColors {
  static const primary = Color(0xFF8B5CF6);
  static const primaryDark = Color(0xFF7C3AED);
  static const secondary = Color(0xFF111827);
  static const background = Color(0xFFF5F5F7);
  static const card = Color(0xFFFFFFFF);
  static const income = Color(0xFF10B981);
  static const expense = Color(0xFFEF4444);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
}
