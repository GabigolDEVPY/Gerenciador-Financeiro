from rest_framework import generics
from rest_framework.permissions import AllowAny
from .serializers import AccountRegisterSerializer

class AccountRegisterView(generics.CreateAPIView):
    serializer_class = AccountRegisterSerializer
    permission_classes = [AllowAny]