from datetime import datetime, time

from django.db import transaction as db_transaction
from django.utils import timezone

from .models import FixedTransaction, Transaction


def process_fixed_transactions():
    today = timezone.localdate()

    fixed_transactions = FixedTransaction.objects.filter(
        is_active=True,
        next_date__lte=today
    ).values_list("pk", flat=True)

    generated = 0

    for fixed_id in fixed_transactions:

        with db_transaction.atomic():

            fixed = (
                FixedTransaction.objects
                .select_for_update()
                .filter(pk=fixed_id, is_active=True)
                .first()
            )

            if not fixed:
                continue

            while fixed.is_active and fixed.next_date <= today:

                occurrence_date = fixed.next_date

                Transaction.objects.create(
                    owner=fixed.owner,
                    amount=fixed.amount,
                    title=fixed.title,
                    description=fixed.description,
                    category=fixed.category,
                    type=fixed.type,
                    created=timezone.make_aware(
                        datetime.combine(occurrence_date, time.min)
                    )
                )

                fixed.generated_occurrences += 1
                generated += 1

                if fixed.generated_occurrences >= fixed.occurrences:
                    fixed.is_active = False
                    break

                fixed.next_date = fixed.calculate_next_date(
                    occurrence_date
                )

            fixed.save(update_fields=[
                "generated_occurrences",
                "next_date",
                "is_active"
            ])

    return generated