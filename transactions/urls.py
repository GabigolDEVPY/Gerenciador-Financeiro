from django.urls import path
from .views import (
    AddTransactionView, ReturnTransactionsSummaryView,
    TransactionsViewTemplate, ReturnTransactionsView, TransactionDetailView,
    CreateFixedTransactionView, ListFixedTransactionView, 
    FixedTransactionDetailView
    )

from django.views.generic import TemplateView

app_name = "transactions"

urlpatterns = [
    #templates routes
    path("", TransactionsViewTemplate.as_view(), name="home"),

    # transactions
    path("api/transactions/", ReturnTransactionsView.as_view(), name=""),
    path("api/transactions/<int:pk>/", TransactionDetailView.as_view(), name="transaction_detail"),
    #api routes
    path("api/add", AddTransactionView.as_view()),
    path("api/all", ReturnTransactionsSummaryView.as_view()),
    
    
    path("fixed-transactions/", TemplateView.as_view(template_name="fixed_transactions.html"),name="fixed_transactions_page",),

    # API Fixed transactions
    path("api/fixed/", ListFixedTransactionView.as_view(), name="list_fixed_transactions"),
    path("api/fixed/create/", CreateFixedTransactionView.as_view(), name="create_fixed_transaction"),
    path("api/fixed/<int:pk>/", FixedTransactionDetailView.as_view(), name="fixed_transaction_detail"),

]
