from datetime import datetime, time

from django.db import transaction as db_transaction
from django.db.models import F
from django.utils import timezone

from .models import FixedTransaction, Transaction


def _occurrence_datetime(day):
    """
    Converte a data da ocorrência em datetime com fuso.
    Usa meio-dia para a data não "escorregar" para o dia anterior/seguinte
    caso o fuso do banco (UTC) seja diferente do fuso exibido na tela.
    """
    return timezone.make_aware(datetime.combine(day, time(12, 0)))


def _generate_for_fixed(fixed, today):
    """
    Gera todas as ocorrências vencidas de UMA transação fixa.
    Deve ser chamada dentro de uma transação de banco, com a linha já travada.
    Retorna a quantidade de lançamentos criados.
    """
    new_transactions = []
    next_date = fixed.next_date
    generated = fixed.generated_occurrences

    # while cobre o caso de o usuário ter ficado dias/meses sem acessar:
    # cria os lançamentos atrasados, cada um na sua data correta.
    while next_date <= today and generated < fixed.occurrences:
        new_transactions.append(
            Transaction(
                owner_id=fixed.owner_id,
                title=fixed.title,
                description=fixed.description,
                amount=fixed.amount,
                category=fixed.category,
                type=fixed.type,
                created=_occurrence_datetime(next_date),
            )
        )
        generated += 1
        next_date = fixed.calculate_next_date(next_date)

    if not new_transactions:
        return 0

    Transaction.objects.bulk_create(new_transactions)

    fixed.generated_occurrences = generated
    fixed.next_date = next_date

    # Ao gerar a última ocorrência, a recorrência é encerrada
    if generated >= fixed.occurrences:
        fixed.is_active = False

    fixed.save(update_fields=["generated_occurrences", "next_date", "is_active"])

    return len(new_transactions)


def process_due_fixed_transactions(owner):
    """
    Verifica as transações fixas ativas do usuário e cria os lançamentos
    que já venceram (next_date <= hoje). Chame nas views que precisarem
    dos dados atualizados (dashboard, lista de lançamentos, etc.).

    Retorna o total de lançamentos criados.
    """
    if not getattr(owner, "is_authenticated", False):
        return 0

    today = timezone.localdate()
    created = 0

    with db_transaction.atomic():
        # select_for_update trava as linhas: duas requisições simultâneas
        # não geram o mesmo lançamento duas vezes.
        due = (
            FixedTransaction.objects
            .select_for_update()
            .filter(
                owner=owner,
                is_active=True,
                next_date__lte=today,
                generated_occurrences__lt=F("occurrences"),
            )
        )

        for fixed in due:
            created += _generate_for_fixed(fixed, today)

    return created