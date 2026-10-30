from django.db import models
from django.db.models import Q
from django.utils import timezone

# Create your models here.
class Transaction(models.Model):
    class Type(models.TextChoices):
        CREDIT = "credit", "CREDIT"
        DEBIT = "debit", "DEBIT"

    
    owner = models.ForeignKey("account.Account", on_delete=models.CASCADE, related_name="all_transactions")
    amount = models.DecimalField(decimal_places=2, max_digits=8, blank=True)
    title = models.CharField(max_length=50, blank=True)
    description = models.CharField(max_length=255, blank=True)
    type = models.CharField(max_length=6, choices=Type.choices, blank=True)
    created = models.DateTimeField(default=timezone.now)
    
    class Meta:
        ordering = ["amount", "type"]
        indexes = [models.Index(fields=["owner", "type"], name="owner_type_idx")]
        constraints = [models.CheckConstraint(condition=Q(amount__gte=0), name="amount_non_negative")]
    
    def __str__(self):
        return f"account: {self.owner}, amount: {self.amount}"