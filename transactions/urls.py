from django.urls import path
from .views import AddTransactionView, ReturnTransactionsView

urlpatterns = [
    path("api/add", AddTransactionView.as_view()),
    path("api/all", ReturnTransactionsView.as_view())
]
