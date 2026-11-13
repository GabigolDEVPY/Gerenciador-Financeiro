import 'package:flutter/material.dart';

class AppConstants {
  static const String baseUrl = 'https://gabigolbr38.pythonanywhere.com';

  static const String loginEndpoint = '/account/api/auth/login/';
  static const String registerEndpoint = '/account/api/auth/register/';
  static const String dashboardEndpoint = '/transactions/api/all';
  static const String transactionsEndpoint = '/transactions/api/transactions/';
  static const String addTransactionEndpoint = '/transactions/api/add';
  static const String fixedTransactionsEndpoint = '/transactions/api/fixed/';

  static const String tokenKey = 'access_token';
  static const String usernameKey = 'username';
}

class AppColors {
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF6D28D9);
  static const secondary = Color(0xFF2E1065);
  static const background = Color(0xFFF4F3FF);
  static const card = Color(0xFFFFFFFF);
  static const income = Color(0xFF15803D);
  static const expense = Color(0xFFB91C1C);
  static const warning = Color(0xFFD97706);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF64748B);
}
