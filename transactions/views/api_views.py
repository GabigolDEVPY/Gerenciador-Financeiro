from rest_framework import generics
from ..serializers import TransactionSerializer
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from ..services.summary_services import TransactionsService
from rest_framework.pagination import PageNumberPagination
from ..models import Transaction
from ..serializers import FixedTransactionSerializer
from transactions.services.fixed_transactions_services import process_due_fixed_transactions
from rest_framework.generics import (
    CreateAPIView,
    ListAPIView,
    RetrieveUpdateDestroyAPIView,
)
from ..models import FixedTransaction
from transactions.services.api_services import ApiTransactionsService



class AddTransactionView(generics.CreateAPIView):
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        transaction, created = ApiTransactionsService.add_transaction_view(
            client_id=request.data.get("client_id"),
            serializer=serializer,
            owner=request.user,
        )
        data = self.get_serializer(transaction).data
        return Response(data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)



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
        params = self.request.query_params
        queryset = ApiTransactionsService.return_transactions(
            owner=self.request.user, 
            search=params.get("search"), 
            start_date=params.get("start_date"), 
            end_date=params.get("end_date")
            )
        
        return queryset
        


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
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        transaction, created = ApiTransactionsService.create_fixed_transaction(client_id, request.user, serializer)
        data = self.get_serializer(transaction).data
        return Response(data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)



class FixedTransactionDetailView(OwnedFixedTransactionMixin, RetrieveUpdateDestroyAPIView):
    """GET, PUT, PATCH e DELETE de uma transação fixa."""