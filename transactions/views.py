from rest_framework import generics
from .serializers import TransactionSerializer
from rest_framework.permissions import IsAuthenticated
from django.views.generic import TemplateView
from rest_framework.response import Response
from .services import TransactionsService
from django.contrib.auth.mixins import LoginRequiredMixin
from rest_framework.pagination import PageNumberPagination
from .models import Transaction
from django.utils.dateparse import parse_date
from django.db.models import Sum, Q, Count, Value, DecimalField
    
from rest_framework.generics import CreateAPIView
from rest_framework.permissions import IsAuthenticated

from .models import FixedTransaction
from .serializers import FixedTransactionSerializer
from .fixed_transactions_services import process_fixed_transactions




class TransactionsViewTemplate(LoginRequiredMixin, TemplateView):
    template_name = "transactions.html"


class AddTransactionView(generics.CreateAPIView):
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class ReturnTransactionsSummaryView(generics.ListAPIView):
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated]

    def get(self, request, *args, **kwargs):
        summary = TransactionsService.get_summary(user=request.user)
        return Response(summary)



class TransactionPagination(PageNumberPagination):
    page_size = 5
    page_size_query_param = "page_size"
    max_page_size = 1000


class ReturnTransactionsView(generics.ListAPIView):
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = TransactionPagination

    def get_queryset(self):
        queryset = Transaction.objects.filter(
            owner=self.request.user
        )

        params = self.request.query_params

        search = params.get("search")
        start_date = params.get("start_date")
        end_date = params.get("end_date")

        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) |
                Q(description__icontains=search)
            )

        if start_date:
            date = parse_date(start_date)
            if date:
                queryset = queryset.filter(created__date__gte=date)

        if end_date:
            date = parse_date(end_date)
            if date:
                queryset = queryset.filter(created__date__lte=date)

        return queryset.order_by("-created", "-id")
    



class CreateFixedTransactionView(CreateAPIView):

    serializer_class = FixedTransactionSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)