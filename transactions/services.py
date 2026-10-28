from .models import Transaction
from decimal import Decimal
from django.db.models import Sum, Q


class TransactionsService:
    @staticmethod
    def get_summary(user):
        all_transactions = user.all_transactions.all()
        transactions = all_transactions.aggregate(
            total_credit=Sum("amount", filter=Q(type="credit")),
            total_debit=Sum("amount", filter=Q(type="debit"))
        )
        total_debit = transactions["total_debit"] or 0
        total_credit = transactions["total_credit"] or 0
        
        
        return {
            "total_debit": total_debit,
            "total_credit": total_credit,
            "total_revenue": total_credit - total_debit,
            "transactions": list(all_transactions.values())
        }