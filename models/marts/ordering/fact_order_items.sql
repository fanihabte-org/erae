select
    order_item_key
    , order_item_id
    , earliest_order_key
    , product_key
    , quantity
    , line_amount
    , created_at
from {{ ref('inter_order_items') }}