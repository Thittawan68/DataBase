CREATE OR REPLACE FUNCTION update_offers_availability(
    p_restaurant_id INT,
    p_sell_voucher BOOLEAN DEFAULT NULL,
    p_promo_code BOOLEAN DEFAULT NULL
)
    RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION update_time_slot(
    p_time_slot_id INT,
    p_start_time TIME DEFAULT NULL,
    p_end_time TIME DEFAULT NULL,
    p_package_id INT DEFAULT NULL
)
    RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION update_cuisine(
    p_cuisine_id INT,
    p_cuisine_name VARCHAR DEFAULT NULL,
    p_restaurant_id INT DEFAULT NULL,
    p_hotel_id INT DEFAULT NULL
)
    RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql;

