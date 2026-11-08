from rest_framework import generics
from .serializers import TransactionSerializer
from rest_framework.permissions import IsAuthenticated
from django.views.generic import TemplateView
from rest_framework.response import Response
from .services import TransactionsService
from django.contrib.auth.mixins import LoginRequiredMixin
from rest_framework.pagination import PageNumberPagination
from .models import Transaction

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
        return Transaction.objects.filter(owner=self.request.user).order_by("-created")
