SELECT product.name, 
       COUNT(DISTINCT CASE
			 WHEN list_of_products_w_price.amount > 0 THEN
			 list_of_products_w_price.price_list END) AS different_price_lists, 
       COUNT(DISTINCT CASE 
                         WHEN price_list.expiration_date <= CURRENT_DATE THEN list_of_products_w_price.price_list 
                       END) AS different_price_lists_not_expired,
		COUNT (DISTINCT bill.bill_id) AS number_of_bills,
		AVG(list_of_products_w_price.price) AS average_cost,
		COUNT (DISTINCT bill.client_name) AS different_clients
FROM product
INNER JOIN list_of_products_w_price ON (product.product_id = list_of_products_w_price.product)
INNER JOIN price_list ON (list_of_products_w_price.price_list = price_list.price_list_id)
INNER JOIN list_of_ordered_products ON (product.product_id = list_of_ordered_products.product)
INNER JOIN "order" ON ("order".order_id = list_of_ordered_products.order)
INNER JOIN bill ON ("order".order_id = bill.order)
GROUP BY product.name