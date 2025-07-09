-- Populate user_info table with 9 users
-- 2 users with Facebook login only (no email_login)
-- 7 users with email_login for regular authentication

-- Users with Facebook login only (no email/password authentication)
SELECT insert_user_info(
    'Sarah Johnson',           -- name
    150,                      -- hungry_point
    NULL,                     -- email_login (NULL for Facebook-only users)
    'sarah.johnson@gmail.com', -- email_contact
    'sarah.johnson.fb',        -- facebook
    2125551234,               -- phone_number
    '1992-03-15',             -- date_of_birth
    'Gold',                   -- tier
    NULL                      -- password (NULL for Facebook users)
);

SELECT insert_user_info(
    'Michael Chen',           -- name
    75,                       -- hungry_point
    NULL,                     -- email_login (NULL for Facebook-only users)
    'michael.chen@yahoo.com', -- email_contact
    'michael.chen.social',    -- facebook
    2125555678,               -- phone_number
    '1988-07-22',             -- date_of_birth
    'Silver',                 -- tier
    NULL                      -- password (NULL for Facebook users)
);

-- Regular users with email/password authentication
SELECT insert_user_info(
    'Emma Rodriguez',         -- name
    200,                      -- hungry_point
    'emma.rodriguez@gmail.com', -- email_login
    'emma.rodriguez2@gmail.com', -- email_contact (same as login)
    NULL,                     -- facebook (NULL for email users)
    2125559876,               -- phone_number
    '1995-11-08',             -- date_of_birth
    'Platinum',               -- tier
    'EmmaPass123!'            -- password
);

SELECT insert_user_info(
    'David Thompson',         -- name
    120,                      -- hungry_point
    'david.thompson@outlook.com', -- email_login
    'david.thompson2@outlook.com', -- email_contact
    NULL,                     -- facebook
    2125554321,               -- phone_number
    '1990-01-30',             -- date_of_birth
    'Gold',                   -- tier
    'DavidSecure2024'         -- password
);

SELECT insert_user_info(
    'Lisa Park',              -- name
    95,                       -- hungry_point
    'lisa.park@hotmail.com',  -- email_login
    'lisa.park2@hotmail.com',  -- email_contact
    NULL,                     -- facebook
    2125558765,               -- phone_number
    '1993-09-12',             -- date_of_birth
    'Silver',                 -- tier
    'LisaP@ssw0rd'           -- password
);

SELECT insert_user_info(
    'James Wilson',           -- name
    180,                      -- hungry_point
    'james.wilson@gmail.com', -- email_login
    'james.wilson@gmail.com', -- email_contact
    NULL,                     -- facebook
    2125552468,               -- phone_number
    '1987-05-18',             -- date_of_birth
    'Gold',                   -- tier
    'JamesW1ls0n!'           -- password
);

SELECT insert_user_info(
    'Ana Martinez',           -- name
    60,                       -- hungry_point
    'ana.martinez@yahoo.com', -- email_login
    'ana.martinez@yahoo.com', -- email_contact
    NULL,                     -- facebook
    2125557890,               -- phone_number
    '1996-12-03',             -- date_of_birth
    'Red',                    -- tier
    'AnaM2024$'              -- password
);

SELECT insert_user_info(
    'Robert Kim',             -- name
    250,                      -- hungry_point
    'robert.kim@gmail.com',   -- email_login
    'robert.kim@gmail.com',   -- email_contact
    NULL,                     -- facebook
    2125553579,               -- phone_number
    '1985-08-25',             -- date_of_birth
    'Platinum',               -- tier
    'RobertK!m123'           -- password
);

SELECT insert_user_info(
    'Sophie Brown',           -- name
    140,                      -- hungry_point
    'sophie.brown@outlook.com', -- email_login
    'sophie.brown@outlook.com', -- email_contact
    NULL,                     -- facebook
    2125556420,               -- phone_number
    '1991-04-14',             -- date_of_birth
    'Gold',                   -- tier
    'SophieB_2024'           -- password
);

-- Verify the insertions and add reviews for Chinese restaurant (id = 9)
SELECT user_id, name, hungry_point, email_login, email_contact, facebook, phone_number, date_of_birth, tier,
       CASE 
           WHEN password_hash IS NOT NULL THEN 'HASHED_PASSWORD_SET'
           ELSE 'NO_PASSWORD'
       END as password_status
FROM user_info 
ORDER BY user_id;

-- Summary of users by authentication type
SELECT 
    CASE 
        WHEN facebook IS NOT NULL AND email_login IS NULL THEN 'Facebook Only'
        WHEN email_login IS NOT NULL AND facebook IS NULL THEN 'Email/Password'
        ELSE 'Mixed'
    END AS auth_type,
    COUNT(*) as user_count
FROM user_info 
GROUP BY 
    CASE 
        WHEN facebook IS NOT NULL AND email_login IS NULL THEN 'Facebook Only'
        WHEN email_login IS NOT NULL AND facebook IS NULL THEN 'Email/Password'
        ELSE 'Mixed'
    END;

