from django.urls import path
from .views import AddTransactionView, ReturnTransactionsSummaryView, HomeViewTemplate


app_name = "transactions"

urlpatterns = [
    #templates routes
    path("home/", HomeViewTemplate.as_view(), name="home"),
    
    #api routes
    path("api/add", AddTransactionView.as_view()),
    path("api/all", ReturnTransactionsSummaryView.as_view())
]
