ALTER TABLE package
ADD COLUMN duration INT DEFAULT NULL;
ALTER TABLE package
ADD COLUMN number_of_dishes INT DEFAULT NULL;

ALTER TABLE package
ADD COLUMN number_of_people INT DEFAULT NULL;

ALTER TABLE table_review
ADD COLUMN food_rating INT NOT NULL,
ADD COLUMN ambiance_rating INT NOT NULL,
ADD COLUMN service_rating INT NOT NULL,
ADD COLUMN value_rating INT NOT NULL,
DROP COLUMN IF EXISTS rating;

ALTER TABLE table_review
ADD CONSTRAINT check_food_rating CHECK (food_rating >= 0 AND food_rating <= 5),
ADD CONSTRAINT check_ambiance_rating CHECK (ambiance_rating >= 0 AND ambiance_rating <= 5),
ADD CONSTRAINT check_service_rating CHECK (service_rating >= 0 AND service_rating <= 5),
ADD CONSTRAINT check_value_rating CHECK (value_rating >= 0 AND value_rating <= 5);

ALTER TABLE user_info
ADD COLUMN password_hash VARCHAR(255) DEFAULT NULL;