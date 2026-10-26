from django.contrib import admin
from .models import Transaction

# Register your models here.
@admin.register(Transaction)
class TransanctionAdmin(admin.ModelAdmin):
    list_display = "owner", "amount", "created"