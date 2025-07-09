CREATE FUNCTION public.delete_table_date(p_table_size integer, p_time_slot time without time zone, p_date date) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    rows_deleted INTEGER;
BEGIN
    DELETE FROM table_date
     WHERE table_size = p_table_size
       AND time_slot  = p_time_slot
       AND "date"     = p_date;

    GET DIAGNOSTICS rows_deleted = ROW_COUNT;
    IF rows_deleted = 0 THEN
        RAISE EXCEPTION 'No table_date entry to delete for table_size=%, time_slot=%, date=%',
            p_table_size, p_time_slot, p_date;
    END IF;
END;
$$;


CREATE FUNCTION public.delete_table_reservation(p_table_reservation_id integer, p_restaurant_id integer, p_user_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
declare
    num_needed int;
    rows_deleted int;
begin
    SELECT (tr.adult_number + tr.kid_number) INTO num_needed
    FROM table_reservation tr
    WHERE table_reservation_id = p_table_reservation_id AND restaurant_id = p_restaurant_id AND user_id = p_user_id;

    UPDATE table_date
        SET capacity = capacity + num_needed
        WHERE restaurant_id = p_restaurant_id;

    DELETE FROM table_reservation
        WHERE table_reservation_id = p_table_reservation_id
            AND restaurant_id = p_restaurant_id
            AND user_id = p_restaurant_id;

    get diagnostics rows_deleted = ROW_COUNT;
    if rows_deleted = 0 THEN
        RAISE EXCEPTION 'No user found to delete.';
    else
        return 'user deleted successfully.';
    end if;
end;
$$;


CREATE FUNCTION public.delete_table_table(p_table_table_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validate the row exists
    IF NOT EXISTS (
        SELECT 1
          FROM table_table
         WHERE table_table_id = p_table_table_id
    ) THEN
        RAISE EXCEPTION 'table_table_id % does not exist.', p_table_table_id;
    END IF;

    -- Delete the row
    DELETE FROM table_table
     WHERE table_table_id = p_table_table_id;
END;
$$;


CREATE FUNCTION public.delete_table_table(p_table_table_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validate the row exists
    IF NOT EXISTS (
        SELECT 1
          FROM table_table
         WHERE table_table_id = p_table_table_id
    ) THEN
        RAISE EXCEPTION 'table_table_id % does not exist.', p_table_table_id;
    END IF;

    -- Delete the row
    DELETE FROM table_table
     WHERE table_table_id = p_table_table_id;
END;
$$;


CREATE FUNCTION public.delete_voucher(p_voucher_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validate voucher exists
    IF NOT EXISTS (
        SELECT 1 FROM voucher WHERE voucher_id = p_voucher_id
    ) THEN
        RAISE EXCEPTION 'Voucher ID % does not exist.', p_voucher_id;
    END IF;

    -- 1) Remove from user_promotion so no dangling refs
    DELETE FROM user_promotion
     WHERE promo_card_type = 'voucher'
       AND promo_card_id   = p_voucher_id;

    -- 2) Delete the voucher
    DELETE FROM voucher
     WHERE voucher_id = p_voucher_id;
END;
$$;



CREATE FUNCTION public.delete_user_promotion(p_user_id integer, p_promo_card_type character varying, p_promo_card_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validate the promotion entry exists
    IF NOT EXISTS (
        SELECT 1
          FROM user_promotion
         WHERE user_id         = p_user_id
           AND promo_card_type = p_promo_card_type
           AND promo_card_id   = p_promo_card_id
    ) THEN
        RAISE EXCEPTION 'No promotion entry for user %, type %, id %.',
            p_user_id, p_promo_card_type, p_promo_card_id;
    END IF;

    -- Perform the delete
    DELETE FROM user_promotion
     WHERE user_id         = p_user_id
       AND promo_card_type = p_promo_card_type
       AND promo_card_id   = p_promo_card_id;
END;
$$;


CREATE FUNCTION public.delete_promo_code(p_promo_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validate promo code exists
    IF NOT EXISTS (
        SELECT 1 FROM promo_code WHERE promo_id = p_promo_id
    ) THEN
        RAISE EXCEPTION 'Promo Code ID % does not exist.', p_promo_id;
    END IF;

    -- 1) Remove from user_promotion so no dangling refs
    DELETE FROM user_promotion
     WHERE promo_card_type = 'promo_code'
       AND promo_card_id   = p_promo_id;

    -- 2) Delete the promo code
    DELETE FROM promo_code
     WHERE promo_id = p_promo_id;
END;
$$;


CREATE FUNCTION public.delete_gift_card(p_card_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validate gift card exists
    IF NOT EXISTS (
        SELECT 1 FROM gift_card WHERE card_id = p_card_id
    ) THEN
        RAISE EXCEPTION 'Gift Card ID % does not exist.', p_card_id;
    END IF;

    -- Remove related rows in user_promotion
    DELETE FROM user_promotion
     WHERE promo_card_type = 'gift_card'
       AND promo_card_id   = p_card_id;

    -- Delete the gift card itself
    DELETE FROM gift_card
     WHERE card_id = p_card_id;
END;
$$;
