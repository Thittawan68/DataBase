CREATE FUNCTION public.all_restaurant() RETURNS TABLE(restaurant_name character varying)
    LANGUAGE plpgsql
    AS $$
    begin
        RETURN QUERY
        SELECT ri.restaurant_name
        FROM restaurant_information ri;
    end;
    $$;


ALTER FUNCTION public.all_restaurant() OWNER TO deedee;

--
-- Name: check_cascade_constraints(); Type: FUNCTION; Schema: public; Owner: deedee
--

CREATE FUNCTION public.check_cascade_constraints() RETURNS TABLE(table_name text, column_name text, foreign_table_name text, foreign_column_name text, delete_rule text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tc.table_name::TEXT,
        kcu.column_name::TEXT,
        ccu.table_name::TEXT AS foreign_table_name,
        ccu.column_name::TEXT AS foreign_column_name,
        rc.delete_rule::TEXT
    FROM information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
    JOIN information_schema.referential_constraints AS rc
        ON tc.constraint_name = rc.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
        AND ccu.table_name = 'restaurant_information'
    ORDER BY tc.table_name, kcu.column_name;
END;
$$;

CREATE FUNCTION public.check_main_picture_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.main_picture = TRUE THEN
        IF (SELECT COUNT(*) FROM PICTURE 
            WHERE restaurant_id = NEW.restaurant_id 
            AND main_picture = TRUE 
            AND picture_id != COALESCE(NEW.picture_id, -1)) >= 5 THEN
            RAISE EXCEPTION 'Cannot have more than 5 main pictures per restaurant';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE FUNCTION public.check_review_picture_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (SELECT COUNT(*) FROM review_picture 
        WHERE reservation_id = NEW.reservation_id) >= 5 THEN
        RAISE EXCEPTION 'Cannot have more than 5 pictures per reservation';
    END IF;
    RETURN NEW;
END;
$$;

CREATE FUNCTION public.delete_cuisine(p_cuisine_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    cuisine_name_var TEXT;
    restaurant_id_var INTEGER;
    hotel_id_var INTEGER;
    result_message TEXT;
BEGIN
    SELECT cuisinename, restaurant_id, hotel_id 
    INTO cuisine_name_var, restaurant_id_var, hotel_id_var
    FROM cuisine 
    WHERE cuisine_id = p_cuisine_id;
    
    IF cuisine_name_var IS NULL THEN
        RAISE EXCEPTION 'Cuisine with ID % does not exist', p_cuisine_id;
    END IF;
    
    DELETE FROM cuisine WHERE cuisine_id = p_cuisine_id;
    
    result_message := 'Cuisine ID ' || p_cuisine_id || ' ("' || cuisine_name_var || 
                     '") from restaurant ID ' || restaurant_id_var;
    
    IF hotel_id_var IS NOT NULL THEN
        result_message := result_message || ' and hotel ID ' || hotel_id_var;
    END IF;
    
    result_message := result_message || ' successfully deleted';
    
    RETURN result_message;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error deleting cuisine: %', SQLERRM;
END;
$$;

CREATE FUNCTION public.delete_cuisines_by_hotel(p_hotel_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    hotel_name_var TEXT;
    cuisine_count INTEGER;
    result_message TEXT;
BEGIN
    SELECT hotel_name INTO hotel_name_var
    FROM hotel 
    WHERE hotel_id = p_hotel_id;
    
    IF hotel_name_var IS NULL THEN
        RAISE EXCEPTION 'Hotel with ID % does not exist', p_hotel_id;
    END IF;
    
    SELECT COUNT(*) INTO cuisine_count
    FROM cuisine 
    WHERE hotel_id = p_hotel_id;
    
    DELETE FROM cuisine WHERE hotel_id = p_hotel_id;
    
    result_message := 'All ' || cuisine_count || ' cuisines for hotel "' || hotel_name_var || 
                     '" (ID: ' || p_hotel_id || ') successfully deleted';
    
    RETURN result_message;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error deleting cuisines by hotel: %', SQLERRM;
END;
$$;

CREATE FUNCTION public.delete_cuisines_by_restaurant(p_restaurant_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    restaurant_name_var TEXT;
    cuisine_count INTEGER;
    result_message TEXT;
BEGIN
    SELECT restaurant_name INTO restaurant_name_var
    FROM restaurant_information 
    WHERE restaurant_id = p_restaurant_id;
    
    IF restaurant_name_var IS NULL THEN
        RAISE EXCEPTION 'Restaurant with ID % does not exist', p_restaurant_id;
    END IF;
    
    SELECT COUNT(*) INTO cuisine_count
    FROM cuisine 
    WHERE restaurant_id = p_restaurant_id;
    
    DELETE FROM cuisine WHERE restaurant_id = p_restaurant_id;
    
    result_message := 'All ' || cuisine_count || ' cuisines for restaurant "' || restaurant_name_var || 
                     '" (ID: ' || p_restaurant_id || ') successfully deleted';
    
    RETURN result_message;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error deleting cuisines: %', SQLERRM;
END;
$$;

CREATE FUNCTION public.delete_dining_style(p_restaurant_id integer, p_hotel_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
        declare rows_deleted int;
            begin
            delete from dining_style
                where hotel_id = p_hotel_id AND restaurant_id = p_restaurant_id;

            get diagnostics rows_deleted = ROW_COUNT;

            if rows_deleted = 0 THEN
                RAISE EXCEPTION 'No dining_style found to delete.';
            else
                return 'dining_style deleted successfully.';
            end if;
        end;
    $$;


ALTER FUNCTION public.delete_dining_style(p_restaurant_id integer, p_hotel_id integer) OWNER TO deedee;

--
-- Name: delete_facility(integer, integer); Type: FUNCTION; Schema: public; Owner: deedee
--

CREATE FUNCTION public.delete_facility(p_restaurant_id integer, p_facility_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
        declare rows_deleted int;
            begin
            delete from facility
                where restaurant_id = p_restaurant_id AND facility_id = p_facility_id;
            get diagnostics rows_deleted = ROW_COUNT;
            if rows_deleted = 0 THEN
                RAISE EXCEPTION 'No dining_style found to delete.';
            else
                return 'dining_style deleted successfully.';
            end if;
        end;
    $$;


ALTER FUNCTION public.delete_facility(p_restaurant_id integer, p_facility_id integer) OWNER TO deedee;

--
-- Name: delete_favorite(integer, integer); Type: FUNCTION; Schema: public; Owner: deedee
--

CREATE FUNCTION public.delete_favorite(p_user_id integer, p_restaurant_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
    declare rows_deleted int;
        begin
        delete from favorite
        where user_id = p_user_id AND restaurant_id = p_restaurant_id;
        GET diagnostics rows_deleted = ROW_COUNT;

        if rows_deleted = 0 THEN
            RAISE EXCEPTION 'No favourite found to delete.';
        else
            return 'favourite deleted successfully.';
        end if;
    end;
    $$;


ALTER FUNCTION public.delete_favorite(p_user_id integer, p_restaurant_id integer) OWNER TO deedee;

--
-- Name: delete_gift_card(integer); Type: FUNCTION; Schema: public; Owner: deedee
--

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

CREATE FUNCTION public.delete_location(p_location_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    location_name_var TEXT;
    location_type_var TEXT;
    restaurant_id_var INTEGER;
    result_message TEXT;
BEGIN
    SELECT location_name, location_type, restaurant_id 
    INTO location_name_var, location_type_var, restaurant_id_var
    FROM location 
    WHERE location_id = p_location_id;
    
    IF location_name_var IS NULL THEN
        RAISE EXCEPTION 'Location with ID % does not exist', p_location_id;
    END IF;
    
    DELETE FROM location WHERE location_id = p_location_id;
    
    result_message := 'Location ID ' || p_location_id || ' ("' || location_name_var || 
                     '", type: ' || COALESCE(location_type_var, 'N/A') || 
                     ') from restaurant ID ' || restaurant_id_var || ' successfully deleted';
    
    RETURN result_message;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error deleting location: %', SQLERRM;
END;
$$;

CREATE FUNCTION public.delete_locations_by_restaurant(p_restaurant_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    restaurant_name_var TEXT;
    location_count INTEGER;
    result_message TEXT;
BEGIN
    SELECT restaurant_name INTO restaurant_name_var
    FROM restaurant_information 
    WHERE restaurant_id = p_restaurant_id;
    
    IF restaurant_name_var IS NULL THEN
        RAISE EXCEPTION 'Restaurant with ID % does not exist', p_restaurant_id;
    END IF;
    
    SELECT COUNT(*) INTO location_count
    FROM location 
    WHERE restaurant_id = p_restaurant_id;
    
    DELETE FROM location WHERE restaurant_id = p_restaurant_id;
    
    result_message := 'All ' || location_count || ' locations for restaurant "' || restaurant_name_var || 
                     '" (ID: ' || p_restaurant_id || ') successfully deleted';
    
    RETURN result_message;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error deleting locations: %', SQLERRM;
END;
$$;

CREATE FUNCTION public.delete_offers_availability(p_restaurant_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    restaurant_name_var TEXT;
    sell_voucher_var BOOLEAN;
    sell_delivery_var BOOLEAN;
    result_message TEXT;
BEGIN
    SELECT ri.restaurant_name, oa.sell_voucher, oa.sell_delivery
    INTO restaurant_name_var, sell_voucher_var, sell_delivery_var
    FROM restaurant_information ri
    JOIN offers_availability oa ON ri.restaurant_id = oa.restaurant_id
    WHERE ri.restaurant_id = p_restaurant_id;
    
    IF restaurant_name_var IS NULL THEN
        RAISE EXCEPTION 'Restaurant with ID % does not exist or has no offers availability record', p_restaurant_id;
    END IF;
    
    DELETE FROM offers_availability WHERE restaurant_id = p_restaurant_id;
    
    result_message := 'Offers availability for restaurant "' || restaurant_name_var || 
                     '" (ID: ' || p_restaurant_id || ') successfully deleted';
    
    result_message := result_message || ' (voucher: ' || 
                     CASE WHEN sell_voucher_var THEN 'enabled' ELSE 'disabled' END ||
                     ', delivery: ' || 
                     CASE WHEN sell_delivery_var THEN 'enabled' ELSE 'disabled' END || ')';
    
    RETURN result_message;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error deleting offers availability: %', SQLERRM;
END;
$$;

CREATE FUNCTION public.delete_package_cascade(p_package_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    package_name_var TEXT;
    restaurant_id_var INTEGER;
    result_message TEXT;
BEGIN
    -- Check if package exists and get its name and restaurant_id for confirmation message
    SELECT package_name, restaurant_id INTO package_name_var, restaurant_id_var
    FROM package 
    WHERE package_id = p_package_id;
    
    IF package_name_var IS NULL THEN
        RAISE EXCEPTION 'Package with ID % does not exist', p_package_id;
    END IF;
    
    -- Delete the package - CASCADE will automatically delete all related records
    -- This single DELETE statement will remove:
    -- - The package record
    -- - All time_slot records for this package
    -- - All package_type records for this package
    -- - Any other records that reference this package
    DELETE FROM package WHERE package_id = p_package_id;
    
    result_message := 'Package "' || package_name_var || '" (ID: ' || p_package_id || 
                     ') from restaurant ID ' || restaurant_id_var || 
                     ' and all related data successfully deleted using CASCADE constraints.';
    
    RETURN result_message;
    
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Cannot delete package: CASCADE constraints not properly set up. Error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error deleting package: %', SQLERRM;
END;
$$;

CREATE FUNCTION public.delete_package_types_by_package(p_package_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    package_name_var TEXT;
    type_count INTEGER;
    result_message TEXT;
BEGIN
    SELECT package_name INTO package_name_var
    FROM package 
    WHERE package_id = p_package_id;
    
    IF package_name_var IS NULL THEN
        RAISE EXCEPTION 'Package with ID % does not exist', p_package_id;
    END IF;
    
    SELECT COUNT(*) INTO type_count
    FROM package_type 
    WHERE package_id = p_package_id;
    
    DELETE FROM package_type WHERE package_id = p_package_id;
    
    result_message := 'All ' || type_count || ' package types for package "' || package_name_var || 
                     '" (ID: ' || p_package_id || ') successfully deleted';
    
    RETURN result_message;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error deleting package types: %', SQLERRM;
END;
$$;

CREATE FUNCTION public.delete_payments_methods(p_user_id integer, p_card_number character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  rows_deleted INT;
BEGIN
  DELETE FROM payment_methods
   WHERE user_id     = p_user_id
     AND card_number = p_card_number;
  GET DIAGNOSTICS rows_deleted = ROW_COUNT;
  IF rows_deleted = 0 THEN
    RAISE EXCEPTION 'No payment method % found for user %',
                    p_card_number, p_user_id;
  END IF;
  RETURN 'payment_method deleted successfully.';
END;
$$;

CREATE FUNCTION public.delete_picture(p_picture_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    picture_url_var TEXT;
    restaurant_id_var INTEGER;
    is_main_picture BOOLEAN;
    result_message TEXT;
BEGIN
    SELECT picture_url, restaurant_id, main_picture 
    INTO picture_url_var, restaurant_id_var, is_main_picture
    FROM picture 
    WHERE picture_id = p_picture_id;
    
    IF picture_url_var IS NULL THEN
        RAISE EXCEPTION 'Picture with ID % does not exist', p_picture_id;
    END IF;
    
    DELETE FROM picture WHERE picture_id = p_picture_id;
    
    result_message := 'Picture ID ' || p_picture_id || ' (' || picture_url_var || 
                     ') from restaurant ID ' || restaurant_id_var || 
                     ' successfully deleted';

    
    RETURN result_message;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error deleting picture: %', SQLERRM;
END;
$$;

CREATE FUNCTION public.delete_promo_code(p_promo_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM promo_code WHERE promo_id = p_promo_id
  ) THEN
    RAISE EXCEPTION 'Promo Code ID % does not exist.', p_promo_id;
  END IF;

  DELETE FROM user_promotion
   WHERE promo_card_type = 'promo_code'
     AND promo_card_id   = p_promo_id;

  DELETE FROM promo_code
   WHERE promo_id = p_promo_id;
END;
$$;

CREATE FUNCTION public.delete_promotion(p_package_id integer, p_restaurant_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
declare rows_deleted int;
begin
    delete from promotion
    where package_id = p_package_id AND restaurant_id = p_restaurant_id;
    get diagnostics rows_deleted = ROW_COUNT;
    if rows_deleted = 0 THEN
        RAISE EXCEPTION 'No promotion found to delete.';
    else
        return 'promotion deleted successfully.';
    end if;
end;
$$;

CREATE FUNCTION public.delete_restaurant_cascade(p_restaurant_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    restaurant_name_var TEXT;
    result_message TEXT;
BEGIN
    -- Check if restaurant exists and get its name for confirmation message
    SELECT restaurant_name INTO restaurant_name_var 
    FROM restaurant_information 
    WHERE restaurant_id = p_restaurant_id;
    
    IF restaurant_name_var IS NULL THEN
        RAISE EXCEPTION 'Restaurant with ID % does not exist', p_restaurant_id;
    END IF;
    
    -- Delete the restaurant - CASCADE will automatically delete all related records
    -- This single DELETE statement will remove:
    -- - The restaurant record
    -- - All offers_availability records
    -- - All pictures  
    -- - All packages (and their time_slots)
    -- - All table_reservations (and their reviews, review_pictures)
    -- - All other related records based on your CASCADE setup
    DELETE FROM restaurant_information WHERE restaurant_id = p_restaurant_id;
    
    result_message := 'Restaurant "' || restaurant_name_var || '" (ID: ' || p_restaurant_id || 
                     ') and all related data successfully deleted using CASCADE constraints.';
    
    RETURN result_message;
    
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Cannot delete restaurant: CASCADE constraints not properly set up. Error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error deleting restaurant: %', SQLERRM;
END;
$$;

CREATE FUNCTION public.delete_review_picture(p_picture_id integer, p_reservation_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
declare rows_deleted int;
begin
    delete from review_picture
    where picture_id = p_picture_id and reservation_id = p_reservation_id;
    get diagnostics rows_deleted = ROW_COUNT;
    if rows_deleted = 0 THEN
        RAISE EXCEPTION 'No review_picture found to delete.';
    else
        return 'review_picture deleted successfully.';
    end if;
end;
$$;

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
DECLARE
  num_needed    INTEGER;
  resv_date     DATE;
  resv_time     TIME WITHOUT TIME ZONE;
  rows_deleted  INTEGER;
BEGIN
  -- 1) Fetch reservation details
  SELECT tr.adult_number + tr.kid_number,
         tr."date",
         tr.booking_time
    INTO num_needed, resv_date, resv_time
    FROM table_reservation tr
   WHERE tr.table_reservation_id = p_table_reservation_id
     AND tr.restaurant_id        = p_restaurant_id
     AND tr.user_id              = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No reservation % found for user % at restaurant %',
      p_table_reservation_id, p_user_id, p_restaurant_id;
  END IF;

  -- 2) Restore capacity for that exact slot
  UPDATE table_date
     SET capacity = capacity + num_needed
   WHERE restaurant_id = p_restaurant_id
     AND "date"        = resv_date
     AND time_slot     = resv_time;

  -- 3) Delete the reservation record (**fix** is here)
  DELETE FROM table_reservation
   WHERE table_reservation_id = p_table_reservation_id
     AND restaurant_id        = p_restaurant_id
     AND user_id              = p_user_id;  -- ← was wrongly p_restaurant_id

  GET DIAGNOSTICS rows_deleted = ROW_COUNT;
  IF rows_deleted = 0 THEN
    RAISE EXCEPTION 'Failed to delete reservation %.', p_table_reservation_id;
  END IF;

  RETURN 'Reservation deleted successfully.';
END;
$$;

CREATE FUNCTION public.delete_table_review(p_table_reservation_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    rows_deleted INT;
BEGIN
    DELETE FROM table_review
     WHERE table_reservation_id = p_table_reservation_id;

    GET DIAGNOSTICS rows_deleted = ROW_COUNT;
    IF rows_deleted = 0 THEN
        RAISE EXCEPTION 'No review found for reservation %.', p_table_reservation_id;
    END IF;
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

CREATE FUNCTION public.delete_time_slot(p_time_slot_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    start_time_var TIME;
    end_time_var TIME;
    package_id_var INTEGER;
    result_message TEXT;
BEGIN
    -- Check if time_slot exists and get its details
    SELECT start_time, end_time, package_id 
    INTO start_time_var, end_time_var, package_id_var
    FROM time_slot 
    WHERE time_slot_id = p_time_slot_id;
    
    IF start_time_var IS NULL THEN
        RAISE EXCEPTION 'Time slot with ID % does not exist', p_time_slot_id;
    END IF;
    
    -- Delete the time_slot
    DELETE FROM time_slot WHERE time_slot_id = p_time_slot_id;
    
    result_message := 'Time slot ID ' || p_time_slot_id || ' (' || start_time_var || 
                     ' - ' || end_time_var || ') from package ID ' || package_id_var || 
                     ' successfully deleted';
    
    RETURN result_message;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error deleting time slot: %', SQLERRM;
END;
$$;

CREATE FUNCTION public.delete_time_slots_by_package(p_package_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    package_name_var TEXT;
    slot_count INTEGER;
    result_message TEXT;
BEGIN
    -- Check if package exists
    SELECT package_name INTO package_name_var
    FROM package 
    WHERE package_id = p_package_id;
    
    IF package_name_var IS NULL THEN
        RAISE EXCEPTION 'Package with ID % does not exist', p_package_id;
    END IF;
    
    -- Count time slots before deletion
    SELECT COUNT(*) INTO slot_count
    FROM time_slot 
    WHERE package_id = p_package_id;
    
    -- Delete all time slots for this package
    DELETE FROM time_slot WHERE package_id = p_package_id;
    
    result_message := 'All ' || slot_count || ' time slots for package "' || package_name_var || 
                     '" (ID: ' || p_package_id || ') successfully deleted';
    
    RETURN result_message;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error deleting time slots: %', SQLERRM;
END;
$$;

CREATE FUNCTION public.delete_user(p_user_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
declare rows_deleted int;
begin
    delete from user_info
    WHERE user_id = p_user_id;
    delete from table_reservation
    WHERE user_id = p_user_id;

    get diagnostics rows_deleted = ROW_COUNT;
    if rows_deleted = 0 THEN
        RAISE EXCEPTION 'No user found to delete.';
    else
        return 'user deleted successfully.';
    end if;
end;
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

CREATE FUNCTION public.filter_same_branch(rest_name character varying) RETURNS TABLE(restaurant_name character varying)
    LANGUAGE plpgsql
    AS $$
        begin
            RETURN QUERY
            SELECT ri.restaurant_name
            FROM restaurant_information ri
            WHERE ri.restaurant_name ILIKE '%' || rest_name || '%';
        end;
    $$;


ALTER FUNCTION public.filter_same_branch(rest_name character varying) OWNER TO deedee;

--
-- Name: get_all_gift_cards(); Type: FUNCTION; Schema: public; Owner: deedee
--

CREATE FUNCTION public.get_all_gift_cards() RETURNS TABLE(card_id integer, value integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gift_card.card_id,
        gift_card.value
    FROM gift_card;
END;
$$;

CREATE FUNCTION public.get_all_restaurant_pictures(_restaurant_id integer) RETURNS TABLE(picture_id integer, picture_url character varying, main_picture boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    RETURN QUERY
    SELECT p.picture_id, p.picture_url, p.main_picture
    FROM PICTURE p
    WHERE p.restaurant_id = _restaurant_id
    ORDER BY p.main_picture DESC, p.picture_id;
END;
$$;

CREATE FUNCTION public.get_dining_style() RETURNS TABLE(style_name character varying)
    LANGUAGE plpgsql
    AS $$
    begin
        RETURN QUERY
        SELECT ds.style_name
        FROM dining_style ds
        group by ds.style_name;
    end;
    $$;


ALTER FUNCTION public.get_dining_style() OWNER TO deedee;

--
-- Name: get_restaurant_average_ratings(integer); Type: FUNCTION; Schema: public; Owner: deedee
--

CREATE FUNCTION public.get_restaurant_average_ratings(_restaurant_id integer) RETURNS TABLE(food_average numeric, food_count bigint, ambiance_average numeric, ambiance_count bigint, service_average numeric, service_count bigint, value_average numeric, value_count bigint, overall_average numeric, total_reviews bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    RETURN QUERY
    SELECT 
        ROUND(AVG(COALESCE(r.food_rating, 0))::DECIMAL, 2) as food_average,
        COUNT(r.food_rating) as food_count,
        ROUND(AVG(COALESCE(r.ambiance_rating, 0))::DECIMAL, 2) as ambiance_average,
        COUNT(r.ambiance_rating) as ambiance_count,
        ROUND(AVG(COALESCE(r.service_rating, 0))::DECIMAL, 2) as service_average,
        COUNT(r.service_rating) as service_count,
        ROUND(AVG(COALESCE(r.value_rating, 0))::DECIMAL, 2) as value_average,
        COUNT(r.value_rating) as value_count,
        ROUND(AVG((COALESCE(r.food_rating, 0) + COALESCE(r.ambiance_rating, 0) + COALESCE(r.service_rating, 0) + COALESCE(r.value_rating, 0))::DECIMAL / 4), 2) as overall_average,
        COUNT(*) as total_reviews
    FROM table_review r
    WHERE r.restaurant_id = _restaurant_id;
END;
$$;

CREATE FUNCTION public.get_restaurant_info_with_similar_count(_restaurant_id integer) RETURNS TABLE(restaurant_name character varying, open_time time without time zone, close_time time without time zone, location character varying, similar_restaurants_count bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
    found_name VARCHAR;
    similar_count BIGINT;
BEGIN
    -- Check if restaurant exists and get its info
    SELECT ri.restaurant_name, ri.open_time, ri.close_time, ri.location
    INTO restaurant_name, open_time, close_time, location
    FROM restaurant_information ri
    WHERE ri.restaurant_id = _restaurant_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Restaurant with ID % not found', _restaurant_id;
    END IF;
    
    found_name := restaurant_name;
    
    SELECT COUNT(*) INTO similar_count
    FROM restaurant_information ri
    WHERE LOWER(ri.restaurant_name) LIKE LOWER('%' || found_name || '%');
    
    similar_restaurants_count := similar_count;
    RETURN NEXT;
END;
$$;

CREATE FUNCTION public.get_restaurant_packages(_restaurant_id integer) RETURNS TABLE(package_name character varying, sub_package character varying, price integer, end_date date, duration integer, number_of_dishes integer, number_of_people integer, picture_url character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    RETURN QUERY
    SELECT p.package_name,
           p.sub_package,
           COALESCE(p.price, 0) as price,
           p.end_date,
           COALESCE(p.duration, 0) as duration,
           COALESCE(p.number_of_dishes, 0) as number_of_dishes,
           COALESCE(p.number_of_people, 0) as number_of_people,
           p.picture_url
    FROM package p
    WHERE p.restaurant_id = _restaurant_id
    ORDER BY p.package_id;
END;
$$;

CREATE FUNCTION public.get_restaurant_reviews(_restaurant_id integer) RETURNS TABLE(user_id integer, reviewer_name character varying, average_rating numeric, review_date date, comment text, picture_url character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    RETURN QUERY
    SELECT 
        r.user_id,
        ui.name as reviewer_name,
        ROUND((COALESCE(r.food_rating, 0) + COALESCE(r.ambiance_rating, 0) + COALESCE(r.service_rating, 0) + COALESCE(r.value_rating, 0))::DECIMAL / 4, 2) as average_rating,
        r.date,
        r.comment,
        rp.picture_url
    FROM table_review r
    JOIN user_info ui ON r.user_id = ui.user_id
    LEFT JOIN review_picture rp ON r.table_reservation_id = rp.reservation_id
    JOIN table_reservation tr ON r.table_reservation_id = tr.table_reservation_id
    WHERE r.restaurant_id = _restaurant_id;
END;
$$;

CREATE FUNCTION public.get_resturant_basic_info(_restaurant_id integer) RETURNS TABLE(restaurant_name character varying, restaurant_location text, open_time time without time zone, close_time time without time zone, dining_style character varying, main_cuisine character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    RETURN QUERY
    SELECT ri.restaurant_name, ri.location, ri.open_time, ri.close_time, ri.dining_style, ri.main_cuisine
    FROM restaurant_information ri
    WHERE ri.restaurant_id = _restaurant_id;
END;
$$;

CREATE FUNCTION public.get_resturant_picture(_restaurant_id integer) RETURNS TABLE(picture_url character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    RETURN QUERY
    SELECT p.picture_url 
    FROM PICTURE p
    WHERE p.restaurant_id = _restaurant_id AND p.main_picture = TRUE
    LIMIT 5;
END;
$$;

CREATE FUNCTION public.get_tags(_restaurant_id integer) RETURNS TABLE(data_type character varying, value_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    RETURN QUERY
    SELECT 'facility'::VARCHAR as data_type, f.sub_facility_type as value_name
    FROM facility f
    WHERE f.restaurant_id = _restaurant_id
    
    UNION ALL
    
    SELECT 'cuisine'::VARCHAR as data_type, c.cuisinename as value_name
    FROM cuisine c
    WHERE c.restaurant_id = _restaurant_id
    
    UNION ALL
    
    SELECT 'location'::VARCHAR as data_type, l.location_name as value_name
    FROM location l
    WHERE l.restaurant_id = _restaurant_id
    
    UNION ALL
    
    SELECT 'dining_style'::VARCHAR as data_type, ds.style_name as value_name
    FROM dining_style ds
    WHERE ds.restaurant_id = _restaurant_id
    
    ORDER BY data_type, value_name;
END;
$$;

CREATE FUNCTION public.get_top_cuisine() RETURNS TABLE(cuisine_name character varying)
    LANGUAGE plpgsql
    AS $$
        begin
            return query
            SELECT c.cuisinename FROM cuisine c
            GROUP BY
                c.cuisinename
            ORDER BY
                c.cuisinename DESC;
        end;
    $$;


ALTER FUNCTION public.get_top_cuisine() OWNER TO deedee;

--
-- Name: get_top_dining_style(); Type: FUNCTION; Schema: public; Owner: deedee
--

CREATE FUNCTION public.get_top_dining_style() RETURNS TABLE(dining_style character varying)
    LANGUAGE plpgsql
    AS $$
    begin
        RETURN QUERY
        SELECT ds.style_name
        FROM dining_style ds
        GROUP BY ds.style_name
        ORDER BY COUNT(ds.style_name) DESC;
     end;
    $$;


ALTER FUNCTION public.get_top_dining_style() OWNER TO deedee;

--
-- Name: get_top_location(); Type: FUNCTION; Schema: public; Owner: deedee
--

CREATE FUNCTION public.get_top_location() RETURNS TABLE(location_name character varying)
    LANGUAGE plpgsql
    AS $$
    begin
        RETURN QUERY
        SELECT lo.location_name
        FROM location lo
        GROUP BY lo.location_name
        ORDER BY COUNT(lo.location_name) DESC;
    end;
    $$;


ALTER FUNCTION public.get_top_location() OWNER TO deedee;

--
-- Name: get_user_favorites_summary(integer); Type: FUNCTION; Schema: public; Owner: deedee
--

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

CREATE FUNCTION public.get_user_payment_methods(p_user_id integer) RETURNS TABLE(card_number text, card_type character varying, card_brand character varying)
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

    -- 2) Return all payment methods for that user
    RETURN QUERY
    SELECT
        pm.card_number,
        pm.card_type,
        pm.card_brand
      FROM payment_methods pm
     WHERE pm.user_id = p_user_id;
END;
$$;

CREATE FUNCTION public.get_user_promo_codes(p_user_id integer) RETURNS TABLE(promo_id integer, promo_code text, promo_value integer, restaurant_id integer)
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
      pc.promo_code,
      pc."value"     AS promo_value,
      pc.restaurant_id
    FROM user_promotion up
    JOIN promo_code pc
      ON pc.promo_id = up.promo_card_id
    WHERE up.user_id = p_user_id
      AND LOWER(up.promo_card_type) = 'promo_code';
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

CREATE FUNCTION public.hotel(p_hotel_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
declare rows_deleted int;
begin
    delete from hotel
    where hotel_id = p_hotel_id;
    get diagnostics rows_deleted = ROW_COUNT;
    if rows_deleted = 0 THEN
        RAISE EXCEPTION 'No Hotel found to delete.';
    else
        return 'Hotel deleted successfully.';
    end if;
end;
$$;

CREATE FUNCTION public.insert_cuisine(_cuisine_name character varying, _restaurant_id integer, _hotel_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Restaurant_Information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

   IF _hotel_id IS NOT NULL THEN
       IF NOT EXISTS (SELECT 1 FROM Hotel WHERE hotel_id = _hotel_id) THEN
           RAISE EXCEPTION 'Invalid Hotel_ID';
       END IF;
   END IF;

    IF LENGTH(TRIM(_cuisine_name)) = 0 THEN
        RAISE EXCEPTION 'Cuisine name cannot be empty';
    END IF;

    INSERT INTO cuisine(cuisinename, restaurant_id, hotel_id)
    VALUES (_cuisine_name, _restaurant_id, _hotel_id);
END;
$$;

CREATE FUNCTION public.insert_dining_style(_style_name character varying, _restaurant_id integer, _hotel_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF LENGTH(TRIM(_style_name)) = 0 THEN
        RAISE EXCEPTION 'Style name cannot be empty';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Restaurant_Information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    IF _hotel_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM Hotel WHERE hotel_id = _hotel_id) THEN
            RAISE EXCEPTION 'Invalid Hotel_ID';
        END IF;
    END IF;

    INSERT INTO dining_style(style_name, restaurant_id, hotel_id)
    VALUES (_style_name, _restaurant_id, _hotel_id);
END;
$$;

CREATE FUNCTION public.insert_facility(_restaurant_id integer, _facility_type character varying, _sub_facility_type character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Restaurant_Information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    IF _facility_type IS NULL OR _sub_facility_type IS NULL THEN
        RAISE EXCEPTION 'Facility type and sub-facility type must not be null';
    END IF;

    INSERT INTO facility(restaurant_id, facility_type, sub_facility_type)
    VALUES (_restaurant_id, _facility_type, _sub_facility_type);
END;
$$;

CREATE FUNCTION public.insert_favorite(p_user_id integer, p_restaurant_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
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
$$;

CREATE FUNCTION public.insert_general_pic(p_restaurant_id integer, p_picture_url text, p_main_5 boolean DEFAULT false) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  _id INTEGER;
BEGIN
  -- Validate that the referenced restaurant exists
  IF NOT EXISTS (
    SELECT 1 FROM restaurant_information
     WHERE restaurant_id = p_restaurant_id
  ) THEN
    RAISE EXCEPTION 'Invalid restaurant_id: %', p_restaurant_id;
  END IF;

  -- Ensure a non-empty URL
  IF p_picture_url IS NULL OR btrim(p_picture_url) = '' THEN
    RAISE EXCEPTION 'picture_url cannot be empty';
  END IF;

  -- Insert and return the new picture_id
  INSERT INTO general_pic(restaurant_id, main_5, picture_url)
  VALUES (p_restaurant_id, p_main_5, p_picture_url)
  RETURNING picture_id INTO _id;

  RETURN _id;
END;
$$;

CREATE FUNCTION public.insert_gift_card(p_value integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO gift_card (value)
    VALUES (p_value);
END;
$$;

CREATE FUNCTION public.insert_hotel(_hotel_name character varying, _hotel_location character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    _id INT;
BEGIN
    IF _hotel_name IS NULL OR LENGTH(TRIM(_hotel_name)) = 0 THEN
        RAISE EXCEPTION 'Hotel name cannot be empty';
    END IF;

    INSERT INTO hotel(hotel_name, hotel_location)
    VALUES (_hotel_name, _hotel_location)
    RETURNING hotel_id INTO _id;
    RETURN _id;
END;
$$;

CREATE FUNCTION public.insert_location(_restaurant_id integer, _location_type character varying, _location_name character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Restaurant_Information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    IF LENGTH(TRIM(_location_name)) = 0 THEN
        RAISE EXCEPTION 'Location name cannot be empty';
    END IF;

    INSERT INTO Location(restaurant_id, location_type, location_name)
    VALUES (_restaurant_id, _location_type, _location_name);
END;
$$;

CREATE FUNCTION public.insert_offers_availability(_restaurant_id integer, _sell_voucher boolean DEFAULT false, _promo_code boolean DEFAULT false) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Restaurant_Information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    INSERT INTO offers_availability(restaurant_id, sell_voucher, promo_code)
    VALUES (_restaurant_id, _sell_voucher, _promo_code);
END;
$$;

CREATE FUNCTION public.insert_package(_restaurant_id integer, _price integer, _discount_percent integer, _price_after_discount integer, _start_date date, _end_date date, _sub_package character varying, _package_name character varying, _picture_url character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    _package_id INT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Restaurant_Information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    IF LENGTH(TRIM(_package_name)) = 0 THEN
        RAISE EXCEPTION 'Package name cannot be empty';
    END IF;

    INSERT INTO package (
        restaurant_id, price, discount_percent, price_after_discount,
        start_date, end_date, sub_package, package_name, picture_url
    ) VALUES (
        _restaurant_id, _price, _discount_percent, _price_after_discount,
        _start_date, _end_date, _sub_package, _package_name, _picture_url
    )
    RETURNING package_id INTO _package_id;

    RETURN _package_id;
END;
$$;

CREATE FUNCTION public.insert_package(restaurant_id integer, price character varying, discount_percent character varying, price_after_discount character varying, start_date date, end_date date, sub_package character varying, package_name character varying, picture_url character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Restaurant_Information WHERE restaurant_id = restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    IF LENGTH(TRIM(package_name)) = 0 THEN
        RAISE EXCEPTION 'Package name cannot be empty';
    END IF;

    INSERT INTO package (
        restaurant_id, price, discount_percent, price_after_discount,
        start_date, end_date, sub_package, package_name, picture_url
    ) VALUES (
        restaurant_id, price, discount_percent, price_after_discount,
        start_date, end_date, sub_package, package_name, picture_url
    )
    RETURNING package_id INTO restaurant_id;

    RETURN restaurant_id;
END;

$$;

CREATE FUNCTION public.insert_package_type(p_package_id integer, p_restaurant_id integer DEFAULT NULL::integer, p_all_you_can_eat boolean DEFAULT false, p_party_pack boolean DEFAULT false, p_xperience boolean DEFAULT false) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Validate that the package exists
  IF NOT EXISTS (
    SELECT 1 
      FROM package 
     WHERE package_id = p_package_id
  ) THEN
    RAISE EXCEPTION 'Invalid package_id: %', p_package_id;
  END IF;

  -- Validate that the restaurant exists, if provided
  IF p_restaurant_id IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 
         FROM restaurant_information 
        WHERE restaurant_id = p_restaurant_id
     ) THEN
    RAISE EXCEPTION 'Invalid restaurant_id: %', p_restaurant_id;
  END IF;

  -- Insert into package_type
  INSERT INTO package_type (
    package_id,
    restaurant_id,
    all_you_can_eat,
    party_pack,
    xperience
  )
  VALUES (
    p_package_id,
    p_restaurant_id,
    p_all_you_can_eat,
    p_party_pack,
    p_xperience
  );
END;
$$;

CREATE FUNCTION public.insert_payment_method(p_user_id integer, p_card_number character varying, p_card_type character varying, p_card_brand character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
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
$$;

CREATE FUNCTION public.insert_picture(_restaurant_id integer, _picture_url character varying, _main_picture boolean DEFAULT false) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Restaurant_Information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    IF LENGTH(TRIM(_picture_url)) = 0 THEN
        RAISE EXCEPTION 'Picture URL cannot be empty';
    END IF;

    INSERT INTO picture(restaurant_id, picture_url, main_picture)
    VALUES (_restaurant_id, _picture_url, _main_picture);
END;
$$;

CREATE FUNCTION public.insert_promo_code(p_value integer, p_restaurant_id integer, p_code text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- ensure restaurant exists
  IF NOT EXISTS (
    SELECT 1 FROM restaurant_information WHERE restaurant_id = p_restaurant_id
  ) THEN
    RAISE EXCEPTION 'Restaurant ID % does not exist.', p_restaurant_id;
  END IF;

  -- ensure code is unique
  IF EXISTS (
    SELECT 1 FROM promo_code WHERE promo_code = p_code
  ) THEN
    RAISE EXCEPTION 'Promo code "%" already exists.', p_code;
  END IF;

  INSERT INTO promo_code (value, restaurant_id, promo_code)
  VALUES (p_value, p_restaurant_id, p_code);
END;
$$;

CREATE FUNCTION public.insert_promotion(p_package_id integer, p_promotion character varying, p_restaurant_id integer DEFAULT NULL::integer, p_start_date date DEFAULT NULL::date, p_end_date date DEFAULT NULL::date) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Verify that the package exists
  IF NOT EXISTS (
    SELECT 1 FROM package WHERE package_id = p_package_id
  ) THEN
    RAISE EXCEPTION 'Invalid package_id: %', p_package_id;
  END IF;

  -- Verify that the restaurant exists, if provided
  IF p_restaurant_id IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM restaurant_information
        WHERE restaurant_id = p_restaurant_id
     ) THEN
    RAISE EXCEPTION 'Invalid restaurant_id: %', p_restaurant_id;
  END IF;

  -- Ensure promotion text is not empty
  IF p_promotion IS NULL OR btrim(p_promotion) = '' THEN
    RAISE EXCEPTION 'Promotion text cannot be empty';
  END IF;

  -- If both dates are provided, ensure start_date ≤ end_date
  IF p_start_date IS NOT NULL
     AND p_end_date IS NOT NULL
     AND p_start_date > p_end_date THEN
    RAISE EXCEPTION 'start_date (%) cannot be after end_date (%)',
      p_start_date, p_end_date;
  END IF;

  -- Perform the insert
  INSERT INTO promotion (
    package_id,
    promotion,
    restaurant_id,
    start_date,
    end_date
  )
  VALUES (
    p_package_id,
    p_promotion,
    p_restaurant_id,
    p_start_date,
    p_end_date
  );
END;
$$;

CREATE FUNCTION public.insert_restaurant_information(_open_time time without time zone, _close_time time without time zone, _location character varying, _email character varying, _contact_number bigint, _restaurant_name character varying, _dining_style character varying, _country character varying, _about_us text, _join_date date, _main_cuisine character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    _id INT;
BEGIN
    IF _open_time >= _close_time THEN
        RAISE EXCEPTION 'Open time must be before close time';
    END IF;

    IF LENGTH(CAST(_contact_number AS TEXT)) < 10 THEN
        RAISE EXCEPTION 'Contact number must have at least 10 digits';
    END IF;

    IF _restaurant_name IS NULL OR LENGTH(TRIM(_restaurant_name)) = 0 THEN
        RAISE EXCEPTION 'Restaurant name cannot be empty';
    END IF;

    INSERT INTO Restaurant_Information (
        open_time, close_time, location, email, contact_number,
        restaurant_name, dining_style, country, about_us, join_date, main_cuisine
    ) VALUES (
                 _open_time, _close_time, _location, _email, _contact_number,
                 _restaurant_name, _dining_style, _country, _about_us, _join_date, _main_cuisine
             )
    RETURNING restaurant_id INTO _id;

    RETURN _id;
END;
$$;

CREATE FUNCTION public.insert_review_picture(p_reservation_id integer, p_picture_url character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  _id INTEGER;
BEGIN
  -- Validate that the reservation exists
  IF NOT EXISTS (
    SELECT 1
      FROM table_reservation
     WHERE table_reservation_id = p_reservation_id
  ) THEN
    RAISE EXCEPTION 'Invalid reservation_id: %', p_reservation_id;
  END IF;

  -- Ensure the URL is not null or empty
  IF p_picture_url IS NULL OR btrim(p_picture_url) = '' THEN
    RAISE EXCEPTION 'picture_url cannot be empty';
  END IF;

  -- Insert and return the new picture_id
  INSERT INTO review_picture (reservation_id, picture_url)
  VALUES (p_reservation_id, p_picture_url)
  RETURNING picture_id INTO _id;

  RETURN _id;
END;
$$;

CREATE FUNCTION public.insert_table_date(p_table_size integer, p_time_slot time without time zone, p_date date, p_restaurant_id integer DEFAULT NULL::integer, p_capacity integer DEFAULT NULL::integer, p_max_capacity integer DEFAULT NULL::integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Required fields
  IF p_table_size IS NULL OR p_table_size < 1 THEN
    RAISE EXCEPTION 'table_size must be a positive integer';
  END IF;
  IF p_time_slot IS NULL THEN
    RAISE EXCEPTION 'time_slot cannot be null';
  END IF;
  IF p_date IS NULL THEN
    RAISE EXCEPTION 'date cannot be null';
  END IF;

  -- Referential integrity
  IF p_restaurant_id IS NOT NULL
     AND NOT EXISTS (
       SELECT 1
         FROM restaurant_information
        WHERE restaurant_id = p_restaurant_id
     ) THEN
    RAISE EXCEPTION 'Invalid restaurant_id: %', p_restaurant_id;
  END IF;

  -- Capacity validations
  IF p_capacity IS NOT NULL AND p_capacity < 0 THEN
    RAISE EXCEPTION 'capacity cannot be negative';
  END IF;
  IF p_max_capacity IS NOT NULL AND p_max_capacity < 0 THEN
    RAISE EXCEPTION 'max_capacity cannot be negative';
  END IF;
  IF p_capacity IS NOT NULL
     AND p_max_capacity IS NOT NULL
     AND p_capacity > p_max_capacity THEN
    RAISE EXCEPTION 'capacity (%) cannot exceed max_capacity (%)', p_capacity, p_max_capacity;
  END IF;

  -- Insert the row
  INSERT INTO table_date (
    table_size,
    time_slot,
    capacity,
    "date",
    restaurant_id,
    max_capacity
  )
  VALUES (
    p_table_size,
    p_time_slot,
    p_capacity,
    p_date,
    p_restaurant_id,
    p_max_capacity
  );
END;
$$;

CREATE FUNCTION public.insert_table_reservation(p_adult_number integer, p_kid_number integer, p_restaurant_id integer, p_user_id integer, p_date date, p_package_id integer, p_booking_time time without time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_needed       INTEGER := p_adult_number + p_kid_number;
  v_old_capacity INTEGER;
  v_max_cap      INTEGER;
  v_new_id       INTEGER;
BEGIN
  -- 1) Try to lock & fetch existing availability
  SELECT capacity
    INTO v_old_capacity
    FROM table_date
   WHERE restaurant_id = p_restaurant_id
     AND "date"        = p_date
     AND time_slot     = p_booking_time
  FOR UPDATE;

  IF FOUND THEN
    -- 2a) Not enough seats?
    IF v_old_capacity < v_needed THEN
      RAISE EXCEPTION 'Not enough capacity: have %, need %', v_old_capacity, v_needed;
    END IF;
    -- 2b) Deduct needed seats
    UPDATE table_date
       SET capacity = v_old_capacity - v_needed
     WHERE restaurant_id = p_restaurant_id
       AND "date"        = p_date
       AND time_slot     = p_booking_time;
  ELSE
    -- 3) No row yet: fetch max_capacity from table_table
    SELECT capacity
      INTO v_max_cap
      FROM table_table
     WHERE restaurant_id = p_restaurant_id
    LIMIT 1;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'No max capacity defined for restaurant %', p_restaurant_id;
    END IF;

    IF v_max_cap < v_needed THEN
      RAISE EXCEPTION 'Party size % exceeds restaurant max capacity %', v_needed, v_max_cap;
    END IF;

    -- 4) Initialize a new table_date row
    INSERT INTO table_date(
      table_size,
      time_slot,
      capacity,
      "date",
      restaurant_id,
      max_capacity
    ) VALUES (
      v_max_cap,               -- table_size
      p_booking_time,          -- time_slot
      v_max_cap - v_needed,    -- capacity after booking
      p_date,                  -- date
      p_restaurant_id,         -- restaurant_id
      v_max_cap                -- max_capacity
    );
  END IF;

  -- 5) Finally, insert the reservation
  INSERT INTO table_reservation(
    adult_number,
    kid_number,
    restaurant_id,
    user_id,
    "date",
    package_id,
    arrived,
    booking_time
  )
  VALUES (
    p_adult_number,
    p_kid_number,
    p_restaurant_id,
    p_user_id,
    p_date,
    p_package_id,
    FALSE,             -- arrived default
    p_booking_time
  )
  RETURNING table_reservation_id
  INTO v_new_id;

  RETURN v_new_id;
END;
$$;

CREATE FUNCTION public.insert_table_review(p_table_reservation_id integer, p_restaurant_id integer, p_user_id integer, p_date date, p_food_rating integer, p_ambiance_rating integer, p_service_rating integer, p_value_rating integer, p_comment text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- validations...
    IF NOT EXISTS (SELECT 1 FROM table_reservation WHERE table_reservation_id = p_table_reservation_id) THEN
        RAISE EXCEPTION 'Reservation ID % does not exist.', p_table_reservation_id;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = p_restaurant_id) THEN
        RAISE EXCEPTION 'Restaurant ID % does not exist.', p_restaurant_id;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM user_info WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'User ID % does not exist.', p_user_id;
    END IF;
    -- rating checks
    IF p_food_rating     NOT BETWEEN 0 AND 5 THEN RAISE EXCEPTION 'food_rating % out of range 0–5.', p_food_rating;     END IF;
    IF p_ambiance_rating NOT BETWEEN 0 AND 5 THEN RAISE EXCEPTION 'ambiance_rating % out of range 0–5.', p_ambiance_rating; END IF;
    IF p_service_rating  NOT BETWEEN 0 AND 5 THEN RAISE EXCEPTION 'service_rating % out of range 0–5.', p_service_rating;  END IF;
    IF p_value_rating    NOT BETWEEN 0 AND 5 THEN RAISE EXCEPTION 'value_rating % out of range 0–5.', p_value_rating;      END IF;

    INSERT INTO table_review (
      table_reservation_id,
      restaurant_id,
      user_id,
      "date",
      food_rating,
      ambiance_rating,
      service_rating,
      value_rating,
      comment
    ) VALUES (
      p_table_reservation_id,
      p_restaurant_id,
      p_user_id,
      p_date,
      p_food_rating,
      p_ambiance_rating,
      p_service_rating,
      p_value_rating,
      p_comment
    );
END;
$$;

CREATE FUNCTION public.insert_table_table(p_capacity integer, p_quantity integer, p_restaurant_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  _id INTEGER;
BEGIN
  -- Validate capacity
  IF p_capacity IS NULL OR p_capacity < 1 THEN
    RAISE EXCEPTION 'capacity must be a positive integer';
  END IF;

  -- Validate quantity
  IF p_quantity IS NULL OR p_quantity < 1 THEN
    RAISE EXCEPTION 'quantity must be a positive integer';
  END IF;

  -- Validate restaurant exists
  IF NOT EXISTS (
    SELECT 1
      FROM restaurant_information
     WHERE restaurant_id = p_restaurant_id
  ) THEN
    RAISE EXCEPTION 'Invalid restaurant_id: %', p_restaurant_id;
  END IF;

  -- Insert and return new ID
  INSERT INTO table_table (capacity, quantity, restaurant_id)
  VALUES (p_capacity, p_quantity, p_restaurant_id)
  RETURNING table_table_id INTO _id;

  RETURN _id;
END;
$$;

CREATE FUNCTION public.insert_time_slot(p_start_time time without time zone, p_package_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  _id INTEGER;
BEGIN
  -- Validate start_time
  IF p_start_time IS NULL THEN
    RAISE EXCEPTION 'start_time cannot be null';
  END IF;

  -- Validate that the package exists
  IF NOT EXISTS (
    SELECT 1
      FROM package
     WHERE package_id = p_package_id
  ) THEN
    RAISE EXCEPTION 'Invalid package_id: %', p_package_id;
  END IF;

  -- Perform the insert
  INSERT INTO time_slot (start_time, package_id)
  VALUES (p_start_time, p_package_id)
  RETURNING time_slot_id INTO _id;

  RETURN _id;
END;
$$;

CREATE FUNCTION public.insert_time_slot(p_start_time time without time zone, p_end_time time without time zone, p_package_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  _id INTEGER;
BEGIN
  -- Validate times
  IF p_start_time IS NULL OR p_end_time IS NULL THEN
    RAISE EXCEPTION 'start_time and end_time cannot be null';
  END IF;
  IF p_start_time >= p_end_time THEN
    RAISE EXCEPTION 'start_time (%) must be before end_time (%)', p_start_time, p_end_time;
  END IF;

  -- Validate that the package exists
  IF NOT EXISTS (
    SELECT 1 FROM package WHERE package_id = p_package_id
  ) THEN
    RAISE EXCEPTION 'Invalid package_id: %', p_package_id;
  END IF;

  -- Perform the insert
  INSERT INTO time_slot (start_time, end_time, package_id)
  VALUES (p_start_time, p_end_time, p_package_id)
  RETURNING time_slot_id INTO _id;

  RETURN _id;
END;
$$;

CREATE FUNCTION public.insert_user_info(p_name character varying DEFAULT NULL::character varying, p_hungry_point integer DEFAULT 0, p_email_login character varying DEFAULT NULL::character varying, p_email_contact character varying DEFAULT NULL::character varying, p_facebook character varying DEFAULT NULL::character varying, p_phone_number character varying DEFAULT NULL::character varying, p_date_of_birth date DEFAULT NULL::date, p_tier character varying DEFAULT 'Red'::character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO user_info (
    name, hungry_point, email_login, email_contact,
    facebook, phone_number, date_of_birth, tier
  ) VALUES (
    p_name, p_hungry_point, p_email_login, p_email_contact,
    p_facebook, p_phone_number, p_date_of_birth, p_tier
  );
END;
$$;

CREATE FUNCTION public.insert_user_info(p_name character varying DEFAULT NULL::character varying, p_hungry_point integer DEFAULT 0, p_email_login character varying DEFAULT NULL::character varying, p_email_contact character varying DEFAULT NULL::character varying, p_facebook character varying DEFAULT NULL::character varying, p_phone_number integer DEFAULT NULL::integer, p_date_of_birth date DEFAULT NULL::date, p_tier character varying DEFAULT 'Red'::character varying, p_password character varying DEFAULT NULL::character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    hashed_password VARCHAR(255);
BEGIN
    IF p_password IS NOT NULL THEN
        hashed_password := crypt(p_password, gen_salt('bf', 12));
    ELSE
        hashed_password := NULL;
    END IF;

    INSERT INTO user_info (
        name, hungry_point, email_login, email_contact,
        facebook, phone_number, date_of_birth, tier, email_pass
    )
    VALUES (
       p_name, p_hungry_point, p_email_login, p_email_contact,
       p_facebook, p_phone_number, p_date_of_birth, p_tier, hashed_password
   );
END;
$$;

CREATE FUNCTION public.insert_user_promotion(p_user_id integer, p_promo_card_type character varying, p_promo_card_id integer, p_quantity integer DEFAULT 1) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- validate user
    IF NOT EXISTS (SELECT 1 FROM user_info WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'User ID % does not exist.', p_user_id;
    END IF;

    -- upsert, adding p_quantity
    INSERT INTO user_promotion (user_id, promo_card_type, promo_card_id, quantity)
    VALUES (p_user_id, p_promo_card_type, p_promo_card_id, p_quantity)
    ON CONFLICT (user_id, promo_card_type, promo_card_id)
    DO UPDATE
      SET quantity = user_promotion.quantity + EXCLUDED.quantity;
END;
$$;

CREATE FUNCTION public.insert_voucher(p_value integer, p_description text, p_restaurant_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- validate the restaurant exists
    IF NOT EXISTS (
        SELECT 1
          FROM restaurant_information
         WHERE restaurant_id = p_restaurant_id
    ) THEN
        RAISE EXCEPTION 'Invalid restaurant_id: %', p_restaurant_id;
    END IF;

    -- perform the insert
    INSERT INTO voucher (value, voucher_description, restaurant_id)
    VALUES (p_value, p_description, p_restaurant_id);
END;
$$;

CREATE FUNCTION public.promotion(p_package_id integer, p_restaurant_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
declare rows_deleted int;
begin
    delete from promotion
    where package_id = p_package_id AND restaurant_id = p_restaurant_id;
    get diagnostics rows_deleted = ROW_COUNT;
    if rows_deleted = 0 THEN
        RAISE EXCEPTION 'No promotion found to delete.';
    else
        return 'promotion deleted successfully.';
    end if;
end;
$$;

CREATE FUNCTION public.register_user_promotion_by_type(p_user_id integer, p_type character varying, p_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- 1) Validate user exists
    IF NOT EXISTS (
        SELECT 1 FROM user_info WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'Invalid user_id: %', p_user_id;
    END IF;

    -- 2) Branch by type, validate existence in the right table
    CASE LOWER(p_type)
      WHEN 'voucher' THEN
        IF NOT EXISTS (SELECT 1 FROM voucher WHERE voucher_id = p_id) THEN
            RAISE EXCEPTION 'Voucher ID % does not exist.', p_id;
        END IF;

      WHEN 'gift_card' THEN
        IF NOT EXISTS (SELECT 1 FROM gift_card WHERE card_id = p_id) THEN
            RAISE EXCEPTION 'Gift Card ID % does not exist.', p_id;
        END IF;

      WHEN 'promo_code' THEN
        IF NOT EXISTS (SELECT 1 FROM promo_code WHERE promo_id = p_id) THEN
            RAISE EXCEPTION 'Promo Code ID % does not exist.', p_id;
        END IF;

      ELSE
        RAISE EXCEPTION 'Unknown promotion type: %. Must be voucher, gift_card, or promo_code.', p_type;
    END CASE;

    -- 3) Delegate to your upsert function
    PERFORM insert_user_promotion(
      p_user_id,
      p_type,
      p_id
    );
END;
$$;

CREATE FUNCTION public.search_page_filtering(nearest_first boolean DEFAULT false, sell_voucher boolean DEFAULT false, accept_promo_code boolean DEFAULT false, package_type character varying[] DEFAULT NULL::character varying[], facilities character varying[] DEFAULT NULL::character varying[], package_price boolean DEFAULT false, starting_price integer DEFAULT 0, highest_price integer DEFAULT 20000, cuisine character varying DEFAULT NULL::character varying, dining_style character varying DEFAULT NULL::character varying, location character varying DEFAULT NULL::character varying) RETURNS TABLE(restaurant_id integer, cuisine_type character varying, restaurant_name character varying, avg_rating numeric, price integer)
    LANGUAGE plpgsql
    AS $$
        begin
            RETURN QUERY
            SELECT ri.restaurant_id,
                   c.cuisinename AS cuisine_type,
                   ri.restaurant_name,
                   AVG((tr.value_rating + tr.service_rating + tr.ambiance_rating + tr.food_rating) / 4.0) AS avg_rating,
                   MIN(pack.price) AS price
            FROM restaurant_information ri
            LEFT JOIN table_review tr on ri.restaurant_id = tr.restaurant_id
            LEFT JOIN cuisine c on ri.restaurant_id = c.restaurant_id
            LEFT JOIN dining_style ds on ri.restaurant_id = ds.restaurant_id
            LEFT JOIN location l on ri.restaurant_id = l.restaurant_id

            LEFT JOIN package_type pt on ri.restaurant_id = pt.restaurant_id
            LEFT JOIN package pack on ri.restaurant_id = pack.restaurant_id
            LEFT JOIN facility f on ri.restaurant_id = f.restaurant_id
            LEFT JOIN promotion p on ri.restaurant_id = p.restaurant_id
            LEFT JOIN voucher v on ri.restaurant_id = v.restaurant_id
            WHERE
                (sell_voucher = FALSE OR v.voucher_id IS NOT NULL) AND
                (accept_promo_code = FALSE OR p.promotion IS NOT NULL) AND
                (package_type IS NULL OR
                 (
                    ('all_you_can_eat' = ANY(package_type) AND pt.all_you_can_eat = TRUE)) OR
                    ('party_pack' = ANY(package_type) AND pt.party_pack = TRUE) OR
                    ('xperience' = ANY(package_type) AND pt.party_pack = TRUE)
                    ) AND
                (facilities IS NULL OR f.facility_type = ANY(facilities)) AND
                (package_price = FALSE OR pack.price BETWEEN starting_price AND highest_price)
            GROUP BY
                ri.restaurant_id,
                ri.restaurant_name,
                c.cuisinename;
        end;
    $$;


ALTER FUNCTION public.search_page_filtering(nearest_first boolean, sell_voucher boolean, accept_promo_code boolean, package_type character varying[], facilities character varying[], package_price boolean, starting_price integer, highest_price integer, cuisine character varying, dining_style character varying, location character varying) OWNER TO deedee;

--
-- Name: select_newly_added(); Type: FUNCTION; Schema: public; Owner: deedee
--

CREATE FUNCTION public.select_newly_added() RETURNS TABLE(restaurant_id integer, restaurant_name character varying)
    LANGUAGE plpgsql
    AS $$
    BEGIN
        return QUERY
        SELECT ri.restaurant_id, ri.restaurant_name
        FROM restaurant_information ri
        ORDER BY ri.join_date DESC;
    end;
    $$;


ALTER FUNCTION public.select_newly_added() OWNER TO deedee;

--
-- Name: select_promotion(); Type: FUNCTION; Schema: public; Owner: deedee
--

CREATE FUNCTION public.select_promotion() RETURNS TABLE(restaurant_name character varying, packages_id integer, promotion character varying)
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RETURN QUERY
        SELECT ri.restaurant_name, pi.package_id, pi.promotion
        FROM promotion pi
        JOIN restaurant_information ri ON pi.restaurant_id = ri.restaurant_id
        JOIN table_review tr ON pi.restaurant_id = tr.restaurant_id
        ORDER BY pi.start_Date DESC, (tr.food_rating + tr.ambiance_rating + tr.service_rating + tr.value_rating)/4.0 DESC;
    end;
    $$;


ALTER FUNCTION public.select_promotion() OWNER TO deedee;

--
-- Name: select_top_20(); Type: FUNCTION; Schema: public; Owner: deedee
--

CREATE FUNCTION public.select_top_20() RETURNS TABLE(restaurant_id integer, restaurant_name character varying, rating numeric)
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RETURN QUERY
        SELECT ri.restaurant_id,  ri.restaurant_name, (tr.value_rating + tr.service_rating + tr.ambiance_rating + tr.food_rating )/4.0 AS rating
        FROM restaurant_information ri
        JOIN table_review tr ON ri.restaurant_id = tr.restaurant_id
        ORDER BY rating DESC
        LIMIT 20;
    end;
    $$;


ALTER FUNCTION public.select_top_20() OWNER TO deedee;

--
-- Name: select_top_hotel_rest(); Type: FUNCTION; Schema: public; Owner: deedee
--

CREATE FUNCTION public.select_top_hotel_rest() RETURNS TABLE(restaurant_id integer, restaurant_name character varying, rating numeric)
    LANGUAGE plpgsql
    AS $$
    begin
        return query
        select
            ri.restaurant_id,
            ri.restaurant_name,
            (tr.food_rating
                + tr.ambiance_rating
                + tr.service_rating
                + tr.value_rating
                ) / 4.0 AS rating
        from restaurant_information as ri
        join table_review as tr
        on ri.restaurant_id = tr.restaurant_id
        join hotel as h
        on ri.restaurant_id = h.restaurant_id
        order by rating desc
        limit 20;
    end;
    $$;


ALTER FUNCTION public.select_top_hotel_rest() OWNER TO deedee;

--
-- Name: update_cuisine(integer, character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: deedee
--

CREATE FUNCTION public.update_cuisine(p_cuisine_id integer, p_cuisine_name character varying DEFAULT NULL::character varying, p_restaurant_id integer DEFAULT NULL::integer, p_hotel_id integer DEFAULT NULL::integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    updated_fields TEXT[] := ARRAY[]::TEXT[];
    result_message TEXT;
BEGIN
    -- Check if cuisine exists
    IF NOT EXISTS (SELECT 1 FROM cuisine WHERE cuisine_id = p_cuisine_id) THEN
        RAISE EXCEPTION 'Cuisine with ID % does not exist.', p_cuisine_id;
    END IF;

    -- Check if restaurant exists if restaurant_id is provided
    IF p_restaurant_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = p_restaurant_id) THEN
            RAISE EXCEPTION 'Restaurant with ID % does not exist.', p_restaurant_id;
        END IF;
    END IF;

    -- Check if hotel exists if hotel_id is provided
    IF p_hotel_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM hotel WHERE hotel_id = p_hotel_id) THEN
            RAISE EXCEPTION 'Hotel with ID % does not exist.', p_hotel_id;
        END IF;
    END IF;

    -- Validate cuisine name if provided
    IF p_cuisine_name IS NOT NULL AND LENGTH(TRIM(p_cuisine_name)) = 0 THEN
        RAISE EXCEPTION 'Cuisine name cannot be empty';
    END IF;

    -- Build list of fields being updated for confirmation message
    IF p_cuisine_name IS NOT NULL THEN updated_fields := array_append(updated_fields, 'cuisine_name'); END IF;
    IF p_restaurant_id IS NOT NULL THEN updated_fields := array_append(updated_fields, 'restaurant_id'); END IF;
    IF p_hotel_id IS NOT NULL THEN updated_fields := array_append(updated_fields, 'hotel_id'); END IF;

    -- Check if any fields are being updated
    IF array_length(updated_fields, 1) IS NULL THEN
        RETURN 'No fields specified for update. Cuisine ID ' || p_cuisine_id || ' unchanged.';
    END IF;

    -- Update only the fields that are not NULL
    UPDATE cuisine
    SET 
        cuisinename = COALESCE(p_cuisine_name, cuisinename),
        restaurant_id = COALESCE(p_restaurant_id, restaurant_id),
        hotel_id = COALESCE(p_hotel_id, hotel_id)
    WHERE cuisine_id = p_cuisine_id;
    
    RETURN result_message;
END;
$$;

CREATE FUNCTION public.update_dining_style(p_style_name character varying, p_restaurant_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
    declare rows_updated int;
    begin
        update dining_style
        set
            style_name = p_style_name
        where p_restaurant_id = restaurant_id;

        get diagnostics rows_updated = row_count;
        if rows_updated = 0 then
            return 'no dining style found';
        else
            return 'dining style update successfully';
        end if;
    end;
    $$;


ALTER FUNCTION public.update_dining_style(p_style_name character varying, p_restaurant_id integer) OWNER TO deedee;

--
-- Name: update_facility(integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: deedee
--

CREATE FUNCTION public.update_facility(p_facility_id integer, p_facility_type character varying, p_sub_facility_type character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
    begin
        UPDATE facility
        SET
            facility_type = p_facility_type,
            sub_facility_type = p_sub_facility_type
        WHERE p_facility_id = facility.facility_id;
    end;
    $$;


ALTER FUNCTION public.update_facility(p_facility_id integer, p_facility_type character varying, p_sub_facility_type character varying) OWNER TO deedee;

--
-- Name: update_favorite(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: deedee
--

CREATE FUNCTION public.update_favorite(p_user_id integer, p_old_restaurant_id integer, p_new_restaurant_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    rows_updated INT;
BEGIN
    UPDATE favorite
    SET restaurant_id = p_new_restaurant_id
    WHERE user_id = p_user_id AND restaurant_id = p_old_restaurant_id;

    GET DIAGNOSTICS rows_updated = ROW_COUNT;

    IF rows_updated = 0 THEN
        RETURN 'No matching favourite found.';
    ELSE
        RETURN 'Favourite updated successfully.';
    END IF;
END;
$$;

CREATE FUNCTION public.update_gift_card(p_card_id integer, p_value integer DEFAULT NULL::integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validate gift card exists
    IF NOT EXISTS (
        SELECT 1 FROM gift_card WHERE card_id = p_card_id
    ) THEN
        RAISE EXCEPTION 'Gift Card ID % does not exist.', p_card_id;
    END IF;

    -- Update only the value if provided
    UPDATE gift_card
       SET "value" = COALESCE(p_value, "value")
     WHERE card_id = p_card_id;
END;
$$;

CREATE FUNCTION public.update_hotel(p_hotel_name character varying, p_hotel_location character varying, p_hotel_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
    DECLARE
        rows_updated INT;
        begin
        UPDATE hotel
        SET
            hotel_name = p_hotel_name,
            hotel_location = p_hotel_location
        WHERE hotel_id = p_hotel_id;
        IF rows_updated = 0 THEN
            RETURN 'Hotel does not exist';
        ELSE
            RETURN 'Hotel Update Successful!';
        end IF;
        end;
    $$;


ALTER FUNCTION public.update_hotel(p_hotel_name character varying, p_hotel_location character varying, p_hotel_id integer) OWNER TO deedee;

--
-- Name: update_location(integer, integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: deedee
--

CREATE FUNCTION public.update_location(p_location_id integer, p_restaurant_id integer DEFAULT NULL::integer, p_location_type character varying DEFAULT NULL::character varying, p_location_name character varying DEFAULT NULL::character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    updated_fields TEXT[] := ARRAY[]::TEXT[];
    result_message TEXT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM location WHERE location_id = p_location_id) THEN
        RAISE EXCEPTION 'Location with ID % does not exist.', p_location_id;
    END IF;

    IF p_restaurant_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = p_restaurant_id) THEN
            RAISE EXCEPTION 'Restaurant with ID % does not exist.', p_restaurant_id;
        END IF;
    END IF;

    IF p_location_name IS NOT NULL AND LENGTH(TRIM(p_location_name)) = 0 THEN
        RAISE EXCEPTION 'Location name cannot be empty';
    END IF;

    IF p_location_type IS NOT NULL AND LENGTH(TRIM(p_location_type)) = 0 THEN
        RAISE EXCEPTION 'Location type cannot be empty';
    END IF;

    IF p_restaurant_id IS NOT NULL THEN updated_fields := array_append(updated_fields, 'restaurant_id'); END IF;
    IF p_location_type IS NOT NULL THEN updated_fields := array_append(updated_fields, 'location_type'); END IF;
    IF p_location_name IS NOT NULL THEN updated_fields := array_append(updated_fields, 'location_name'); END IF;

    
    UPDATE location
    SET 
        restaurant_id = COALESCE(p_restaurant_id, restaurant_id),
        location_type = COALESCE(p_location_type, location_type),
        location_name = COALESCE(p_location_name, location_name)
    WHERE location_id = p_location_id;

    
    RETURN result_message;
END;
$$;

CREATE FUNCTION public.update_offers_availability(p_restaurant_id integer, p_sell_voucher boolean DEFAULT NULL::boolean, p_promo_code boolean DEFAULT NULL::boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    updated_fields TEXT[] := ARRAY[]::TEXT[];
    result_message TEXT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM offers_availability WHERE restaurant_id = p_restaurant_id) THEN
        RAISE EXCEPTION 'Offers availability record for restaurant ID % does not exist.', p_restaurant_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = p_restaurant_id) THEN
        RAISE EXCEPTION 'Restaurant with ID % does not exist.', p_restaurant_id;
    END IF;

    IF p_sell_voucher IS NOT NULL THEN updated_fields := array_append(updated_fields, 'sell_voucher'); END IF;
    IF p_promo_code IS NOT NULL THEN updated_fields := array_append(updated_fields, 'promo_code'); END IF;

    IF array_length(updated_fields, 1) IS NULL THEN
        RETURN 'No fields specified for update. Offers availability for restaurant ID ' || p_restaurant_id || ' unchanged.';
    END IF;

    UPDATE offers_availability
    SET 
        sell_voucher = COALESCE(p_sell_voucher, sell_voucher),
        promo_code = COALESCE(p_promo_code, promo_code)
    WHERE restaurant_id = p_restaurant_id;
    
    RETURN result_message;
END;
$$;

CREATE FUNCTION public.update_package(p_package_id integer, p_restaurant_id integer DEFAULT NULL::integer, p_package_name character varying DEFAULT NULL::character varying, p_sub_package character varying DEFAULT NULL::character varying, p_price numeric DEFAULT NULL::numeric, p_end_date date DEFAULT NULL::date, p_duration integer DEFAULT NULL::integer, p_number_of_dishes integer DEFAULT NULL::integer, p_number_of_people integer DEFAULT NULL::integer, p_picture_url character varying DEFAULT NULL::character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    updated_fields TEXT[] := ARRAY[]::TEXT[];
    result_message TEXT;
BEGIN
    -- Check if package exists
    IF NOT EXISTS (SELECT 1 FROM package WHERE package_id = p_package_id) THEN
        RAISE EXCEPTION 'Package with ID % does not exist.', p_package_id;
    END IF;

    -- Check if restaurant exists if restaurant_id is provided
    IF p_restaurant_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = p_restaurant_id) THEN
            RAISE EXCEPTION 'Restaurant with ID % does not exist.', p_restaurant_id;
        END IF;
    END IF;

    -- Validate price if provided
    IF p_price IS NOT NULL AND p_price < 0 THEN
        RAISE EXCEPTION 'Price must be a positive value';
    END IF;

    -- Validate duration if provided
    IF p_duration IS NOT NULL AND p_duration <= 0 THEN
        RAISE EXCEPTION 'Duration must be greater than 0 minutes';
    END IF;

    -- Validate number of dishes if provided
    IF p_number_of_dishes IS NOT NULL AND p_number_of_dishes < 0 THEN
        RAISE EXCEPTION 'Number of dishes cannot be negative';
    END IF;

    -- Validate number of people if provided
    IF p_number_of_people IS NOT NULL AND p_number_of_people <= 0 THEN
        RAISE EXCEPTION 'Number of people must be greater than 0';
    END IF;

    -- Validate package name if provided
    IF p_package_name IS NOT NULL AND LENGTH(TRIM(p_package_name)) = 0 THEN
        RAISE EXCEPTION 'Package name cannot be empty';
    END IF;

    -- Validate end date if provided (should be in the future)
    IF p_end_date IS NOT NULL AND p_end_date < CURRENT_DATE THEN
        RAISE EXCEPTION 'End date cannot be in the past';
    END IF;

    -- Build list of fields being updated for confirmation message
    IF p_restaurant_id IS NOT NULL THEN updated_fields := array_append(updated_fields, 'restaurant_id'); END IF;
    IF p_package_name IS NOT NULL THEN updated_fields := array_append(updated_fields, 'package_name'); END IF;
    IF p_sub_package IS NOT NULL THEN updated_fields := array_append(updated_fields, 'sub_package'); END IF;
    IF p_price IS NOT NULL THEN updated_fields := array_append(updated_fields, 'price'); END IF;
    IF p_end_date IS NOT NULL THEN updated_fields := array_append(updated_fields, 'end_date'); END IF;
    IF p_duration IS NOT NULL THEN updated_fields := array_append(updated_fields, 'duration'); END IF;
    IF p_number_of_dishes IS NOT NULL THEN updated_fields := array_append(updated_fields, 'number_of_dishes'); END IF;
    IF p_number_of_people IS NOT NULL THEN updated_fields := array_append(updated_fields, 'number_of_people'); END IF;
    IF p_picture_url IS NOT NULL THEN updated_fields := array_append(updated_fields, 'picture_url'); END IF;

    -- Check if any fields are being updated
    IF array_length(updated_fields, 1) IS NULL THEN
        RETURN 'No fields specified for update. Package ID ' || p_package_id || ' unchanged.';
    END IF;

    -- Update only the fields that are not NULL
    UPDATE package
    SET 
        restaurant_id = COALESCE(p_restaurant_id, restaurant_id),
        package_name = COALESCE(p_package_name, package_name),
        sub_package = COALESCE(p_sub_package, sub_package),
        price = COALESCE(p_price, price),
        end_date = COALESCE(p_end_date, end_date),
        duration = COALESCE(p_duration, duration),
        number_of_dishes = COALESCE(p_number_of_dishes, number_of_dishes),
        number_of_people = COALESCE(p_number_of_people, number_of_people),
        picture_url = COALESCE(p_picture_url, picture_url)
    WHERE package_id = p_package_id;

    -- Create result message
    result_message := 'Package ID ' || p_package_id || ' updated successfully. Updated fields: ' || array_to_string(updated_fields, ', ');
    
    RETURN result_message;
END;
$$;

CREATE FUNCTION public.update_package_type(p_package_id integer, p_all_you_can_eat boolean DEFAULT NULL::boolean, p_party_pack boolean DEFAULT NULL::boolean, p_xperience boolean DEFAULT NULL::boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    updated_fields TEXT[] := ARRAY[]::TEXT[];
    result_message TEXT;
BEGIN
    -- Check if package type exists
    IF NOT EXISTS (SELECT 1 FROM package_type WHERE package_id = p_package_id) THEN
        RAISE EXCEPTION 'Package type with ID % does not exist.', p_package_id;
    END IF;

    -- Build list of fields being updated for confirmation message
    IF p_all_you_can_eat IS NOT NULL THEN updated_fields := array_append(updated_fields, 'all_you_can_eat'); END IF;
    IF p_party_pack IS NOT NULL THEN updated_fields := array_append(updated_fields, 'party_pack'); END IF;
    IF p_xperience IS NOT NULL THEN updated_fields := array_append(updated_fields, 'xperience'); END IF;

    -- Check if any fields are being updated
    IF array_length(updated_fields, 1) IS NULL THEN
        RETURN 'No fields specified for update. Package type ID ' || p_package_id || ' unchanged.';
    END IF;

    -- Update only the fields that are not NULL
    UPDATE package_type
    SET 
        all_you_can_eat = COALESCE(p_all_you_can_eat, all_you_can_eat),
        party_pack = COALESCE(p_party_pack, party_pack),
        xperience = COALESCE(p_xperience, xperience)
    WHERE package_id = p_package_id;

    -- Create result message
    result_message := 'Package type ID ' || p_package_id || ' updated successfully. Updated fields: ' || array_to_string(updated_fields, ', ');
    
    RETURN result_message;
END;
$$;

CREATE FUNCTION public.update_payments_method(p_card_type character varying, p_card_brand character varying, p_user_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
    DECLARE
        rows_updated INT;
        begin
        UPDATE payment_methods
        SET
            card_type = p_card_type,
            card_brand = p_card_brand
        WHERE user_id = p_user_id;
        IF rows_updated = 0 THEN
            RETURN 'Restaurant does not exist';
        ELSE
            RETURN 'Payments Update Successful!';
        end IF;
        end;
    $$;


ALTER FUNCTION public.update_payments_method(p_card_type character varying, p_card_brand character varying, p_user_id integer) OWNER TO deedee;

--
-- Name: update_picture(integer, integer, boolean, character varying); Type: FUNCTION; Schema: public; Owner: deedee
--

CREATE FUNCTION public.update_picture(p_picture_id integer, p_restaurant_id integer DEFAULT NULL::integer, p_main_picture boolean DEFAULT NULL::boolean, p_picture_url character varying DEFAULT NULL::character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    updated_fields TEXT[] := ARRAY[]::TEXT[];
    result_message TEXT;
    current_main_count INT;
BEGIN
    -- Check if picture exists
    IF NOT EXISTS (SELECT 1 FROM picture WHERE picture_id = p_picture_id) THEN
        RAISE EXCEPTION 'Picture with ID % does not exist.', p_picture_id;
    END IF;

    -- Check if restaurant exists if restaurant_id is provided
    IF p_restaurant_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = p_restaurant_id) THEN
            RAISE EXCEPTION 'Restaurant with ID % does not exist.', p_restaurant_id;
        END IF;
    END IF;

    -- Validate picture URL if provided
    IF p_picture_url IS NOT NULL AND LENGTH(TRIM(p_picture_url)) = 0 THEN
        RAISE EXCEPTION 'Picture URL cannot be empty';
    END IF;

    -- Check main picture limit if setting to main picture
    IF p_main_picture = TRUE THEN
        -- Get the restaurant_id for this picture (current or new)
        SELECT COALESCE(p_restaurant_id, restaurant_id) INTO current_main_count
        FROM picture WHERE picture_id = p_picture_id;
        
        -- Check if restaurant already has 5 main pictures (excluding current picture)
        SELECT COUNT(*) INTO current_main_count
        FROM picture 
        WHERE restaurant_id = COALESCE(p_restaurant_id, 
                                     (SELECT restaurant_id FROM picture WHERE picture_id = p_picture_id))
        AND main_picture = TRUE 
        AND picture_id != p_picture_id;
        
        IF current_main_count >= 5 THEN
            RAISE EXCEPTION 'Cannot have more than 5 main pictures per restaurant';
        END IF;
    END IF;

    -- Build list of fields being updated for confirmation message
    IF p_restaurant_id IS NOT NULL THEN updated_fields := array_append(updated_fields, 'restaurant_id'); END IF;
    IF p_main_picture IS NOT NULL THEN updated_fields := array_append(updated_fields, 'main_picture'); END IF;
    IF p_picture_url IS NOT NULL THEN updated_fields := array_append(updated_fields, 'picture_url'); END IF;

    -- Check if any fields are being updated
    IF array_length(updated_fields, 1) IS NULL THEN
        RETURN 'No fields specified for update. Picture ID ' || p_picture_id || ' unchanged.';
    END IF;

    -- Update only the fields that are not NULL
    UPDATE picture
    SET 
        restaurant_id = COALESCE(p_restaurant_id, restaurant_id),
        main_picture = COALESCE(p_main_picture, main_picture),
        picture_url = COALESCE(p_picture_url, picture_url)
    WHERE picture_id = p_picture_id;

    -- Create result message
    result_message := 'Picture ID ' || p_picture_id || ' updated successfully. Updated fields: ' || array_to_string(updated_fields, ', ');
    
    RETURN result_message;
END;
$$;

CREATE FUNCTION public.update_promo_code(p_promo_id integer, p_value integer DEFAULT NULL::integer, p_restaurant_id integer DEFAULT NULL::integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validate promo code exists
    IF NOT EXISTS (
        SELECT 1 FROM promo_code WHERE promo_id = p_promo_id
    ) THEN
        RAISE EXCEPTION 'Promo Code ID % does not exist.', p_promo_id;
    END IF;

    -- If updating restaurant, validate it exists
    IF p_restaurant_id IS NOT NULL AND
       NOT EXISTS (
           SELECT 1 FROM restaurant_information WHERE restaurant_id = p_restaurant_id
       )
    THEN
        RAISE EXCEPTION 'Restaurant ID % does not exist.', p_restaurant_id;
    END IF;

    -- Perform the update, only touching provided columns
    UPDATE promo_code
       SET
         "value"        = COALESCE(p_value,        "value"),
         restaurant_id  = COALESCE(p_restaurant_id, restaurant_id)
     WHERE promo_id = p_promo_id;
END;
$$;

CREATE FUNCTION public.update_promotion(p_promotion character varying, p_start_date date, p_end_date date, p_restaurant_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
    DECLARE
        rows_updated INT;
        begin
            UPDATE promotion
            SET
                promotion = p_promotion,
                start_date = p_start_date,
                end_date = p_end_date
            WHERE restaurant_id = p_restaurant_id;
            IF rows_updated = 0 THEN
                RETURN 'Promotion does not exist';
            ELSE
                RETURN 'Promotion Update Successful!';
            end IF;
        end;
    $$;


ALTER FUNCTION public.update_promotion(p_promotion character varying, p_start_date date, p_end_date date, p_restaurant_id integer) OWNER TO deedee;

--
-- Name: update_restaurant(integer, time without time zone, time without time zone, character varying, character varying, bigint, character varying, character varying, character varying, text, character varying); Type: FUNCTION; Schema: public; Owner: deedee
--

CREATE FUNCTION public.update_restaurant(p_restaurant_id integer, p_open_time time without time zone DEFAULT NULL::time without time zone, p_close_time time without time zone DEFAULT NULL::time without time zone, p_location character varying DEFAULT NULL::character varying, p_email character varying DEFAULT NULL::character varying, p_contact_number bigint DEFAULT NULL::bigint, p_restaurant_name character varying DEFAULT NULL::character varying, p_dining_style character varying DEFAULT NULL::character varying, p_country character varying DEFAULT NULL::character varying, p_about_us text DEFAULT NULL::text, p_main_cuisine character varying DEFAULT NULL::character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    updated_fields TEXT[] := ARRAY[]::TEXT[];
    result_message TEXT;
BEGIN
    -- Check if restaurant exists
    IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = p_restaurant_id) THEN
        RAISE EXCEPTION 'Restaurant with ID % does not exist.', p_restaurant_id;
    END IF;

    -- Validate open/close time if both are provided
    IF p_open_time IS NOT NULL AND p_close_time IS NOT NULL THEN
        IF p_open_time >= p_close_time THEN
            RAISE EXCEPTION 'Open time must be before close time';
        END IF;
    END IF;

    -- Validate contact number if provided
    IF p_contact_number IS NOT NULL AND LENGTH(CAST(p_contact_number AS TEXT)) < 10 THEN
        RAISE EXCEPTION 'Contact number must have at least 10 digits';
    END IF;

    -- Validate restaurant name if provided
    IF p_restaurant_name IS NOT NULL AND LENGTH(TRIM(p_restaurant_name)) = 0 THEN
        RAISE EXCEPTION 'Restaurant name cannot be empty';
    END IF;

    -- Build list of fields being updated for confirmation message
    IF p_open_time IS NOT NULL THEN updated_fields := array_append(updated_fields, 'open_time'); END IF;
    IF p_close_time IS NOT NULL THEN updated_fields := array_append(updated_fields, 'close_time'); END IF;
    IF p_location IS NOT NULL THEN updated_fields := array_append(updated_fields, 'location'); END IF;
    IF p_email IS NOT NULL THEN updated_fields := array_append(updated_fields, 'email'); END IF;
    IF p_contact_number IS NOT NULL THEN updated_fields := array_append(updated_fields, 'contact_number'); END IF;
    IF p_restaurant_name IS NOT NULL THEN updated_fields := array_append(updated_fields, 'restaurant_name'); END IF;
    IF p_dining_style IS NOT NULL THEN updated_fields := array_append(updated_fields, 'dining_style'); END IF;
    IF p_country IS NOT NULL THEN updated_fields := array_append(updated_fields, 'country'); END IF;
    IF p_about_us IS NOT NULL THEN updated_fields := array_append(updated_fields, 'about_us'); END IF;
    IF p_main_cuisine IS NOT NULL THEN updated_fields := array_append(updated_fields, 'main_cuisine'); END IF;

    -- Check if any fields are being updated
    IF array_length(updated_fields, 1) IS NULL THEN
        RETURN 'No fields specified for update. Restaurant ID ' || p_restaurant_id || ' unchanged.';
    END IF;

    -- Update only the fields that are not NULL
    UPDATE restaurant_information
    SET 
        open_time = COALESCE(p_open_time, open_time),
        close_time = COALESCE(p_close_time, close_time),
        location = COALESCE(p_location, location),
        email = COALESCE(p_email, email),
        contact_number = COALESCE(p_contact_number, contact_number),
        restaurant_name = COALESCE(p_restaurant_name, restaurant_name),
        dining_style = COALESCE(p_dining_style, dining_style),
        country = COALESCE(p_country, country),
        about_us = COALESCE(p_about_us, about_us),
        main_cuisine = COALESCE(p_main_cuisine, main_cuisine)
    WHERE restaurant_id = p_restaurant_id;

    -- Create result message
    result_message := 'Restaurant ID ' || p_restaurant_id || ' updated successfully. Updated fields: ' || array_to_string(updated_fields, ', ');
    
    RETURN result_message;
END;
$$;

CREATE FUNCTION public.update_review_picture(p_picture_url character varying, p_reservation_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
    DECLARE
        rows_updated INT;
        begin
            UPDATE review_picture
            SET
                picture_url = picture_url
            WHERE reservation_id = p_reservation_id;
            IF rows_updated = 0 THEN
                RETURN 'Restaurant does not exist';
            ELSE
                RETURN 'Picture Update Successful!';
            end IF;
        end;
    $$;


ALTER FUNCTION public.update_review_picture(p_picture_url character varying, p_reservation_id integer) OWNER TO deedee;

--
-- Name: update_table_date(integer, time without time zone, date, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: deedee
--

CREATE FUNCTION public.update_table_date(p_table_size integer, p_time_slot time without time zone, p_date date, p_capacity integer DEFAULT NULL::integer, p_max_capacity integer DEFAULT NULL::integer, p_restaurant_id integer DEFAULT NULL::integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validate the row exists
    IF NOT EXISTS (
        SELECT 1
          FROM table_date
         WHERE table_size    = p_table_size
           AND time_slot     = p_time_slot
           AND "date"        = p_date
    ) THEN
        RAISE EXCEPTION 'No table_date entry for table_size=%, time_slot=%, date=%',
            p_table_size, p_time_slot, p_date;
    END IF;

    -- Validate non-negative capacities
    IF p_capacity IS NOT NULL AND p_capacity < 0 THEN
        RAISE EXCEPTION 'capacity cannot be negative';
    END IF;
    IF p_max_capacity IS NOT NULL AND p_max_capacity < 0 THEN
        RAISE EXCEPTION 'max_capacity cannot be negative';
    END IF;

    -- If both provided, ensure capacity ≤ max_capacity
    IF p_capacity IS NOT NULL
       AND p_max_capacity IS NOT NULL
       AND p_capacity > p_max_capacity
    THEN
        RAISE EXCEPTION 'capacity (%) cannot exceed max_capacity (%)',
            p_capacity, p_max_capacity;
    END IF;

    -- If updating restaurant_id, validate it
    IF p_restaurant_id IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
             FROM restaurant_information
            WHERE restaurant_id = p_restaurant_id
       )
    THEN
        RAISE EXCEPTION 'Invalid restaurant_id: %', p_restaurant_id;
    END IF;

    -- Perform the update
    UPDATE table_date
       SET
         capacity      = COALESCE(p_capacity,      capacity),
         max_capacity  = COALESCE(p_max_capacity,  max_capacity),
         restaurant_id = COALESCE(p_restaurant_id, restaurant_id)
     WHERE table_size    = p_table_size
       AND time_slot     = p_time_slot
       AND "date"        = p_date;
END;
$$;

CREATE FUNCTION public.update_table_reservation(p_table_reservation_id integer, p_adult_number integer, p_kid_number integer, p_restaurant_id integer, p_user_id integer, p_date date, p_package_id integer, p_booking_time time without time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_old_needed   INTEGER;
    v_old_date     DATE;
    v_old_time     TIME;
    v_old_rest     INTEGER;
    v_new_needed   INTEGER := p_adult_number + p_kid_number;
    v_old_capacity INTEGER;
    v_max_cap      INTEGER;
BEGIN
    -- 1) Fetch old reservation (and validate it belongs to this user/restaurant)
    SELECT adult_number + kid_number,
           "date",
           booking_time,
           restaurant_id
      INTO v_old_needed, v_old_date, v_old_time, v_old_rest
    FROM table_reservation
    WHERE table_reservation_id = p_table_reservation_id
      AND user_id             = p_user_id
      AND restaurant_id       = p_restaurant_id
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Reservation % not found for user % at restaurant %',
            p_table_reservation_id, p_user_id, p_restaurant_id;
    END IF;

    -- 2) Restore old capacity
    UPDATE table_date
       SET capacity = capacity + v_old_needed
     WHERE restaurant_id = v_old_rest
       AND "date"        = v_old_date
       AND time_slot     = v_old_time;

    -- 3) Reserve in the new slot (lock & fetch)
    SELECT capacity
      INTO v_old_capacity
    FROM table_date
    WHERE restaurant_id = p_restaurant_id
      AND "date"        = p_date
      AND time_slot     = p_booking_time
    FOR UPDATE;

    IF FOUND THEN
        IF v_old_capacity < v_new_needed THEN
            RAISE EXCEPTION 'Not enough capacity in new slot: have %, need %',
                v_old_capacity, v_new_needed;
        END IF;
        UPDATE table_date
           SET capacity = v_old_capacity - v_new_needed
         WHERE restaurant_id = p_restaurant_id
           AND "date"        = p_date
           AND time_slot     = p_booking_time;
    ELSE
        -- initialize slot if absent
        SELECT capacity
          INTO v_max_cap
        FROM table_table
        WHERE restaurant_id = p_restaurant_id
        LIMIT 1;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'No max capacity defined for restaurant %', p_restaurant_id;
        END IF;
        IF v_max_cap < v_new_needed THEN
            RAISE EXCEPTION 'Party size % exceeds restaurant max capacity %',
                v_new_needed, v_max_cap;
        END IF;

        INSERT INTO table_date(
            table_size, time_slot, capacity, "date", restaurant_id, max_capacity
        ) VALUES (
            v_max_cap,
            p_booking_time,
            v_max_cap - v_new_needed,
            p_date,
            p_restaurant_id,
            v_max_cap
        );
    END IF;

    -- 4) Update the reservation row
    UPDATE table_reservation
       SET adult_number  = p_adult_number,
           kid_number    = p_kid_number,
           restaurant_id = p_restaurant_id,
           "date"        = p_date,
           package_id    = p_package_id,
           booking_time  = p_booking_time
     WHERE table_reservation_id = p_table_reservation_id
       AND user_id              = p_user_id;

    -- 5) Return the reservation ID
    RETURN p_table_reservation_id;
END;
$$;

CREATE FUNCTION public.update_table_review(p_table_reservation_id integer, p_comment text DEFAULT NULL::text, p_food_rating integer DEFAULT NULL::integer, p_ambiance_rating integer DEFAULT NULL::integer, p_service_rating integer DEFAULT NULL::integer, p_value_rating integer DEFAULT NULL::integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (
      SELECT 1 FROM table_review
       WHERE table_reservation_id = p_table_reservation_id
    ) THEN
        RAISE EXCEPTION 'Review for reservation % does not exist.', p_table_reservation_id;
    END IF;

    IF p_food_rating     IS NOT NULL AND p_food_rating     NOT BETWEEN 0 AND 5 THEN RAISE EXCEPTION 'food_rating % out of range.', p_food_rating;     END IF;
    IF p_ambiance_rating IS NOT NULL AND p_ambiance_rating NOT BETWEEN 0 AND 5 THEN RAISE EXCEPTION 'ambiance_rating % out of range.', p_ambiance_rating; END IF;
    IF p_service_rating  IS NOT NULL AND p_service_rating  NOT BETWEEN 0 AND 5 THEN RAISE EXCEPTION 'service_rating % out of range.', p_service_rating;  END IF;
    IF p_value_rating    IS NOT NULL AND p_value_rating    NOT BETWEEN 0 AND 5 THEN RAISE EXCEPTION 'value_rating % out of range.', p_value_rating;      END IF;

    UPDATE table_review
       SET
         comment         = COALESCE(p_comment,         comment),
         food_rating     = COALESCE(p_food_rating,     food_rating),
         ambiance_rating = COALESCE(p_ambiance_rating, ambiance_rating),
         service_rating  = COALESCE(p_service_rating,  service_rating),
         value_rating    = COALESCE(p_value_rating,    value_rating)
     WHERE table_reservation_id = p_table_reservation_id;
END;
$$;

CREATE FUNCTION public.update_table_table(p_table_table_id integer, p_capacity integer DEFAULT NULL::integer, p_quantity integer DEFAULT NULL::integer, p_restaurant_id integer DEFAULT NULL::integer) RETURNS void
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

    -- If a new restaurant_id is provided, validate it
    IF p_restaurant_id IS NOT NULL AND
       NOT EXISTS (
           SELECT 1
             FROM restaurant_information
            WHERE restaurant_id = p_restaurant_id
       )
    THEN
        RAISE EXCEPTION 'Invalid restaurant_id: %', p_restaurant_id;
    END IF;

    -- Validate positive integers if provided
    IF p_capacity IS NOT NULL AND p_capacity < 1 THEN
        RAISE EXCEPTION 'capacity must be a positive integer';
    END IF;
    IF p_quantity IS NOT NULL AND p_quantity < 1 THEN
        RAISE EXCEPTION 'quantity must be a positive integer';
    END IF;

    -- Perform the update, only touching provided columns
    UPDATE table_table
       SET
         capacity      = COALESCE(p_capacity,      capacity),
         quantity      = COALESCE(p_quantity,      quantity),
         restaurant_id = COALESCE(p_restaurant_id, restaurant_id)
     WHERE table_table_id = p_table_table_id;
END;
$$;

CREATE FUNCTION public.update_time_slot(p_time_slot_id integer, p_start_time time without time zone DEFAULT NULL::time without time zone, p_end_time time without time zone DEFAULT NULL::time without time zone, p_package_id integer DEFAULT NULL::integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    updated_fields TEXT[] := ARRAY[]::TEXT[];
    result_message TEXT;
BEGIN
    -- Check if time slot exists
    IF NOT EXISTS (SELECT 1 FROM time_slot WHERE time_slot_id = p_time_slot_id) THEN
        RAISE EXCEPTION 'Time slot with ID % does not exist.', p_time_slot_id;
    END IF;

    -- Check if package exists if package_id is provided
    IF p_package_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM package WHERE package_id = p_package_id) THEN
            RAISE EXCEPTION 'Package with ID % does not exist.', p_package_id;
        END IF;
    END IF;

    -- Validate start/end time if both are provided
    IF p_start_time IS NOT NULL AND p_end_time IS NOT NULL THEN
        IF p_start_time >= p_end_time THEN
            RAISE EXCEPTION 'Start time must be before end time';
        END IF;
    END IF;

    -- Validate start time with existing end time if only start time is provided
    IF p_start_time IS NOT NULL AND p_end_time IS NULL THEN
        IF p_start_time >= (SELECT end_time FROM time_slot WHERE time_slot_id = p_time_slot_id) THEN
            RAISE EXCEPTION 'Start time must be before existing end time';
        END IF;
    END IF;

    -- Validate end time with existing start time if only end time is provided
    IF p_end_time IS NOT NULL AND p_start_time IS NULL THEN
        IF p_end_time <= (SELECT start_time FROM time_slot WHERE time_slot_id = p_time_slot_id) THEN
            RAISE EXCEPTION 'End time must be after existing start time';
        END IF;
    END IF;

    -- Build list of fields being updated for confirmation message
    IF p_start_time IS NOT NULL THEN updated_fields := array_append(updated_fields, 'start_time'); END IF;
    IF p_end_time IS NOT NULL THEN updated_fields := array_append(updated_fields, 'end_time'); END IF;
    IF p_package_id IS NOT NULL THEN updated_fields := array_append(updated_fields, 'package_id'); END IF;

    -- Check if any fields are being updated
    IF array_length(updated_fields, 1) IS NULL THEN
        RETURN 'No fields specified for update. Time slot ID ' || p_time_slot_id || ' unchanged.';
    END IF;

    -- Update only the fields that are not NULL
    UPDATE time_slot
    SET 
        start_time = COALESCE(p_start_time, start_time),
        end_time = COALESCE(p_end_time, end_time),
        package_id = COALESCE(p_package_id, package_id)
    WHERE time_slot_id = p_time_slot_id;

    -- Create result message
    result_message := 'Time slot ID ' || p_time_slot_id || ' updated successfully. Updated fields: ' || array_to_string(updated_fields, ', ');
    
    RETURN result_message;
END;
$$;

CREATE FUNCTION public.update_user_info(p_name character varying, p_hungry_point integer, p_email_login character varying, p_email_contact character varying, p_facebook character varying, p_phone_number integer, p_date_of_birth date, p_tier character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
    DECLARE
        rows_updated INT;
        begin
            UPDATE user_info
            SET
                NAME = p_name,
                hungry_point = p_hungry_point,
                email_contact = p_email_contact,
                facebook = p_facebook,
                phone_number = p_phone_number,
                date_of_birth = p_date_of_birth,
                tier = p_tier
            WHERE email_login = p_email_login;

            GET DIAGNOSTICS  rows_updated = ROW_COUNT;

            IF rows_updated = 0 THEN
                RETURN 'User does not exist, please sign up.';
            ELSE
                RETURN 'User Update Successful!';
            end IF;
        end;
    $$;


ALTER FUNCTION public.update_user_info(p_name character varying, p_hungry_point integer, p_email_login character varying, p_email_contact character varying, p_facebook character varying, p_phone_number integer, p_date_of_birth date, p_tier character varying) OWNER TO deedee;

--
-- Name: update_user_info(integer, character varying, integer, character varying, character varying, character varying, integer, date, character varying, character varying, boolean, boolean, boolean); Type: FUNCTION; Schema: public; Owner: deedee
--

CREATE FUNCTION public.update_user_info(p_user_id integer, p_name character varying DEFAULT NULL::character varying, p_hungry_point integer DEFAULT NULL::integer, p_email_login character varying DEFAULT NULL::character varying, p_email_contact character varying DEFAULT NULL::character varying, p_facebook character varying DEFAULT NULL::character varying, p_phone_number integer DEFAULT NULL::integer, p_date_of_birth date DEFAULT NULL::date, p_tier character varying DEFAULT NULL::character varying, p_password character varying DEFAULT NULL::character varying, p_set_email_login_null boolean DEFAULT false, p_set_facebook_null boolean DEFAULT false, p_set_password_null boolean DEFAULT false) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    updated_fields TEXT[] := ARRAY[]::TEXT[];
    result_message TEXT;
    hashed_password VARCHAR(255);
BEGIN
    -- Check if user exists
    IF NOT EXISTS (SELECT 1 FROM user_info WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'User with ID % does not exist.', p_user_id;
    END IF;

    -- Validate hungry points if provided
    IF p_hungry_point IS NOT NULL AND p_hungry_point < 0 THEN
        RAISE EXCEPTION 'Hungry points cannot be negative';
    END IF;

    -- Validate user name if provided
    IF p_name IS NOT NULL AND LENGTH(TRIM(p_name)) = 0 THEN
        RAISE EXCEPTION 'User name cannot be empty';
    END IF;

    -- Validate phone number if provided
    IF p_phone_number IS NOT NULL AND LENGTH(CAST(p_phone_number AS TEXT)) < 10 THEN
        RAISE EXCEPTION 'Phone number must have at least 10 digits';
    END IF;

    -- Validate tier if provided
    IF p_tier IS NOT NULL AND p_tier NOT IN ('Red', 'Silver', 'Gold', 'Platinum') THEN
        RAISE EXCEPTION 'Tier must be one of: Red, Silver, Gold, Platinum';
    END IF;

    -- Validate date of birth if provided (must be in the past)
    IF p_date_of_birth IS NOT NULL AND p_date_of_birth >= CURRENT_DATE THEN
        RAISE EXCEPTION 'Date of birth must be in the past';
    END IF;

    -- Validate email format if provided
    IF p_email_login IS NOT NULL AND p_email_login !~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$' THEN
        RAISE EXCEPTION 'Invalid email format for login email';
    END IF;

    IF p_email_contact IS NOT NULL AND p_email_contact !~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$' THEN
        RAISE EXCEPTION 'Invalid email format for contact email';
    END IF;

    -- Hash password if provided
    IF p_password IS NOT NULL THEN
        hashed_password := MD5(p_password || 'salt_string_2024');
    END IF;

    -- Build list of fields being updated for confirmation message
    IF p_name IS NOT NULL THEN updated_fields := array_append(updated_fields, 'name'); END IF;
    IF p_hungry_point IS NOT NULL THEN updated_fields := array_append(updated_fields, 'hungry_point'); END IF;
    IF p_email_login IS NOT NULL OR p_set_email_login_null THEN updated_fields := array_append(updated_fields, 'email_login'); END IF;
    IF p_email_contact IS NOT NULL THEN updated_fields := array_append(updated_fields, 'email_contact'); END IF;
    IF p_facebook IS NOT NULL OR p_set_facebook_null THEN updated_fields := array_append(updated_fields, 'facebook'); END IF;
    IF p_phone_number IS NOT NULL THEN updated_fields := array_append(updated_fields, 'phone_number'); END IF;
    IF p_date_of_birth IS NOT NULL THEN updated_fields := array_append(updated_fields, 'date_of_birth'); END IF;
    IF p_tier IS NOT NULL THEN updated_fields := array_append(updated_fields, 'tier'); END IF;
    IF p_password IS NOT NULL OR p_set_password_null THEN updated_fields := array_append(updated_fields, 'email_pass'); END IF;

    -- Check if any fields are being updated
    IF array_length(updated_fields, 1) IS NULL THEN
        RETURN 'No fields specified for update. User ID ' || p_user_id || ' unchanged.';
    END IF;

    -- Update only the fields that are not NULL
    UPDATE user_info
    SET 
        name = CASE WHEN p_name IS NOT NULL THEN p_name ELSE name END,
        hungry_point = CASE WHEN p_hungry_point IS NOT NULL THEN p_hungry_point ELSE hungry_point END,
        email_login = CASE WHEN p_set_email_login_null THEN NULL
                           WHEN p_email_login IS NOT NULL THEN p_email_login 
                           ELSE email_login END,
        email_contact = CASE WHEN p_email_contact IS NOT NULL THEN p_email_contact ELSE email_contact END,
        facebook = CASE WHEN p_set_facebook_null THEN NULL
                        WHEN p_facebook IS NOT NULL THEN p_facebook 
                        ELSE facebook END,
        phone_number = CASE WHEN p_phone_number IS NOT NULL THEN p_phone_number ELSE phone_number END,
        date_of_birth = CASE WHEN p_date_of_birth IS NOT NULL THEN p_date_of_birth ELSE date_of_birth END,
        tier = CASE WHEN p_tier IS NOT NULL THEN p_tier ELSE tier END,
        email_pass = CASE WHEN p_set_password_null THEN NULL
                          WHEN p_password IS NOT NULL THEN hashed_password 
                          ELSE email_pass END
    WHERE user_id = p_user_id;

    -- Create result message
    result_message := 'User ID ' || p_user_id || ' updated successfully. Updated fields: ' || array_to_string(updated_fields, ', ');
    
    RETURN result_message;
END;
$_$;


ALTER FUNCTION public.update_user_info(p_user_id integer, p_name character varying, p_hungry_point integer, p_email_login character varying, p_email_contact character varying, p_facebook character varying, p_phone_number integer, p_date_of_birth date, p_tier character varying, p_password character varying, p_set_email_login_null boolean, p_set_facebook_null boolean, p_set_password_null boolean) OWNER TO deedee;

--
-- Name: update_user_promotion(integer, character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: deedee
--

CREATE FUNCTION public.update_user_promotion(p_user_id integer, p_promo_card_type character varying, p_promo_card_id integer, p_quantity integer DEFAULT NULL::integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validate the user exists
    IF NOT EXISTS (
        SELECT 1 FROM user_info WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'User ID % does not exist.', p_user_id;
    END IF;

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

    -- Update only if a new quantity is provided
    IF p_quantity IS NOT NULL THEN
        UPDATE user_promotion
           SET quantity = p_quantity
         WHERE user_id         = p_user_id
           AND promo_card_type = p_promo_card_type
           AND promo_card_id   = p_promo_card_id;
    END IF;
END;
$$;

CREATE FUNCTION public.update_voucher(p_voucher_id integer, p_value integer DEFAULT NULL::integer, p_description text DEFAULT NULL::text, p_restaurant_id integer DEFAULT NULL::integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validate voucher exists
    IF NOT EXISTS (
        SELECT 1 FROM voucher WHERE voucher_id = p_voucher_id
    ) THEN
        RAISE EXCEPTION 'Voucher ID % does not exist.', p_voucher_id;
    END IF;

    -- If updating restaurant, validate it exists
    IF p_restaurant_id IS NOT NULL AND
       NOT EXISTS (
           SELECT 1 FROM restaurant_information WHERE restaurant_id = p_restaurant_id
       )
    THEN
        RAISE EXCEPTION 'Restaurant ID % does not exist.', p_restaurant_id;
    END IF;

    -- Perform the update, only touching provided columns
    UPDATE voucher
       SET
         "value"              = COALESCE(p_value,         "value"),
         voucher_description  = COALESCE(p_description,   voucher_description),
         restaurant_id        = COALESCE(p_restaurant_id, restaurant_id)
     WHERE voucher_id = p_voucher_id;
END;
$$;

