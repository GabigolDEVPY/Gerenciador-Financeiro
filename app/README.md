# FinanceApp 💰

App de **finanças pessoais** em Flutter que consome a API local.

## Estrutura do projeto

```
lib/
├── main.dart
├── models/
│   └── transaction.dart
├── providers/
│   ├── auth_provider.dart
│   └── transaction_provider.dart
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart          # Dashboard + bottom nav
│   ├── transactions_screen.dart
│   └── add_transaction_screen.dart
├── services/
│   └── api_service.dart
├── utils/
│   └── constants.dart
└── widgets/
    ├── balance_card.dart
    ├── custom_button.dart
    ├── custom_text_field.dart
    └── transaction_card.dart
```

## Endpoints consumidos

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| POST | `/account/api/auth/login/` | Login |
| POST | `/account/api/auth/register/` | Cadastro |
| GET | `/transactions/api/all` | Dashboard |
| GET | `/transactions/api/transactions/` | Lista de transações |
| POST | `/transactions/api/add` | Adicionar transação |

## Como rodar

1. Certifique-se de que a API está rodando em `http://127.0.0.1:8000`

2. Ajuste a URL base se necessário em `lib/utils/constants.dart`:
   - **Emulador Android**: `http://10.0.2.2:8000`
   - **iOS Simulator / Desktop / Web**: `http://127.0.0.1:8000`
   - **Dispositivo físico**: use o IP da sua máquina na rede (ex: `http://192.168.1.10:8000`)

3. Instale as dependências e rode:

```bash
flutter pub get
flutter run
```

## Funcionalidades

- ✅ Login e registro
- ✅ Dashboard com saldo, entradas e saídas
- ✅ Lista de transações com filtro (todas / entradas / saídas)
- ✅ Adicionar transação (crédito ou débito) com categorias
- ✅ Persistência do token (SharedPreferences)
- ✅ Pull-to-refresh
- ✅ UI moderna com Material 3

## Observações sobre a API

O app tenta ser flexível com o formato de resposta:

- Login: procura `access`, `access_token` ou `token`
- Dashboard: aceita `balance`/`total_balance`, `income`/`total_income`, `expense`/`total_expense` e lista de transações
- Transações: aceita lista direta ou dentro de `results` / `transactions` / `data`

Se a sua API retornar campos diferentes, ajuste em `lib/models/transaction.dart` e `lib/services/api_service.dart`.
