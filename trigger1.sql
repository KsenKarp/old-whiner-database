CREATE OR REPLACE FUNCTION trigger_function1()
RETURNS TRIGGER AS
$$
DECLARE
    recipe_id int;
    taste int;
    bad_topping_id int;
	new_topping int;
	impact int;
	pastry_id_ int;
	price_list_id_ int;
	pastry_ingredient int;
	product_ingredient int;
	pastry_amount int;
	recipe_amount int;
	pastry_topping int;
	product_topping int;
BEGIN
    SELECT recipe INTO recipe_id FROM product WHERE product_id = NEW.product;
    taste := 100;
	SELECT topping INTO new_topping FROM toppings_list_for_product WHERE toppings_list_for_product.id = NEW.list_of_toppings;
    FOR bad_topping_id IN SELECT topping_id FROM bad_topping_for_product WHERE recipe = recipe_id
    LOOP
		SELECT impact_on_taste INTO impact FROM bad_topping_for_product WHERE topping_id = bad_topping_id AND recipe = recipe_id;
        IF new_topping = bad_topping_id THEN
            taste := taste - impact;
        END IF;
    END LOOP;
    IF taste <= 50 THEN
        RAISE EXCEPTION 'Taste is too low';
    END IF;

	SELECT price_list INTO price_list_id_ FROM "order" WHERE "order".order_id = NEW.order;
	SELECT pastry INTO pastry_id_ FROM price_list WHERE price_list.price_list_id = price_list_id_;
	--тут надо пройтись по складу кондитерской и проверить наличие необходимых ингредиентов
	--для чего нужно получить два массива: ингредиентов на складе и ингредиентов в рецепте
	FOR pastry_ingredient IN SELECT ingredient_id FROM pastry_ingredients WHERE pastry_ingredients.pastry = pastry_id_
	LOOP
		FOR product_ingredient IN SELECT ingredient_id FROM ingredients_list WHERE ingredients_list.recipe = recipe_id
		LOOP
		--проверить, а есть ли вообще такие ингредиенты в кондитерсокой
			IF NOT EXISTS(SELECT ingredient_id FROM pastry_ingredients WHERE pastry_ingredients.pastry = pastry_id_ 
			AND pastry_ingredients.ingredient_id = product_ingredient) THEN
				RAISE EXCEPTION 'Pastry has no ingredients with id %:', pastry_ingredient;
			END IF;
			
			IF pastry_ingredient = product_ingredient THEN 
			
				SELECT pastry_ingredients.amount INTO pastry_amount FROM pastry_ingredients 
				WHERE pastry_ingredients.pastry = pastry_id_ AND pastry_ingredients.ingredient_id = pastry_ingredient;
				SELECT ingredients_list.amount INTO recipe_amount FROM ingredients_list 
				WHERE ingredients_list.recipe = recipe_id AND ingredients_list.ingredient_id = product_ingredient;
				
				IF pastry_amount < recipe_amount THEN
					RAISE EXCEPTION 'Pastry is out of ingredient with id %:', pastry_ingredient;
				END IF;
			END IF;
			
		END LOOP;
	
	END LOOP;
	
	FOR pastry_ingredient IN SELECT ingredient_id FROM pastry_ingredients WHERE pastry_ingredients.pastry = pastry_id_
	LOOP
		FOR product_ingredient IN SELECT ingredient_id FROM ingredients_list WHERE ingredients_list.recipe = recipe_id
		LOOP
			IF pastry_ingredient = product_ingredient THEN 
			
				SELECT pastry_ingredients.amount INTO pastry_amount FROM pastry_ingredients 
				WHERE pastry_ingredients.pastry = pastry_id_ AND pastry_ingredients.ingredient_id = pastry_ingredient;
				SELECT ingredients_list.amount INTO recipe_amount FROM ingredients_list 
				WHERE ingredients_list.recipe = recipe_id AND ingredients_list.ingredient_id = product_ingredient;
				
				UPDATE pastry_ingredients SET amount = pastry_amount - recipe_amount
				WHERE pastry_ingredients.pastry = pastry_id_ AND pastry_ingredients.ingredient_id = pastry_ingredient;
				
			END IF;
		END LOOP;
	END LOOP;
	
	--аналогичная фигня для топпингов
	
	FOR pastry_topping IN SELECT topping_id FROM pastry_toppings WHERE pastry_toppings.pastry = pastry_id_
	LOOP
		FOR product_topping IN SELECT topping FROM toppings_list_for_product WHERE toppings_list_for_product."id" = NEW.list_of_toppings
		LOOP
			--проверить, а есть ли вообще такие топпинги в кондитерсокой
			IF NOT EXISTS(SELECT topping FROM toppings_list_for_product WHERE toppings_list_for_product."id" = NEW.list_of_toppings 
			AND toppings_list_for_product.topping = product_topping) THEN
				RAISE EXCEPTION 'Pastry has no toppings with id %:', product_topping;
			END IF;
			
			IF pastry_topping = product_topping THEN 
			
				SELECT pastry_toppings.amount INTO pastry_amount FROM pastry_topping 
				WHERE pastry_topping.pastry = pastry_id_ AND pastry_topping.topping_id = topping_id;
				recipe_amount := 1;
				
				IF pastry_amount < recipe_amount THEN
					RAISE EXCEPTION 'Pastry is out of toppings with id %:', topping_id;
				END IF;
			END IF;
		END LOOP;
	END LOOP;
	
	FOR pastry_topping IN SELECT topping_id FROM pastry_toppings WHERE pastry_toppings.pastry = pastry_id_
	LOOP
		FOR product_topping IN SELECT topping FROM toppings_list_for_product WHERE toppings_list_for_product."id" = NEW.list_of_toppings
		LOOP
			IF pastry_ingredient = product_ingredient THEN 
			
				SELECT pastry_toppings.amount INTO pastry_amount FROM pastry_toppings 
				WHERE pastry_toppings.pastry = pastry_id_ AND pastry_toppings.topping_id = topping_id;
				recipe_amount := 1;
				
				UPDATE pastry_toppings SET amount = pastry_amount - recipe_amount
				WHERE pastry_toppings.pastry = pastry_id_ AND pastry_toppings.topping_id = topping_id;
				
			END IF;
		END LOOP;
	END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger1
BEFORE INSERT ON list_of_ordered_products
FOR EACH ROW
EXECUTE FUNCTION trigger_function1();