-- Create table reservations for each user at Chinese restaurant (id = 9)
-- Assuming table_reservation needs: restaurant_id, user_id, package_id, reservation_date

-- Sarah Johnson (Facebook user) - reservation
INSERT INTO table_reservation (restaurant_id, user_id, package_id, reservation_date, reservation_time)
VALUES (9, 1, 1, '2024-06-15', '19:00:00');

-- Michael Chen (Facebook user) - reservation  
INSERT INTO table_reservation (restaurant_id, user_id, package_id, reservation_date, reservation_time)
VALUES (9, 2, 1, '2024-06-20', '18:30:00');

-- Emma Rodriguez - reservation
INSERT INTO table_reservation (restaurant_id, user_id, package_id, reservation_date, reservation_time)
VALUES (9, 3, 2, '2024-06-25', '20:00:00');

-- David Thompson - reservation
INSERT INTO table_reservation (restaurant_id, user_id, package_id, reservation_date, reservation_time)
VALUES (9, 4, 1, '2024-07-01', '19:30:00');

-- Lisa Park - reservation
INSERT INTO table_reservation (restaurant_id, user_id, package_id, reservation_date, reservation_time)
VALUES (9, 5, 3, '2024-07-05', '18:00:00');

-- James Wilson - reservation
INSERT INTO table_reservation (restaurant_id, user_id, package_id, reservation_date, reservation_time)
VALUES (9, 6, 2, '2024-07-08', '19:15:00');

-- Ana Martinez - reservation
INSERT INTO table_reservation (restaurant_id, user_id, package_id, reservation_date, reservation_time)
VALUES (9, 7, 1, '2024-07-12', '18:45:00');

-- Robert Kim - reservation
INSERT INTO table_reservation (restaurant_id, user_id, package_id, reservation_date, reservation_time)
VALUES (9, 8, 3, '2024-07-15', '20:30:00');

-- Sophie Brown - reservation
INSERT INTO table_reservation (restaurant_id, user_id, package_id, reservation_date, reservation_time)
VALUES (9, 9, 2, '2024-07-18', '19:00:00');

-- Reviews for each user at Chinese restaurant (id = 9)
-- Assuming review table needs: reservation_id, user_id, food_rating, ambiance_rating, service_rating, value_rating, review_date, review_text

-- Sarah Johnson's review (reservation_id will be the first one created)
INSERT INTO review (reservation_id, user_id, food_rating, ambiance_rating, service_rating, value_rating, review_date, review_text)
VALUES (
    (SELECT table_reservation_id FROM table_reservation WHERE restaurant_id = 9 AND user_id = 1 LIMIT 1),
    1, 5, 4, 5, 4, '2024-06-16',
    'Amazing authentic Chinese food! The Peking duck was exceptional and the service was very attentive. Will definitely come back!'
);

-- Michael Chen's review
INSERT INTO review (reservation_id, user_id, food_rating, ambiance_rating, service_rating, value_rating, review_date, review_text)
VALUES (
    (SELECT table_reservation_id FROM table_reservation WHERE restaurant_id = 9 AND user_id = 2 LIMIT 1),
    2, 4, 5, 4, 4, '2024-06-21',
    'Great atmosphere and delicious dim sum. The restaurant has a nice traditional Chinese decor. Good value for money.'
);

-- Emma Rodriguez's review
INSERT INTO review (reservation_id, user_id, food_rating, ambiance_rating, service_rating, value_rating, review_date, review_text)
VALUES (
    (SELECT table_reservation_id FROM table_reservation WHERE restaurant_id = 9 AND user_id = 3 LIMIT 1),
    3, 5, 5, 5, 5, '2024-06-26',
    'Perfect dining experience! Every dish was flavorful and beautifully presented. The staff was incredibly helpful and friendly.'
);

-- David Thompson's review
INSERT INTO review (reservation_id, user_id, food_rating, ambiance_rating, service_rating, value_rating, review_date, review_text)
VALUES (
    (SELECT table_reservation_id FROM table_reservation WHERE restaurant_id = 9 AND user_id = 4 LIMIT 1),
    4, 4, 4, 3, 4, '2024-07-02',
    'Good Chinese food with reasonable prices. The kung pao chicken was tasty but service was a bit slow during peak hours.'
);

-- Lisa Park's review
INSERT INTO review (reservation_id, user_id, food_rating, ambiance_rating, service_rating, value_rating, review_date, review_text)
VALUES (
    (SELECT table_reservation_id FROM table_reservation WHERE restaurant_id = 9 AND user_id = 5 LIMIT 1),
    5, 3, 4, 4, 3, '2024-07-06',
    'Decent Chinese restaurant. The sweet and sour pork was okay but not exceptional. Nice ambiance though.'
);

-- James Wilson's review
INSERT INTO review (reservation_id, user_id, food_rating, ambiance_rating, service_rating, value_rating, review_date, review_text)
VALUES (
    (SELECT table_reservation_id FROM table_reservation WHERE restaurant_id = 9 AND user_id = 6 LIMIT 1),
    6, 5, 4, 5, 5, '2024-07-09',
    'Outstanding Chinese cuisine! The mapo tofu was the best I have ever had. Excellent service and great portions.'
);

