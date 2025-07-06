-- Test file for restaurant, picture, and package functions
-- Testing insert_restaurant_information function, and direct INSERT for pictures and packages

-- Test 1: Insert Restaurant Information Function
SELECT 'Testing insert_restaurant_information function...' as test_step;

SELECT insert_restaurant_information(
    '10:00:00'::TIME,                           -- open_time
    '22:00:00'::TIME,                           -- close_time
    '999 Test Boulevard, Test District',        -- location
    'test@testrestaurant.com',                  -- email
    1234567890,                                 -- contact_number (BIGINT)
    'Test Restaurant',                          -- restaurant_name
    'Fine Dining',                              -- dining_style
    'Thailand',                                 -- country
    'This is a test restaurant for function testing purposes.',  -- about_us
    '2024-01-01'::DATE,                         -- join_date
    'International'                             -- main_cuisine
) as new_restaurant_id;

-- Get the restaurant ID for further testing
-- Note: In a real scenario, you'd capture this ID from the function above
-- For testing, we'll assume it returns the next available ID

-- Test 2: Insert Picture (Direct INSERT since no function exists)
SELECT 'Testing picture insertion...' as test_step;

-- First, let's check what restaurant IDs exist
SELECT 'Current restaurant IDs:' as info;
SELECT restaurant_id, restaurant_name FROM restaurant_information ORDER BY restaurant_id DESC LIMIT 5;

-- Insert a test picture for the last restaurant (assuming it exists)
INSERT INTO picture (restaurant_id, main_picture, picture_url) 
VALUES (
    (SELECT MAX(restaurant_id) FROM restaurant_information), 
    true, 
    'https://example.com/test-restaurant-main.jpg'
);

SELECT 'Picture inserted successfully' as result;

-- Test 3: Insert Package (Direct INSERT since no function exists)  
SELECT 'Testing package insertion...' as test_step;

INSERT INTO package (
    restaurant_id, 
    package_name, 
    sub_package, 
    price, 
    end_date, 
    duration, 
    number_of_dishes, 
    number_of_people, 
    picture_url
) VALUES (
    (SELECT MAX(restaurant_id) FROM restaurant_information),
    'Test Special Package',
    'Dinner',
    299.99,
    '2024-12-31'::DATE,
    120,                                        -- 2 hours in minutes
    5,                                          -- number of dishes
    2,                                          -- number of people
    'https://example.com/test-package.jpg'
);

SELECT 'Package inserted successfully' as result;

-- Verification: Check if all insertions worked
SELECT 'Verification - Restaurant Information:' as verification;
SELECT restaurant_id, restaurant_name, location, email, contact_number 
FROM restaurant_information 
WHERE restaurant_name = 'Test Restaurant';

SELECT 'Verification - Picture:' as verification;
SELECT picture_id, restaurant_id, main_picture, picture_url 
FROM picture 
WHERE picture_url = 'https://example.com/test-restaurant-main.jpg';

SELECT 'Verification - Package:' as verification;
SELECT package_id, restaurant_id, package_name, sub_package, price, number_of_dishes, number_of_people
FROM package 
WHERE package_name = 'Test Special Package';

SELECT 'All tests completed!' as final_result;
