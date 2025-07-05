CREATE OR REPLACE FUNCTION get_cuisinename(
    _restaurant_id INT
)
RETURNS TABLE (
    cuisinename VARCHAR
) AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    RETURN QUERY
    SELECT cuisinename 
    FROM cuisine 
    WHERE cuisine.restaurant_id = _restaurant_id;
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_dining_style(
    _restaurant_id INT
)
RETURNS TABLE (
    dining_style VARCHAR
) AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    RETURN QUERY
    SELECT style_name 
    FROM dining_style 
    WHERE dining_style.restaurant_id = _restaurant_id; 
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_resturant_basic_info(
    _restaurant_id INT
)
RETURNS TABLE (
    restaurant_name VARCHAR,
    restaurant_location VARCHAR,
    open_time TIME,
    close_time TIME
) AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    RETURN QUERY
    SELECT ri.restaurant_name, ri.location, ri.open_time, ri.close_time 
    FROM restaurant_information ri
    WHERE ri.restaurant_id = _restaurant_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_resturant_picture(
    _restaurant_id INT
)
RETURNS TABLE (
    picture_url VARCHAR
) AS $$
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
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_restaurant_info_with_similar_count(
    _restaurant_id INT
)
RETURNS TABLE (
    restaurant_name VARCHAR,
    open_time TIME,
    close_time TIME,
    location VARCHAR,
    similar_restaurants_count BIGINT
) AS $$
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
    
    -- Store the name for counting
    found_name := restaurant_name;
    
    -- Count restaurants with similar names (including the current one)
    SELECT COUNT(*) INTO similar_count
    FROM restaurant_information ri
    WHERE LOWER(ri.restaurant_name) LIKE LOWER('%' || found_name || '%');
    
    -- Return the single row with all info
    similar_restaurants_count := similar_count;
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;






