CREATE FUNCTION public.get_user_gift_cards(p_user_id integer) RETURNS TABLE(card_id integer, value integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- 1) Validate that the user exists
    IF NOT EXISTS (
        SELECT 1
          FROM user_info
         WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'Invalid user_id: %', p_user_id;
    END IF;

    -- 2) Return all gift-card details for that user
    RETURN QUERY
    SELECT
        gc.card_id,
        gc."value"
      FROM user_promotion up
      JOIN gift_card gc
        ON gc.card_id = up.promo_card_id
     WHERE up.user_id = p_user_id
       AND LOWER(up.promo_card_type) = 'gift_card';
END;
$$;

CREATE FUNCTION public.get_user_promo_codes(p_user_id integer) RETURNS TABLE(promo_id integer, value integer, restaurant_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- 1) Validate that the user exists
    IF NOT EXISTS (
        SELECT 1
          FROM user_info
         WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'Invalid user_id: %', p_user_id;
    END IF;

    -- 2) Return all promo‐code details for that user
    RETURN QUERY
    SELECT
        pc.promo_id,
        pc."value",
        pc.restaurant_id
      FROM user_promotion up
      JOIN promo_code pc
        ON pc.promo_id = up.promo_card_id
     WHERE up.user_id = p_user_id
       AND LOWER(up.promo_card_type) = 'promo_code';
END;
$$;

CREATE FUNCTION public.get_user_vouchers(p_user_id integer) RETURNS TABLE(voucher_id integer, voucher_description text, value integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- 1) Validate that the user exists
    IF NOT EXISTS (
        SELECT 1
          FROM user_info
         WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'Invalid user_id: %', p_user_id;
    END IF;

    -- 2) Return all voucher details for that user
    RETURN QUERY
    SELECT
        v.voucher_id,
        v.voucher_description,
        v.value
      FROM user_promotion up
      JOIN voucher v
        ON v.voucher_id = up.promo_card_id
     WHERE up.user_id = p_user_id
       AND LOWER(up.promo_card_type) = 'voucher';
END;
$$;

CREATE FUNCTION public.get_user_reservations(p_user_id integer) RETURNS SETOF public.table_reservation
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- 1) Validate the user exists
    IF NOT EXISTS (
        SELECT 1
          FROM user_info
         WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'Invalid user_id: %', p_user_id;
    END IF;

    -- 2) Return all reservations for that user
    RETURN QUERY
    SELECT *
      FROM table_reservation
     WHERE user_id = p_user_id;
END;
$$;

CREATE FUNCTION public.get_user_status(p_user_id integer) RETURNS TABLE(hungry_point integer, current_tier character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- 1) Validate the user exists
    IF NOT EXISTS (
        SELECT 1
          FROM user_info
         WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'Invalid user_id: %', p_user_id;
    END IF;

    -- 2) Return the hungry_point and tier (as current_tier)
    RETURN QUERY
    SELECT
        ui.hungry_point,
        ui.tier
      FROM user_info ui
     WHERE ui.user_id = p_user_id;
END;
$$;


CREATE FUNCTION public.get_user_favorites_summary(p_user_id integer) RETURNS TABLE(restaurant_id integer, country character varying, dining_style character varying, restaurant_name character varying, avg_rating numeric, min_package_price numeric, name_count integer)
    LANGUAGE sql
    AS $$
  SELECT
    r.restaurant_id,
    r.country,
    r.dining_style,
    r.restaurant_name,
    -- average of all reviews for this restaurant
    AVG(tr.value_rating)                 AS avg_rating,
    -- minimum numeric price across all packages for this restaurant
    MIN( (pkg.price_after_discount)::NUMERIC ) AS min_package_price,
    -- count of how many restaurants share this name
    (SELECT COUNT(*)
       FROM restaurant_information ri
      WHERE ri.restaurant_name = r.restaurant_name
    )                                     AS name_count
  FROM favorite f
  JOIN restaurant_information r
    ON f.restaurant_id = r.restaurant_id
  LEFT JOIN table_review tr
    ON tr.restaurant_id = r.restaurant_id
  LEFT JOIN package pkg
    ON pkg.restaurant_id = r.restaurant_id
  WHERE f.user_id = p_user_id
  GROUP BY
    r.restaurant_id,
    r.country,
    r.dining_style,
    r.restaurant_name
$$;