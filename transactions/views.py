from rest_framework import generics, status
from .serializers import TransactionSerializer
from rest_framework.permissions import IsAuthenticated
from django.views.generic import TemplateView
from rest_framework.response import Response
from .services import TransactionsService
from django.contrib.auth.mixins import LoginRequiredMixin
from rest_framework.pagination import PageNumberPagination
from .models import Transaction
from django.utils.dateparse import parse_date
from django.db.models import Q
from rest_framework.generics import CreateAPIView
from rest_framework.permissions import IsAuthenticated
from .serializers import FixedTransactionSerializer
from transactions.fixed_transactions_services import process_due_fixed_transactions
from rest_framework.generics import (
    CreateAPIView,
    ListAPIView,
    RetrieveUpdateDestroyAPIView,
)
from rest_framework.permissions import IsAuthenticated
 
from .models import FixedTransaction
from .serializers import FixedTransactionSerializer





class TransactionsViewTemplate(LoginRequiredMixin, TemplateView):
    template_name = "transactions.html"

    def dispatch(self, request, *args, **kwargs):
        process_due_fixed_transactions(request.user)
        return super().dispatch(request, *args, **kwargs)

class AddTransactionView(generics.CreateAPIView):
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated]

    def create(self, request, *args, **kwargs):
        client_id = request.data.get("client_id")
        if client_id:
            existing = Transaction.objects.filter(
                owner=request.user,
                client_id=client_id,
            ).first()
            if existing:
                return Response(
                    self.get_serializer(existing).data,
                    status=status.HTTP_200_OK,
                )
        return super().create(request, *args, **kwargs)

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class ReturnTransactionsSummaryView(generics.ListAPIView):
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated]

    def get(self, request, *args, **kwargs):
        summary = TransactionsService.get_summary(user=request.user)
        process_due_fixed_transactions(request.user)
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
        process_due_fixed_transactions(self.request.user)
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


class TransactionDetailView(RetrieveUpdateDestroyAPIView):
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Transaction.objects.filter(owner=self.request.user)
    



class OwnedFixedTransactionMixin:
    serializer_class = FixedTransactionSerializer
    permission_classes = [IsAuthenticated]


    def get_queryset(self):
        # Garante que o usuário só enxerga/edita/exclui as próprias
        process_due_fixed_transactions(self.request.user)
        return FixedTransaction.objects.filter(owner=self.request.user)


class ListFixedTransactionView(OwnedFixedTransactionMixin, ListAPIView):
    pagination_class = None  # a tela recebe a lista completa


class CreateFixedTransactionView(OwnedFixedTransactionMixin, CreateAPIView):
    def create(self, request, *args, **kwargs):
        client_id = request.data.get("client_id")
        if client_id:
            existing = FixedTransaction.objects.filter(
                owner=request.user,
                client_id=client_id,
            ).first()
            if existing:
                return Response(
                    self.get_serializer(existing).data,
                    status=status.HTTP_200_OK,
                )
        return super().create(request, *args, **kwargs)

    def perform_create(self, serializer):
        process_due_fixed_transactions(self.request.user)
        serializer.save(owner=self.request.user)


class FixedTransactionDetailView(OwnedFixedTransactionMixin, RetrieveUpdateDestroyAPIView):
    """GET, PUT, PATCH e DELETE de uma transação fixa."""