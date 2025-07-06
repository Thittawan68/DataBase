CREATE OR REPLACE FUNCTION insert_user_info(
    p_name VARCHAR DEFAULT NULL,
    p_hungry_point INT DEFAULT 0,
    p_email_login VARCHAR DEFAULT NULL,
    p_email_contact VARCHAR DEFAULT NULL,
    p_facebook VARCHAR DEFAULT NULL,
    p_phone_number INT DEFAULT NULL,
    p_date_of_birth DATE DEFAULT NULL,
    p_tier VARCHAR DEFAULT 'Red'
)
    RETURNS VOID AS $$
BEGIN
    INSERT INTO user_info (
        name, hungry_point, email_login, email_contact,
        facebook, phone_number, date_of_birth, tier
    )
    VALUES (
       p_name, p_hungry_point, p_email_login, p_email_contact,
       p_facebook, p_phone_number, p_date_of_birth, p_tier
   );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_payment_method(
    p_user_id INT,
    p_card_number INT,
    p_card_type VARCHAR,
    p_card_brand VARCHAR
)
    RETURNS VOID AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM user_info WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'User ID % does not exist.', p_user_id;
    END IF;

    IF EXISTS (SELECT 1 FROM payment_methods WHERE card_number = p_card_number) THEN
        RAISE EXCEPTION 'Card number % already exists.', p_card_number;
    END IF;

    INSERT INTO payment_methods (user_id, card_number, card_type, card_brand)
    VALUES (p_user_id, p_card_number, p_card_type, p_card_brand);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_voucher(
    p_value INT,
    p_description TEXT
)
    RETURNS VOID AS $$
BEGIN
    INSERT INTO voucher (value, voucher_description)
    VALUES (p_value ,p_description);
END;
$$ LANGUAGE plpgsql;

ALTER TABLE voucher
    ADD COLUMN value INT DEFAULT NULL;

CREATE OR REPLACE FUNCTION insert_favorite(
    p_user_id INT,
    p_restaurant_id INT
)
    RETURNS VOID AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM user_info WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'User ID % does not exist.', p_user_id;
    END IF;

    -- You’ll need a restaurant table. Assuming it exists:
    IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = p_restaurant_id) THEN
        RAISE EXCEPTION 'Restaurant ID % does not exist.', p_restaurant_id;
    END IF;

    IF EXISTS (
        SELECT 1 FROM favorite
        WHERE user_id = p_user_id AND restaurant_id = p_restaurant_id
    ) THEN
        RAISE EXCEPTION 'Favorite already exists.';
    END IF;

    INSERT INTO favorite (user_id, restaurant_id)
    VALUES (p_user_id, p_restaurant_id);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_promo_code(
    p_value INT,
    p_restaurant_id INT
)
    RETURNS VOID AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = p_restaurant_id) THEN
        RAISE EXCEPTION 'Restaurant ID % does not exist.', p_restaurant_id;
    END IF;

    INSERT INTO promo_code (value, restaurant_id)
    VALUES (p_value, p_restaurant_id);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_gift_card(
    p_value INT
)
    RETURNS VOID AS $$
BEGIN
    INSERT INTO gift_card (value)
    VALUES (p_value, p_number_hold);
END;
$$ LANGUAGE plpgsql;


-- Function to insert or update user promotion with quantity tracking
CREATE OR REPLACE FUNCTION insert_user_promotion(
    p_user_id INT,
    p_promo_card_type VARCHAR,
    p_promo_card_id INT
)
RETURNS VOID AS $$
BEGIN
    -- Validate user exists
    IF NOT EXISTS (SELECT 1 FROM user_info WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'User ID % does not exist.', p_user_id;
    END IF;
    
    -- Insert new row with quantity 1 or update existing quantity by adding 1
    INSERT INTO user_promotion (user_id, promo_card_type, promo_card_id, quantity)
    VALUES (p_user_id, p_promo_card_type, p_promo_card_id, 1)
    ON CONFLICT (user_id, promo_card_type, promo_card_id) 
    DO UPDATE SET 
        quantity = user_promotion.quantity + 1;
END;
$$ LANGUAGE plpgsql;



-- SELECT insert_payment_method(1001, 1234567890123456, 'Credit', 'Visa');
-- SELECT insert_user_info('John Doe', 100, 'haha@gmail.com');
-- SELECT insert_voucher('2023-10-01', 'Free dessert voucher');
-- SELECT insert_favorite(1001, 2001);
-- SELECT insert_promo_code(1000, 2001);
-- SELECT insert_gift_card(100, 5);



-- ALTER TABLE cuisine
--     ALTER COLUMN cuisine_id ADD GENERATED ALWAYS AS IDENTITY;
-- ALTER TABLE dining_style
--     ALTER COLUMN dining_style_id ADD GENERATED ALWAYS AS IDENTITY;
-- ALTER TABLE gift_card
--     ALTER COLUMN card_id ADD GENERATED ALWAYS AS IDENTITY;
-- ALTER TABLE location
--     ALTER COLUMN location_id ADD GENERATED ALWAYS AS IDENTITY;
-- ALTER TABLE package
--     ALTER COLUMN package_id ADD GENERATED ALWAYS AS IDENTITY;
-- ALTER TABLE promo_code
--     ALTER COLUMN promo_id ADD GENERATED ALWAYS AS IDENTITY;
-- ALTER TABLE restaurant_information
--     ALTER COLUMN restaurant_id ADD GENERATED ALWAYS AS IDENTITY;
-- ALTER TABLE table_reservation
--     ALTER COLUMN table_reservation_id ADD GENERATED ALWAYS AS IDENTITY;
-- ALTER TABLE table_table
--     ALTER COLUMN table_table_id ADD GENERATED ALWAYS AS IDENTITY;
-- ALTER TABLE voucher
--     ALTER COLUMN voucher_id ADD GENERATED ALWAYS AS IDENTITY;