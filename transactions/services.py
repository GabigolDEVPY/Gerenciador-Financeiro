from .models import Transaction
from decimal import Decimal
from django.db.models import Sum, Q


class TransactionsService:
    @staticmethod
    def get_summary(user):
        transactions = user.all_transactions.all().aggregate(
            total_credit=Sum("amount", filter=Q(type="credit")),
            total_debit=Sum("amount", filter=Q(type="debit"))
        )
        
        
        return {
            "total_debit": transactions["total_debit"] or 0,
            "total_credit": transactions["total_credit"] or 0
        }