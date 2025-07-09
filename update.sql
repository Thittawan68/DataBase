-- Single comprehensive function to update restaurant information
-- Use named parameters to update only specific fields
CREATE OR REPLACE FUNCTION update_restaurant(
    p_restaurant_id INT,
    p_open_time TIME DEFAULT NULL,
    p_close_time TIME DEFAULT NULL,
    p_location VARCHAR DEFAULT NULL,
    p_email VARCHAR DEFAULT NULL,
    p_contact_number BIGINT DEFAULT NULL,
    p_restaurant_name VARCHAR DEFAULT NULL,
    p_dining_style VARCHAR DEFAULT NULL,
    p_country VARCHAR DEFAULT NULL,
    p_about_us TEXT DEFAULT NULL,
    p_main_cuisine VARCHAR DEFAULT NULL
)
    RETURNS TEXT AS $$
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
    IF p_contact_number IS NOT NULL AND LENGTH(CAST(p_contact_number AS TEXT)) < 300 THEN
        RAISE EXCEPTION 'Contact number must have at least 300 digits';
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
$$ LANGUAGE plpgsql;

-- Single comprehensive function to update package information
-- Use named parameters to update only specific fields
CREATE OR REPLACE FUNCTION update_package(
    p_package_id INT,
    p_restaurant_id INT DEFAULT NULL,
    p_package_name VARCHAR DEFAULT NULL,
    p_sub_package VARCHAR DEFAULT NULL,
    p_price DECIMAL DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_duration INT DEFAULT NULL,
    p_number_of_dishes INT DEFAULT NULL,
    p_number_of_people INT DEFAULT NULL,
    p_picture_url VARCHAR DEFAULT NULL
)
    RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql;

-- Single comprehensive function to update picture information
-- Use named parameters to update only specific fields
CREATE OR REPLACE FUNCTION update_picture(
    p_picture_id INT,
    p_restaurant_id INT DEFAULT NULL,
    p_main_picture BOOLEAN DEFAULT NULL,
    p_picture_url VARCHAR DEFAULT NULL
)
    RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION update_package_type(
    p_package_id INT,
    p_all_you_can_eat BOOLEAN DEFAULT NULL,
    p_party_pack BOOLEAN DEFAULT NULL,
    p_xperience BOOLEAN DEFAULT NULL
)
    RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION update_location(
    p_location_id INT,
    p_restaurant_id INT DEFAULT NULL,
    p_location_type VARCHAR DEFAULT NULL,
    p_location_name VARCHAR DEFAULT NULL
)
    RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql;










