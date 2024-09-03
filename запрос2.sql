SELECT price_list_id, COUNT(DISTINCT product),
SUM(final_cost) AS sum_profit,
TO_CHAR(AVG(CAST(list_of_products_w_price.price - product.price AS numeric)), '99999999.99') AS avg_price_difference_related_to_basic_price,
INTERVAL '1 day' * (price_list.expiration_date -  MAX("order".date_time::date)) AS difference_between_last_order_and_expiration_date
FROM price_list
INNER JOIN list_of_products_w_price ON (list_of_products_w_price.price_list = price_list.price_list_id)
INNER JOIN "order" ON ("order".price_list = price_list.price_list_id)
INNER JOIN product ON ("order".price_list = price_list.price_list_id)
GROUP BY price_list_id