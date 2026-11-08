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
  static const primary = Color(0xFF00C853);
  static const primaryDark = Color(0xFF00A844);
  static const secondary = Color(0xFF1A237E);
  static const background = Color(0xFFF5F7FA);
  static const card = Color(0xFFFFFFFF);
  static const income = Color(0xFF00C853);
  static const expense = Color(0xFFFF5252);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
}
