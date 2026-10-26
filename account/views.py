from django.shortcuts import render
from django.views.generic import View
from django.contrib.auth import login, authenticate, logout
from django.contrib.auth.views import LoginView
from django.shortcuts import redirect


class LoginViewTemplate(LoginView):
    template_name = "login.html"
    redirect_authenticated_user = True
    
    
class RegisterViewTemplate(View):
    def get(self, request):
        return render(request, "register.html")
    
class LogoutView(View):
    def get(self, request):
        logout(request)
        return redirect("account:login")


    

    
    