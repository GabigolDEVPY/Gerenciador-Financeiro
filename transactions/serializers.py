from rest_framework import serializers
from .models import Transaction, FixedTransaction


class TransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transaction
        fields = ["id", "amount", "title", "category","description", "type", "created"]

    read_only_fields = ["id"]




class FixedTransactionSerializer(serializers.ModelSerializer):

    class Meta:
        model = FixedTransaction
        exclude = ["owner", "generated_occurrences", "created_at", "next_date"]
        read_only_fields = ["is_active"]

    def validate(self, attrs):
        recurrence = attrs.get("recurrence_type")

        interval = attrs.get("interval_days")
        day = attrs.get("day_of_month")

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

        return attrs

    def create(self, validated_data):
        validated_data["next_date"] = validated_data["start_date"]

        return FixedTransaction.objects.create(**validated_data)