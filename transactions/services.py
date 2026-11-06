from .models import Transaction
from django.db.models import Sum, Q, Count, CharField, Value, DecimalField
from django.utils import timezone
from dateutil.relativedelta import relativedelta
from django.db.models.functions import Coalesce



class TransactionsService:
    @staticmethod
    def _get_revenue_month(month, year, queryset):
        revenue = queryset.filter(created__month=month, created__year=year
                ).aggregate(total= Sum("amount", filter=Q(type="credit")) - Sum("amount", filter=Q(type="debit")))
        savings_rate = round(100 - revenue["total"]  / 100) if revenue["total"] else 0
        return revenue["total"] or 0, savings_rate or 0

    @staticmethod
    def _get_transactions_for_the_month(user, queryset, start_date, end_date):
        if user:
            queryset = user.all_transactions.all()
        return queryset.filter(created__gte=start_date, created__lt=end_date)

    @staticmethod
    def _get_flow_by_category(queryset, type, monthly_total):
        percent_category = (
            queryset.filter(type=type).values("category")
            .annotate(total=Sum("amount"),type=Value(type, output_field=CharField()))
            .order_by("-total")
            )

        for category in percent_category:
            category["percentage"] = round((category["total"] / monthly_total) * 100, 2)
            category["category"] = Transaction.Category(category["category"]).label

        return percent_category

    @staticmethod
    def get_summary(user):
        now = timezone.localtime(timezone.now())
        decimal_field = DecimalField(max_digits=10, decimal_places=2)
        start_date = (now - relativedelta(months=2)).replace(day=1)
        end_date = now + relativedelta(microseconds=1)
        # retornando as transações dos 2 ultimos vezes
        all_transactions = TransactionsService._get_transactions_for_the_month(user=user, queryset=None, start_date=start_date, end_date=end_date)
        # retornando as transações do mes referente
        transactions_this_month = all_transactions.filter(created__month=now.month)


        last_transactions = transactions_this_month.order_by("-created")[:7]


        summary = transactions_this_month.aggregate(
            total_credit=Coalesce(Sum("amount", filter=Q(type="credit")), Value(0, output_field=decimal_field)),
            total_debit=Coalesce(Sum("amount", filter=Q(type="debit")), Value(0, output_field=decimal_field)),
            credit_count=Count("id", filter=Q(type="credit")),
            debit_count=Count("id", filter=Q(type="debit"))
        )


        percent_debit = TransactionsService._get_flow_by_category(transactions_this_month, "debit", summary["total_debit"])
        percent_credit = TransactionsService._get_flow_by_category(transactions_this_month, "credit", summary["total_credit"])

        transactions_categorys = []

        transactions_categorys.extend(list(percent_debit))
        transactions_categorys.extend(list(percent_credit))

        revenue, savings_rate = TransactionsService._get_revenue_month(now.month, now.year, all_transactions)


        return {
            "total_debit": summary["total_debit"],
            "total_credit": summary["total_credit"],
            "credit_count": summary["credit_count"],
            "debit_count": summary["debit_count"],
            "total_revenue": revenue,
            "savings_rate": savings_rate,
            "last_transactions": list(last_transactions.values()),
            "transactions_categorys": transactions_categorys,
        }
