CREATE OR REPLACE FUNCTION delete_picture(p_picture_id INTEGER)
RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_package_types_by_package(p_package_id INTEGER)
RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql;

-- Function to delete a time_slot entry by its ID
CREATE OR REPLACE FUNCTION delete_time_slot(p_time_slot_id INTEGER)
RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION delete_time_slots_by_package(p_package_id INTEGER)
RETURNS TEXT AS $$
DECLARE
    package_name_var TEXT;
    slot_count INTEGER;
    result_message TEXT;
BEGIN
    SELECT package_name INTO package_name_var
    FROM package 
    WHERE package_id = p_package_id;
    
    IF package_name_var IS NULL THEN
        RAISE EXCEPTION 'Package with ID % does not exist', p_package_id;
    END IF;
    
    SELECT COUNT(*) INTO slot_count
    FROM time_slot 
    WHERE package_id = p_package_id;
    
    DELETE FROM time_slot WHERE package_id = p_package_id;
    
    result_message := 'All ' || slot_count || ' time slots for package "' || package_name_var || 
                     '" (ID: ' || p_package_id || ') successfully deleted';
    
    RETURN result_message;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error deleting time slots: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_cuisine(p_cuisine_id INTEGER)
RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_cuisines_by_restaurant(p_restaurant_id INTEGER)
RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_cuisines_by_hotel(p_hotel_id INTEGER)
RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_offers_availability(p_restaurant_id INTEGER)
RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_location(p_location_id INTEGER)
RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_locations_by_restaurant(p_restaurant_id INTEGER)
RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql;
