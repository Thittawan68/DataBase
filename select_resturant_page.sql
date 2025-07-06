
CREATE OR REPLACE FUNCTION get_resturant_basic_info(
    _restaurant_id INT
)
RETURNS TABLE (
    restaurant_name VARCHAR,
    restaurant_location TEXT,
    open_time TIME,
    close_time TIME,
    dining_style VARCHAR,
    main_cuisine VARCHAR
) AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    RETURN QUERY
    SELECT ri.restaurant_name, ri.location, ri.open_time, ri.close_time, ri.dining_style, ri.main_cuisine
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

CREATE OR REPLACE FUNCTION get_all_restaurant_pictures(
    _restaurant_id INT
)
RETURNS TABLE (
    picture_id INT,
    picture_url VARCHAR,
    main_picture BOOLEAN
) AS $$
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
    
    found_name := restaurant_name;
    
    SELECT COUNT(*) INTO similar_count
    FROM restaurant_information ri
    WHERE LOWER(ri.restaurant_name) LIKE LOWER('%' || found_name || '%');
    
    similar_restaurants_count := similar_count;
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;



--package functions
CREATE OR REPLACE FUNCTION get_restaurant_packages(
    _restaurant_id INT
)
RETURNS TABLE (
    package_name VARCHAR,
    sub_package VARCHAR,
    price INT,
    end_date DATE,
    duration INT,
    number_of_dishes INT,
    number_of_people INT,
    picture_url VARCHAR
) AS $$
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
$$ LANGUAGE plpgsql;

-- Review query function
CREATE OR REPLACE FUNCTION get_restaurant_reviews(
    _restaurant_id INT
)
RETURNS TABLE (
    reviewer_name VARCHAR,
    average_rating DECIMAL(3,2),
    review_date DATE,
    package_id INT,
    picture_url VARCHAR
) AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    RETURN QUERY
    SELECT ui.name as reviewer_name,
           ROUND((COALESCE(r.food_rating, 0) + COALESCE(r.ambiance_rating, 0) + 
                  COALESCE(r.service_rating, 0) + COALESCE(r.value_rating, 0))::DECIMAL / 4, 2) as average_rating,
           r.review_date,
           tr.package_id,
           rp.picture_url
    FROM review r
    JOIN table_reservation tr ON r.reservation_id = tr.table_reservation_id
    JOIN user_info ui ON r.user_id = ui.user_id
    LEFT JOIN review_picture rp ON tr.table_reservation_id = rp.reservation_id
    WHERE tr.restaurant_id = _restaurant_id
    ORDER BY r.review_date DESC, r.review_id;
END;
$$ LANGUAGE plpgsql;

-- Get average ratings by type for a restaurant and count
CREATE OR REPLACE FUNCTION get_restaurant_average_ratings(
    _restaurant_id INT
)
RETURNS TABLE (
    food_average DECIMAL(3,2),
    food_count BIGINT,
    ambiance_average DECIMAL(3,2),
    ambiance_count BIGINT,
    service_average DECIMAL(3,2),
    service_count BIGINT,
    value_average DECIMAL(3,2),
    value_count BIGINT,
    overall_average DECIMAL(3,2),
    total_reviews BIGINT
) AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM restaurant_information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    RETURN QUERY
    SELECT ROUND(AVG(COALESCE(r.food_rating, 0))::DECIMAL, 2) as food_average,
           COUNT(CASE WHEN r.food_rating IS NOT NULL THEN 1 END) as food_count,
           ROUND(AVG(COALESCE(r.ambiance_rating, 0))::DECIMAL, 2) as ambiance_average,
           COUNT(CASE WHEN r.ambiance_rating IS NOT NULL THEN 1 END) as ambiance_count,
           ROUND(AVG(COALESCE(r.service_rating, 0))::DECIMAL, 2) as service_average,
           COUNT(CASE WHEN r.service_rating IS NOT NULL THEN 1 END) as service_count,
           ROUND(AVG(COALESCE(r.value_rating, 0))::DECIMAL, 2) as value_average,
           COUNT(CASE WHEN r.value_rating IS NOT NULL THEN 1 END) as value_count,
           ROUND(AVG((COALESCE(r.food_rating, 0) + COALESCE(r.ambiance_rating, 0) + 
                      COALESCE(r.service_rating, 0) + COALESCE(r.value_rating, 0))::DECIMAL / 4), 2) as overall_average,
           COUNT(*) as total_reviews
    FROM review r
    JOIN table_reservation tr ON r.reservation_id = tr.table_reservation_id
    WHERE tr.restaurant_id = _restaurant_id;
END;
$$ LANGUAGE plpgsql;

-- Combined query function for all related tables
CREATE OR REPLACE FUNCTION get_tags(
    _restaurant_id INT
)
RETURNS TABLE (
    data_type VARCHAR,
    value_name VARCHAR
) AS $$
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
$$ LANGUAGE plpgsql;

SELECT * FROM get_resturant_basic_info(1);

SELECT get_restaurant_packages(1);


