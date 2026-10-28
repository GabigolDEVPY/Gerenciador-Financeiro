from rest_framework import generics
from .serializers import TransactionSerializer
from rest_framework.permissions import IsAuthenticated
from django.views.generic import TemplateView
from rest_framework.response import Response
from .services import TransactionsService

class TransactionsViewTemplate(TemplateView):
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