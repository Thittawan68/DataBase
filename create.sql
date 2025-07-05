CREATE TABLE offers_availability (
    restaurant_id INT NOT NULL,
    sell_voucher BOOLEAN NOT NULL DEFAULT FALSE,
    sell_delivery BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (restaurant_id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurant_information(restaurant_id)
);

CREATE TABLE payment_Methods (
    user_id INT NOT NULL,
    Card_Number INT NOT NULL,
    Card_Type VARCHAR(50) NOT NULL,
    Card_Brand VARCHAR(50) NOT NULL,
    PRIMARY KEY (User_ID, Card_Number),
    FOREIGN KEY (User_ID) REFERENCES user_info(user_id)
);

CREATE TABLE user_promotion (
    user_id INT NOT NULL,
    promo_card_type VARCHAR(50) NOT NULL,
    promo_card_id INT NOT NULL,
    PRIMARY KEY (user_id, promo_card_type, promo_card_id),
    FOREIGN KEY (user_id) REFERENCES user_info(user_id)
);

CREATE TABLE HOTEL (
    hotel_id SERIAL PRIMARY KEY,
    hotel_name VARCHAR(100) NOT NULL,
    hotel_location INT NOT NULL
);

CREATE TABLE time_Slot (
    time_slot_id SERIAL PRIMARY KEY,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    package_ID INT NOT NULL,
    FOREIGN KEY (package_ID) REFERENCES Package(package_id)
);