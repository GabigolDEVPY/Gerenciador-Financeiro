from django.shortcuts import render
from django.views.generic import View


class LoginViewTemplate(View):
    def get(self, request):
        return render(request, "login.html")
    
class RegisterViewTemplate(View):
    def get(self, request):
        return render(request, "register.html")
    
    
    