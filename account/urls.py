from django.urls import path
from rest_framework_simplejwt.views import (TokenObtainPairView, TokenRefreshView)
from .views import RegisterViewTemplate, LoginViewTemplate
from .api_views import AccountRegisterView

app_name = "account"

urlpatterns = [
    # page routes
    path("login/", LoginViewTemplate.as_view(), name="login"),
    path("register/", RegisterViewTemplate.as_view(), name="register"),
    
    # api routes
    path("api/auth/register/", AccountRegisterView.as_view()),
    path("api/auth/login/", TokenObtainPairView.as_view()),
    path("api/auth/refresh/", TokenRefreshView.as_view())
]
