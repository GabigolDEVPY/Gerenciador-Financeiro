from django.db import models
from django.db.models import Q
from django.utils import timezone
from calendar import monthrange
from datetime import timedelta

# Create your models here.
class Transaction(models.Model):
    class Type(models.TextChoices):
        CREDIT = "credit", "CREDIT"
        DEBIT = "debit", "DEBIT"

    class Category(models.TextChoices):
        HOUSING = "housing", "Moradia"
        FOOD = "food", "Alimentação"
        TRANSPORT = "transport", "Transporte"
        HEALTH = "health", "Saúde"
        EDUCATION = "education", "Educação"
        LEISURE = "leisure", "Lazer"
        SHOPPING = "shopping", "Compras"
        TRAVEL = "travel", "Viagem"
        INVESTMENT = "investment", "Investimento"
        DEBT = "debt", "Dívida / Empréstimo"
        TRANSFER = "transfer", "Transferência"
        WORK = "work", "Trabalho / Freelance"
        OTHER = "other", "Outros"

        #revenue
        WORK_WAGE = "work_wage", "Trabalho / Salário"
        FREELANCE = "freelance", "Freelance / Extra"
        INVESTMENT_RETURN = "investment_return", "Retorno de Investimento"
        TRANSFER_RECEIVED = "transfer_received", "Transferências Recebidas"
        OTHER_INCOME = "other_income", "Outras Receitas"

    owner = models.ForeignKey("account.Account", on_delete=models.CASCADE, related_name="all_transactions")
    amount = models.DecimalField(decimal_places=2, max_digits=8, blank=True)
    title = models.CharField(max_length=50, blank=True)
    description = models.CharField(max_length=255, blank=True)
    category = models.CharField(max_length=24, choices=Category.choices)
    type = models.CharField(max_length=6, choices=Type.choices, blank=True)
    created = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ["amount", "type"]
        indexes = [models.Index(fields=["owner", "type"], name="owner_type_idx")]
        constraints = [models.CheckConstraint(condition=Q(amount__gte=0), name="amount_non_negative")]

    def __str__(self):
        return f"account: {self.owner}, amount: {self.amount}"

class FixedTransaction(models.Model):

    class RecurrenceType(models.TextChoices):
        INTERVAL = "interval", "Intervalo de dias"
        MONTHLY = "monthly", "Dia específico do mês"

    owner = models.ForeignKey(
        "account.Account",
        on_delete=models.CASCADE,
        related_name="fixed_transactions"
    )

    title = models.CharField(max_length=50)
    description = models.CharField(max_length=255, blank=True)

    amount = models.DecimalField(max_digits=8, decimal_places=2)

    category = models.CharField(
        max_length=24,
        choices=Transaction.Category.choices
    )

    type = models.CharField(
        max_length=6,
        choices=Transaction.Type.choices
    )

    recurrence_type = models.CharField(
        max_length=10,
        choices=RecurrenceType.choices
    )

    start_date = models.DateField()
    next_date = models.DateField()

    # Recorrência por intervalo
    interval_days = models.PositiveIntegerField(
        null=True,
        blank=True
    )

    # Recorrência por dia do mês
    day_of_month = models.PositiveSmallIntegerField(
        null=True,
        blank=True
    )

    # Quantidade total de lançamentos
    occurrences = models.PositiveIntegerField()

    # Quantidade de lançamentos já gerados
    generated_occurrences = models.PositiveIntegerField(default=0)

    is_active = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["next_date"]
        indexes = [
            models.Index(
                fields=["owner", "is_active", "next_date"],
                name="fixed_transaction_idx"
            )
        ]
        constraints = [
            models.CheckConstraint(
                condition=Q(amount__gt=0),
                name="fixed_amount_positive"
            ),
            models.CheckConstraint(
                condition=Q(occurrences__gt=0),
                name="fixed_occurrences_positive"
            ),
            models.CheckConstraint(
                condition=(
                    Q(
                        recurrence_type="interval",
                        interval_days__gt=0,
                        day_of_month__isnull=True
                    )
                    |
                    Q(
                        recurrence_type="monthly",
                        day_of_month__gte=1,
                        day_of_month__lte=31,
                        interval_days__isnull=True
                    )
                ),
                name="fixed_recurrence_valid"
            )
        ]

    def calculate_next_date(self, current_date):
        if self.recurrence_type == self.RecurrenceType.INTERVAL:
            return current_date + timedelta(days=self.interval_days)

        year = current_date.year
        month = current_date.month + 1

        if month > 12:
            month = 1
            year += 1

        # Trata meses com menos de 31 dias.
        day = min(
            self.day_of_month,
            monthrange(year, month)[1]
        )

        from datetime import date
        return date(year, month, day)

    def __str__(self):
        return f"{self.title} - {self.owner}"
    