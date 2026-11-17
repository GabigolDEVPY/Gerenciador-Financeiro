from ..models import Transaction
from django.utils.dateparse import parse_date
from django.db.models import Q

from ..models import FixedTransaction


class ApiTransactionsService:
    @staticmethod
    def add_transaction_view(*, serializer, owner, client_id=None):
        
        if client_id:
            existing = Transaction.objects.filter(
                owner=owner,
                client_id=client_id,
            ).first()
            
            if existing:
                return existing, False
        
        transaction = serializer.save(owner=owner)
        
        return transaction, True
    
    
    
    @staticmethod
    def return_transactions(owner, search, start_date, end_date):
        queryset = Transaction.objects.filter(
            owner=owner
        )
        
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
    
    @staticmethod
    def create_fixed_transaction(client_id, owner, serializer):
        if client_id:
            existing = FixedTransaction.objects.filter(
                owner=owner,
                client_id=client_id,
            ).first()
            
            if existing:
                return existing, False
            
        transaction = serializer.save(owner=owner)

        return transaction, True