-- Ana Martinez's review
INSERT INTO review (reservation_id, user_id, food_rating, ambiance_rating, service_rating, value_rating, review_date, review_text)
VALUES (
    (SELECT table_reservation_id FROM table_reservation WHERE restaurant_id = 9 AND user_id = 7 LIMIT 1),
    7, 4, 3, 4, 4, '2024-07-13',
    'Solid Chinese food with authentic flavors. The hot pot was delicious. Restaurant could use some renovation but food quality is good.'
);

-- Robert Kim's review
INSERT INTO review (reservation_id, user_id, food_rating, ambiance_rating, service_rating, value_rating, review_date, review_text)
VALUES (
    (SELECT table_reservation_id FROM table_reservation WHERE restaurant_id = 9 AND user_id = 8 LIMIT 1),
    8, 5, 5, 4, 4, '2024-07-16',
    'Excellent Chinese restaurant with fresh ingredients. The Beijing beef was phenomenal and the tea selection was impressive.'
);

-- Sophie Brown's review
INSERT INTO review (reservation_id, user_id, food_rating, ambiance_rating, service_rating, value_rating, review_date, review_text)
VALUES (
    (SELECT table_reservation_id FROM table_reservation WHERE restaurant_id = 9 AND user_id = 9 LIMIT 1),
    9, 4, 4, 5, 4, '2024-07-19',
    'Really enjoyed the dining experience. The staff was very accommodating and the orange chicken was delicious. Great place for family dinner!'
);

-- Add review pictures for each reservation
-- Sarah Johnson's review picture
INSERT INTO review_picture (reservation_id, picture_url)
VALUES (
    (SELECT table_reservation_id FROM table_reservation WHERE restaurant_id = 9 AND user_id = 1 LIMIT 1),
    'https://example.com/reviews/sarah_chinese_food1.jpg'
);

-- Michael Chen's review picture
INSERT INTO review_picture (reservation_id, picture_url)
VALUES (
    (SELECT table_reservation_id FROM table_reservation WHERE restaurant_id = 9 AND user_id = 2 LIMIT 1),
    'https://example.com/reviews/michael_dimsum.jpg'
);

-- Emma Rodriguez's review picture
INSERT INTO review_picture (reservation_id, picture_url)
VALUES (
    (SELECT table_reservation_id FROM table_reservation WHERE restaurant_id = 9 AND user_id = 3 LIMIT 1),
    'https://example.com/reviews/emma_chinese_feast.jpg'
);

-- David Thompson's review picture
INSERT INTO review_picture (reservation_id, picture_url)
VALUES (
    (SELECT table_reservation_id FROM table_reservation WHERE restaurant_id = 9 AND user_id = 4 LIMIT 1),
    'https://example.com/reviews/david_kungpao.jpg'
);

-- Lisa Park's review picture
INSERT INTO review_picture (reservation_id, picture_url)
VALUES (
    (SELECT table_reservation_id FROM table_reservation WHERE restaurant_id = 9 AND user_id = 5 LIMIT 1),
    'https://example.com/reviews/lisa_sweetandsour.jpg'
);

-- James Wilson's review picture
INSERT INTO review_picture (reservation_id, picture_url)
VALUES (
    (SELECT table_reservation_id FROM table_reservation WHERE restaurant_id = 9 AND user_id = 6 LIMIT 1),
    'https://example.com/reviews/james_mapo_tofu.jpg'
);

-- Ana Martinez's review picture
INSERT INTO review_picture (reservation_id, picture_url)
VALUES (
    (SELECT table_reservation_id FROM table_reservation WHERE restaurant_id = 9 AND user_id = 7 LIMIT 1),
    'https://example.com/reviews/ana_hotpot.jpg'
);

-- Robert Kim's review picture
INSERT INTO review_picture (reservation_id, picture_url)
VALUES (
    (SELECT table_reservation_id FROM table_reservation WHERE restaurant_id = 9 AND user_id = 8 LIMIT 1),
    'https://example.com/reviews/robert_beijing_beef.jpg'
);

-- Sophie Brown's review picture
INSERT INTO review_picture (reservation_id, picture_url)
VALUES (
    (SELECT table_reservation_id FROM table_reservation WHERE restaurant_id = 9 AND user_id = 9 LIMIT 1),
    'https://example.com/reviews/sophie_orange_chicken.jpg'
);

-- Verify all reviews and pictures were added
SELECT 'Reviews and pictures added successfully!' as result;

-- Check review summary for Chinese restaurant (id = 9)
SELECT 
    COUNT(r.*) as total_reviews,
    ROUND(AVG((r.food_rating + r.ambiance_rating + r.service_rating + r.value_rating)::DECIMAL / 4), 2) as average_rating,
    COUNT(rp.*) as total_review_pictures
FROM review r
JOIN table_reservation tr ON r.reservation_id = tr.table_reservation_id
LEFT JOIN review_picture rp ON tr.table_reservation_id = rp.reservation_id
WHERE tr.restaurant_id = 9;

