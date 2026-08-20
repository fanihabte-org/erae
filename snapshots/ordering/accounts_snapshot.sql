{% snapshot accounts_snapshot %}

{{
    config(
        unique_key = 'id',
        strategy='timestamp',
        updated_at = 'updated_at',
        hard_deletes='invalidate'
    )

}}

select * from {{ ref('stg_crm_accounts') }}

{% endsnapshot %}