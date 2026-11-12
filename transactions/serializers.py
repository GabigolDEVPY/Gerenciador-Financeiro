from rest_framework import serializers
from .models import Transaction, FixedTransaction


class TransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transaction
        fields = [
            "id",
            "client_id",
            "amount",
            "title",
            "category",
            "description",
            "type",
            "created",
        ]

    read_only_fields = ["id"]




class FixedTransactionSerializer(serializers.ModelSerializer):

    class Meta:
        model = FixedTransaction
        # next_date e generated_occurrences são devolvidos (a tela usa),
        # mas continuam somente leitura. is_active é editável.
        exclude = ["owner"]
        read_only_fields = [
            "generated_occurrences",
            "created_at",
            "next_date",
        ]

    def validate(self, attrs):
        instance = self.instance

        # Em PATCH, campos ausentes vêm da instância existente
        def get(field):
            if field in attrs:
                return attrs[field]
            return getattr(instance, field, None)

        # --- Recorrência ---
        recurrence = get("recurrence_type")
        interval = get("interval_days")
        day = get("day_of_month")

        if recurrence == FixedTransaction.RecurrenceType.INTERVAL:
            if not interval or interval < 1:
                raise serializers.ValidationError({
                    "interval_days": "Informe um intervalo válido."
                })
            attrs["day_of_month"] = None

        elif recurrence == FixedTransaction.RecurrenceType.MONTHLY:
            if not day or not 1 <= day <= 31:
                raise serializers.ValidationError({
                    "day_of_month": "Informe um dia entre 1 e 31."
                })
            attrs["interval_days"] = None

        # --- Categoria compatível com o tipo ---
        type_ = get("type")
        category = get("category")

        if type_ and category:
            allowed = Transaction.CATEGORIES_BY_TYPE.get(type_, [])
            if category not in allowed:
                raise serializers.ValidationError({
                    "category": "Categoria incompatível com o tipo de transação."
                })

        # --- Não permite reduzir abaixo do que já foi gerado ---
        occurrences = get("occurrences")
        if instance and occurrences is not None:
            if occurrences < instance.generated_occurrences:
                raise serializers.ValidationError({
                    "occurrences": (
                        f"Já foram gerados {instance.generated_occurrences} "
                        "lançamentos. Informe um valor igual ou maior."
                    )
                })

        return attrs

    def create(self, validated_data):
        validated_data["next_date"] = validated_data["start_date"]
        return FixedTransaction.objects.create(**validated_data)

    def update(self, instance, validated_data):
        new_start = validated_data.get("start_date")

        if instance.generated_occurrences > 0:
            # Já gerou lançamentos: a data inicial não pode mais mudar
            validated_data.pop("start_date", None)
        elif new_start:
            # Nada gerado ainda: o próximo lançamento acompanha a nova data
            validated_data["next_date"] = new_start

        return super().update(instance, validated_data)