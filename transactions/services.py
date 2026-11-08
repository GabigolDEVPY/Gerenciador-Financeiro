from .models import Transaction
from django.db.models import Sum, Q, Count, Value, DecimalField
from django.utils import timezone
from dateutil.relativedelta import relativedelta
from django.db.models.functions import Coalesce



class TransactionsService:
    @staticmethod
    def _get_transactions_for_the_month(user=None,queryset=None,start_date=None,end_date=None):

        if queryset is None:
            queryset = user.all_transactions.all()

        return queryset.filter(created__gte=start_date,created__lt=end_date)



    @staticmethod
    def _get_flow_by_category(queryset, total_debit, total_credit):
        percent_category = (queryset.values("category", "type").annotate(total=Sum("amount")).order_by("-total"))
        categories = []

        for category in percent_category:

            monthly_total = (total_credit if category["type"] == "credit"else total_debit)

            percentage = (round((category["total"] / monthly_total) * 100, 2)if monthly_total > 0 else 0)

            categories.append({
                "category": Transaction.Category(category["category"]).label,
                "type": category["type"],
                "total": category["total"],
                "percentage": percentage
            })

        return categories



    @staticmethod
    def get_summary(user):
        now = timezone.localtime()
        start_month = now.replace(day=1,hour=0,minute=0,second=0,microsecond=0)
        decimal_field = DecimalField(max_digits=10, decimal_places=2)
        start_date = (now - relativedelta(months=2)).replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        end_date = now
        all_transactions = TransactionsService._get_transactions_for_the_month(user=user, queryset=None, start_date=start_date, end_date=end_date)
        transactions_this_month = all_transactions.filter(created__gte=start_month)


        last_transactions = transactions_this_month.order_by("-created", "-id")[:7]

        summary = transactions_this_month.aggregate(
            total_credit=Coalesce(Sum("amount", filter=Q(type="credit")), Value(0, output_field=decimal_field)),
            total_debit=Coalesce(Sum("amount", filter=Q(type="debit")), Value(0, output_field=decimal_field)),
            credit_count=Count("id", filter=Q(type="credit")),
            debit_count=Count("id", filter=Q(type="debit"))
        )

        revenue = summary["total_credit"] - summary["total_debit"]

        savings_rate = (
            round((revenue / summary["total_credit"]) * 100, 2)
            if summary["total_credit"] > 0
            else 0
        )


        category_flows = TransactionsService._get_flow_by_category(
            transactions_this_month,
            summary["total_debit"],
            summary["total_credit"]
            )

        return {
            "total_debit": summary["total_debit"],
            "total_credit": summary["total_credit"],
            "credit_count": summary["credit_count"],
            "debit_count": summary["debit_count"],
            "total_revenue": revenue,
            "savings_rate": savings_rate,
            "last_transactions": list(last_transactions.values()),
            "transactions_categories": category_flows
        }
