from django.shortcuts import render
from rest_framework import generics
from .serializers import TransactionSerializer
from rest_framework.permissions import IsAuthenticated
from .models import Transaction

# Create your views here.
class AddTransactionView(generics.CreateAPIView):
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated]
    
    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)

class ReturnTransactionsView(generics.ListAPIView):
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Transaction.objects.filter(owner=self.request.user)