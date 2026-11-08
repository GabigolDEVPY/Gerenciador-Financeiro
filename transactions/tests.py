
from datetime import datetime
from decimal import Decimal
from unittest.mock import patch

from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone

from transactions.models import Transaction
from transactions.services import TransactionsService


User = get_user_model()


class TransactionsServiceTests(TestCase):

    def setUp(self):
        self.user = User.objects.create_user(
            username="testuser",
            password="test123"
        )

        # Data fixa para os testes não dependerem do dia em que são executados.
        self.now = timezone.make_aware(
            datetime(2026, 11, 8, 12, 0, 0),
            timezone.get_current_timezone()
        )

        self.time_patcher = patch(
            "transactions.services.timezone.localtime",
            return_value=self.now
        )
        self.time_patcher.start()

        # Obtém categorias válidas diretamente do model.
        self.categories = list(Transaction.Category)

    def tearDown(self):
        self.time_patcher.stop()

    def create_transaction(
        self,
        amount,
        transaction_type,
        category,
        created=None
    ):
        return Transaction.objects.create(
            owner=self.user,
            amount=Decimal(str(amount)),
            type=transaction_type,
            category=category,
            created=created or self.now.replace(day=5)
        )

    # 1. Usuário sem nenhuma transação
    def test_user_without_transactions(self):
        summary = TransactionsService.get_summary(self.user)

        self.assertEqual(summary["total_credit"], Decimal("0.00"))
        self.assertEqual(summary["total_debit"], Decimal("0.00"))
        self.assertEqual(summary["total_revenue"], Decimal("0.00"))

        self.assertEqual(summary["credit_count"], 0)
        self.assertEqual(summary["debit_count"], 0)

        self.assertEqual(summary["savings_rate"], 0)
        self.assertEqual(summary["last_transactions"], [])
        self.assertEqual(summary["transactions_categories"], [])

    # 2. Usuário com receitas e sem despesas
    def test_user_with_credit_without_debit(self):
        self.create_transaction(
            amount=1000,
            transaction_type="credit",
            category=self.categories[0].value
        )

        summary = TransactionsService.get_summary(self.user)

        self.assertEqual(summary["total_credit"], Decimal("1000.00"))
        self.assertEqual(summary["total_debit"], Decimal("0.00"))
        self.assertEqual(summary["total_revenue"], Decimal("1000.00"))

        self.assertEqual(summary["credit_count"], 1)
        self.assertEqual(summary["debit_count"], 0)

        self.assertEqual(summary["savings_rate"], 100)

    # 3. Usuário com despesas e sem receitas
    def test_user_with_debit_without_credit(self):
        self.create_transaction(
            amount=400,
            transaction_type="debit",
            category=self.categories[0].value
        )

        summary = TransactionsService.get_summary(self.user)

        self.assertEqual(summary["total_credit"], Decimal("0.00"))
        self.assertEqual(summary["total_debit"], Decimal("400.00"))
        self.assertEqual(summary["total_revenue"], Decimal("-400.00"))

        self.assertEqual(summary["credit_count"], 0)
        self.assertEqual(summary["debit_count"], 1)

        self.assertEqual(summary["savings_rate"], 0)

    # 4. Usuário com saldo negativo
    def test_user_with_negative_revenue(self):
        self.create_transaction(
            amount=100,
            transaction_type="credit",
            category=self.categories[0].value
        )

        self.create_transaction(
            amount=150,
            transaction_type="debit",
            category=self.categories[1].value
        )

        summary = TransactionsService.get_summary(self.user)

        self.assertEqual(summary["total_credit"], Decimal("100.00"))
        self.assertEqual(summary["total_debit"], Decimal("150.00"))
        self.assertEqual(summary["total_revenue"], Decimal("-50.00"))

        self.assertEqual(summary["savings_rate"], -50)

    # 5. Transações em meses diferentes
    def test_transactions_from_different_months(self):
        # Transação de outubro: não deve entrar no resumo de novembro.
        self.create_transaction(
            amount=1000,
            transaction_type="credit",
            category=self.categories[0].value,
            created=self.now.replace(month=10, day=15)
        )

        # Transação de novembro: deve entrar no resumo.
        self.create_transaction(
            amount=300,
            transaction_type="credit",
            category=self.categories[0].value,
            created=self.now.replace(day=5)
        )

        summary = TransactionsService.get_summary(self.user)

        self.assertEqual(summary["total_credit"], Decimal("300.00"))
        self.assertEqual(summary["credit_count"], 1)

    # 6. Percentual por categoria e tipo
    def test_percentage_by_category_and_type(self):
        category_credit_1 = self.categories[0].value
        category_credit_2 = self.categories[1].value
        category_debit_1 = self.categories[2].value
        category_debit_2 = self.categories[3].value

        # Receitas: total de 1000.
        self.create_transaction(
            300, "credit", category_credit_1
        )
        self.create_transaction(
            700, "credit", category_credit_2
        )

        # Despesas: total de 400.
        self.create_transaction(
            100, "debit", category_debit_1
        )
        self.create_transaction(
            300, "debit", category_debit_2
        )

        summary = TransactionsService.get_summary(self.user)

        categories = summary["transactions_categories"]

        # Localiza cada categoria pelo seu nome e tipo.
        results = {
            (item["category"], item["type"]): item
            for item in categories
        }

        label_credit_1 = Transaction.Category(category_credit_1).label
        label_credit_2 = Transaction.Category(category_credit_2).label
        label_debit_1 = Transaction.Category(category_debit_1).label
        label_debit_2 = Transaction.Category(category_debit_2).label

        # Percentuais das receitas.
        self.assertEqual(
            results[(label_credit_1, "credit")]["percentage"],
            30.0
        )

        self.assertEqual(
            results[(label_credit_2, "credit")]["percentage"],
            70.0
        )

        # Percentuais das despesas.
        self.assertEqual(
            results[(label_debit_1, "debit")]["percentage"],
            25.0
        )

        self.assertEqual(
            results[(label_debit_2, "debit")]["percentage"],
            75.0
        )

        self.assertEqual(len(categories), 4)
