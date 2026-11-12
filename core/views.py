from django.views.generic import TemplateView
from django.contrib.auth.mixins import LoginRequiredMixin
from transactions.fixed_transactions_services import process_due_fixed_transactions


class HomeViewTemplate(LoginRequiredMixin, TemplateView):
    template_name = "home.html"

    def dispatch(self, request, *args, **kwargs):
        if request.user.is_authenticated:
            process_due_fixed_transactions(request.user)
        return super().dispatch(request, *args, **kwargs)