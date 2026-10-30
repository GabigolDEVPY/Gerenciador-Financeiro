from .models import Transaction
from decimal import Decimal
from django.db.models import Sum, Q, Count
from django.utils import timezone

now = timezone.now()

class TransactionsService:
    @staticmethod
    def get_summary(user):
        all_transactions = user.all_transactions.all().filter(created__month=now.month, created__year=now.year)
        last_transactions = all_transactions.order_by("-created")[:7]
        
        transactions = all_transactions.aggregate(
            total_credit=Sum("amount", filter=Q(type="credit")),
            total_debit=Sum("amount", filter=Q(type="debit")),
            credit_count=Count("id", filter=Q(type="credit")),
            debit_count=Count("id", filter=Q(type="debit"))
        )
        total_debit = transactions["total_debit"] or 0
        total_credit = transactions["total_credit"] or 0
        total_revenue = total_credit - total_debit,
        savings_rate = 100 - (total_debit / (total_credit  / 100)) if total_debit and total_credit else 0
        
        
        return {
            "total_debit": transactions["total_debit"] or 0,
            "total_credit": transactions["total_credit"] or 0,
            "total_revenue": total_revenue,
            "credit_count": transactions["credit_count"] or 0,
            "debit_count": transactions["debit_count"] or 0,
            "savings_rate": savings_rate,
            "last_transactions": list(last_transactions.values())
        }