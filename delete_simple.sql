
ALTER TABLE offers_availability 
DROP CONSTRAINT IF EXISTS offers_availability_restaurant_id_fkey;

ALTER TABLE offers_availability 
ADD CONSTRAINT offers_availability_restaurant_id_fkey 
    FOREIGN KEY (restaurant_id) 
    REFERENCES restaurant_information(restaurant_id) 
    ON DELETE CASCADE;

ALTER TABLE picture 
DROP CONSTRAINT IF EXISTS picture_restaurant_id_fkey;

ALTER TABLE picture 
ADD CONSTRAINT picture_restaurant_id_fkey 
    FOREIGN KEY (restaurant_id) 
    REFERENCES restaurant_information(restaurant_id) 
    ON DELETE CASCADE;

ALTER TABLE time_slot 
DROP CONSTRAINT IF EXISTS time_slot_package_id_fkey;

ALTER TABLE time_slot 
ADD CONSTRAINT time_slot_package_id_fkey 
    FOREIGN KEY (package_id) 
    REFERENCES package(package_id) 
    ON DELETE CASCADE;


ALTER TABLE package 
DROP CONSTRAINT IF EXISTS package_restaurant_id_fkey;
ALTER TABLE package 
ADD CONSTRAINT package_restaurant_id_fkey 
    FOREIGN KEY (restaurant_id) 
    REFERENCES restaurant_information(restaurant_id) 
    ON DELETE CASCADE;

ALTER TABLE facility 
DROP CONSTRAINT IF EXISTS facility_restaurant_id_fkey;
ALTER TABLE facility 
ADD CONSTRAINT facility_restaurant_id_fkey 
    FOREIGN KEY (restaurant_id) 
    REFERENCES restaurant_information(restaurant_id) 
    ON DELETE CASCADE;

ALTER TABLE cuisine 
DROP CONSTRAINT IF EXISTS cuisine_restaurant_id_fkey;
ALTER TABLE cuisine 
ADD CONSTRAINT cuisine_restaurant_id_fkey 
    FOREIGN KEY (restaurant_id) 
    REFERENCES restaurant_information(restaurant_id) 
    ON DELETE CASCADE;

ALTER TABLE dining_style 
DROP CONSTRAINT IF EXISTS dining_style_restaurant_id_fkey;
ALTER TABLE dining_style 
ADD CONSTRAINT dining_style_restaurant_id_fkey 
    FOREIGN KEY (restaurant_id) 
    REFERENCES restaurant_information(restaurant_id) 
    ON DELETE CASCADE;

ALTER TABLE location 
DROP CONSTRAINT IF EXISTS location_restaurant_id_fkey;
ALTER TABLE location 
ADD CONSTRAINT location_restaurant_id_fkey 
    FOREIGN KEY (restaurant_id) 
    REFERENCES restaurant_information(restaurant_id) 
    ON DELETE CASCADE;

ALTER TABLE table_reservation 
DROP CONSTRAINT IF EXISTS table_reservation_restaurant_id_fkey;
ALTER TABLE table_reservation 
ADD CONSTRAINT table_reservation_restaurant_id_fkey 
    FOREIGN KEY (restaurant_id) 
    REFERENCES restaurant_information(restaurant_id) 
    ON DELETE CASCADE;

ALTER TABLE favorite 
DROP CONSTRAINT IF EXISTS favorite_restaurant_id_fkey;
ALTER TABLE favorite 
ADD CONSTRAINT favorite_restaurant_id_fkey 
    FOREIGN KEY (restaurant_id) 
    REFERENCES restaurant_information(restaurant_id) 
    ON DELETE CASCADE;

ALTER TABLE promo_code 
DROP CONSTRAINT IF EXISTS promo_code_restaurant_id_fkey;
ALTER TABLE promo_code 
ADD CONSTRAINT promo_code_restaurant_id_fkey 
    FOREIGN KEY (restaurant_id) 
    REFERENCES restaurant_information(restaurant_id) 
    ON DELETE CASCADE;

ALTER TABLE table_review 
DROP CONSTRAINT IF EXISTS review_reservation_id_fkey;
ALTER TABLE table_review 
ADD CONSTRAINT review_reservation_id_fkey 
    FOREIGN KEY (restaurant_id) 
    REFERENCES restaurant_information(restaurant_id) 
    ON DELETE CASCADE;

ALTER TABLE review_picture 
DROP CONSTRAINT IF EXISTS review_picture_reservation_id_fkey;

ALTER TABLE review_picture 
ADD CONSTRAINT review_picture_reservation_id_fkey 
    FOREIGN KEY (reservation_id) 
    REFERENCES table_reservation(table_reservation_id) 
    ON DELETE CASCADE;

ALTER TABLE package_type 
DROP CONSTRAINT IF EXISTS package_type_package_id_fkey;
ALTER TABLE package_type 
ADD CONSTRAINT package_type_package_id_fkey 
    FOREIGN KEY (package_id) 
    REFERENCES package(package_id) 
    ON DELETE CASCADE;

ALTER TABLE promotion 
DROP CONSTRAINT IF EXISTS promotion_restaurant_id_fkey;
ALTER TABLE promotion 
ADD CONSTRAINT promotion_restaurant_id_fkey 
    FOREIGN KEY (restaurant_id) 
    REFERENCES restaurant_information(restaurant_id) 
    ON DELETE CASCADE;

ALTER TABLE promotion 
DROP CONSTRAINT IF EXISTS promotion_package_id_fkey;
ALTER TABLE promotion 
ADD CONSTRAINT promotion_package_id_fkey 
    FOREIGN KEY (package_id) 
    REFERENCES package(package_id) 
    ON DELETE CASCADE;


CREATE OR REPLACE FUNCTION delete_restaurant_cascade(p_restaurant_id INTEGER)
RETURNS TEXT AS $$
DECLARE
    restaurant_name_var TEXT;
    result_message TEXT;
BEGIN
    SELECT restaurant_name INTO restaurant_name_var 
    FROM restaurant_information 
    WHERE restaurant_id = p_restaurant_id;
    
    IF restaurant_name_var IS NULL THEN
        RAISE EXCEPTION 'Restaurant with ID % does not exist', p_restaurant_id;
    END IF;
    
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_package_cascade(p_package_id INTEGER)
RETURNS TEXT AS $$
DECLARE
    package_name_var TEXT;
    restaurant_id_var INTEGER;
    result_message TEXT;
BEGIN
    SELECT package_name, restaurant_id INTO package_name_var, restaurant_id_var
    FROM package 
    WHERE package_id = p_package_id;
    
    IF package_name_var IS NULL THEN
        RAISE EXCEPTION 'Package with ID % does not exist', p_package_id;
    END IF;
    

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
$$ LANGUAGE plpgsql;

