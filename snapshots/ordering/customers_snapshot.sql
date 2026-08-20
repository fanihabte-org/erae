{% snapshot customers_snapshot %}

{{
    config(
        unique_key = 'id',
        strategy='timestamp',
        updated_at = 'updated_at',
        hard_deletes='invalidate'
    )

}}

select * from {{ ref('stg_ops_customers') }}

{% endsnapshot %}