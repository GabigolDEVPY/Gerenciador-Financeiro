from django.urls import path
from .views import AddTransactionView, ReturnTransactionsSummaryView, TransactionsViewTemplate, ReturnTransactionsView


app_name = "transactions"

urlpatterns = [
    #templates routes
    path("", TransactionsViewTemplate.as_view(), name="home"),

    path("api/transactions/", ReturnTransactionsView.as_view(), name=""),

    #api routes
    path("api/add", AddTransactionView.as_view()),
    path("api/all", ReturnTransactionsSummaryView.as_view())
]
