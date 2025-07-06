CREATE OR REPLACE FUNCTION insert_restaurant_information(
    _open_time TIME,
    _close_time TIME,
    _location VARCHAR,
    _email VARCHAR,
    _contact_number BIGINT,
    _restaurant_name VARCHAR,
    _dining_style VARCHAR,
    _country VARCHAR,
    _about_us TEXT,
    _join_date DATE,
    _main_cuisine VARCHAR
)
    RETURNS INT AS $$
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
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION insert_offers_availability(
    _restaurant_id INT,
    _sell_voucher BOOLEAN DEFAULT FALSE,
    _promo_code BOOLEAN DEFAULT FALSE
)
    RETURNS VOID AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Restaurant_Information WHERE restaurant_id = _restaurant_id) THEN
        RAISE EXCEPTION 'Invalid Restaurant_ID';
    END IF;

    INSERT INTO offers_availability(restaurant_id, sell_voucher, promo_code)
    VALUES (_restaurant_id, _sell_voucher, _promo_code);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_hotel(
    _hotel_name VARCHAR,
    _hotel_location VARCHAR(225)
)
    RETURNS INT AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_facility(
    _restaurant_id INT,
    _facility_type VARCHAR,
    _sub_facility_type VARCHAR
)
    RETURNS VOID AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_cuisine(
    _cuisine_name VARCHAR,
    _restaurant_id INT,
    _hotel_id INT
)
    RETURNS VOID AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_dining_style(
    _style_name VARCHAR,
    _restaurant_id INT,
    _hotel_id INT
)
    RETURNS VOID AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_location(
    _restaurant_id INT,
    _location_type VARCHAR,
    _location_name VARCHAR
)
    RETURNS VOID AS $$
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
$$ LANGUAGE plpgsql;

ALTER TABLE package 
ADD COLUMN package_name VARCHAR(50) DEFAULT NULL;