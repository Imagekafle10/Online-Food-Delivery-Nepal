-- =====================================================================
-- Dummy seed data for the Foodie app / Multi Hotel-Restaurant backend
-- Run AFTER migrations/schema.sql has already created the tables:
--
--   mysql -u root -p hotel_management_app < seed_dummy_data.sql
--
-- Login credentials created by this script (password is the same for both):
--   Business owner -> identifier: owner@foodie.test   password: password123
--   Customer       -> identifier: customer@foodie.test password: password123
--
-- The password hashes below are real bcrypt hashes (10 rounds) of
-- "password123" - login will work immediately, no need to register
-- through the app for these two accounts.
-- =====================================================================

USE hotel_management_app;

-- ---------------------------------------------------------------------
-- USERS
-- ---------------------------------------------------------------------
INSERT INTO users (uuid, full_name, email, phone, password_hash, role, is_active, is_verified)
VALUES
  (UUID(), 'Raj Restaurant Owner', 'owner@foodie.test', '9800000001',
   '$2b$10$LLwahSep/o.JMzU02kxaMurL3Qc3ZqvWhdktpyI3Prrt.wQX13Yku', 'business_owner', 1, 1),
  (UUID(), 'Test Customer', 'customer@foodie.test', '9800000002',
   '$2b$10$z0xyXEIqiSpQnL4K.rS5Q.8FMBRTHTjnFOJPFGky.M6SbfIJDEMgm', 'customer', 1, 1);

SET @owner_id = (SELECT id FROM users WHERE email = 'owner@foodie.test');
SET @customer_id = (SELECT id FROM users WHERE email = 'customer@foodie.test');

-- ---------------------------------------------------------------------
-- BUSINESS - pre-approved and open, so it shows up in Discover immediately
-- ---------------------------------------------------------------------
INSERT INTO businesses (
  uuid, owner_id, name, slug, type, description, logo_url, cover_image_url,
  phone, email, address, city, latitude, longitude,
  has_food_ordering, has_table_booking, has_room_booking,
  delivery_radius_km, base_delivery_fee, min_order_amount, avg_prep_time_mins,
  status, is_open, opens_at, closes_at
) VALUES (
  UUID(), @owner_id, 'Golden Spoon Restaurant', 'golden-spoon-restaurant', 'restaurant',
  'Authentic Nepali & Indian cuisine, made fresh and delivered hot.',
  'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200',
  'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
  '9800000001', 'owner@foodie.test', 'New Road', 'Nepalgunj', 28.0500, 81.6167,
  1, 1, 0,
  5.00, 60.00, 200.00, 25,
  'approved', 1, '08:00:00', '22:00:00'
);

SET @business_id = (SELECT id FROM businesses WHERE slug = 'golden-spoon-restaurant');

-- A second business so the list/filter UI has more than one card to show
INSERT INTO businesses (
  uuid, owner_id, name, slug, type, description, logo_url, cover_image_url,
  phone, email, address, city, latitude, longitude,
  has_food_ordering, has_table_booking, has_room_booking,
  delivery_radius_km, base_delivery_fee, min_order_amount, avg_prep_time_mins,
  status, is_open, opens_at, closes_at
) VALUES (
  UUID(), @owner_id, 'Cafe Mocha', 'cafe-mocha', 'cafe',
  'Coffee, pastries, and quick bites.',
  'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=200',
  'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800',
  '9800000003', 'cafemocha@foodie.test', 'Surkhet Road', 'Nepalgunj', 28.0520, 81.6200,
  1, 1, 0,
  4.00, 40.00, 100.00, 15,
  'approved', 1, '07:00:00', '21:00:00'
);

SET @cafe_id = (SELECT id FROM businesses WHERE slug = 'cafe-mocha');

-- ---------------------------------------------------------------------
-- MENU - Golden Spoon Restaurant
-- ---------------------------------------------------------------------
INSERT INTO menu_categories (business_id, name, sort_order, is_active) VALUES
  (@business_id, 'Starters', 1, 1),
  (@business_id, 'Main Course', 2, 1),
  (@business_id, 'Beverages', 3, 1);

SET @cat_starters = (SELECT id FROM menu_categories WHERE business_id = @business_id AND name = 'Starters');
SET @cat_mains = (SELECT id FROM menu_categories WHERE business_id = @business_id AND name = 'Main Course');
SET @cat_bev = (SELECT id FROM menu_categories WHERE business_id = @business_id AND name = 'Beverages');

INSERT INTO menu_items (business_id, category_id, name, description, price, discount_percent, image_url, is_veg, is_available, prep_time_mins, tags) VALUES
  (@business_id, @cat_starters, 'Veg Momo', 'Steamed dumplings with veggie filling, served with tomato achar', 180.00, NULL,
    'https://images.unsplash.com/photo-1626804475297-411d9e582e12?w=400', 1, 1, 15, 'popular,spicy'),
  (@business_id, @cat_starters, 'Chicken Chili', 'Crispy chicken tossed in a spicy chili sauce', 320.00, 12.50,
    'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400', 0, 1, 20, 'popular'),
  (@business_id, @cat_mains, 'Chicken Biryani', 'Fragrant basmati rice cooked with spiced chicken', 420.00, NULL,
    'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=400', 0, 1, 30, 'bestseller'),
  (@business_id, @cat_mains, 'Paneer Butter Masala', 'Cottage cheese cubes in a rich tomato-butter gravy', 350.00, NULL,
    'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=400', 1, 1, 25, 'popular'),
  (@business_id, @cat_mains, 'Veg Thali', 'Dal, rice, two curries, salad and pickle', 300.00, NULL,
    'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400', 1, 1, 20, NULL),
  (@business_id, @cat_bev, 'Masala Tea', 'Spiced milk tea', 60.00, NULL,
    'https://images.unsplash.com/photo-1571934811356-5cc061b6821f?w=400', 1, 1, 5, NULL),
  (@business_id, @cat_bev, 'Fresh Lime Soda', 'Sweet or salted, served chilled', 90.00, NULL,
    'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=400', 1, 1, 5, NULL);

-- ---------------------------------------------------------------------
-- MENU - Cafe Mocha
-- ---------------------------------------------------------------------
INSERT INTO menu_categories (business_id, name, sort_order, is_active) VALUES
  (@cafe_id, 'Coffee', 1, 1),
  (@cafe_id, 'Snacks', 2, 1);

SET @cat_coffee = (SELECT id FROM menu_categories WHERE business_id = @cafe_id AND name = 'Coffee');
SET @cat_snacks = (SELECT id FROM menu_categories WHERE business_id = @cafe_id AND name = 'Snacks');

INSERT INTO menu_items (business_id, category_id, name, description, price, discount_percent, image_url, is_veg, is_available, prep_time_mins, tags) VALUES
  (@cafe_id, @cat_coffee, 'Cappuccino', 'Espresso with steamed milk foam', 150.00, NULL,
    'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400', 1, 1, 8, 'popular'),
  (@cafe_id, @cat_coffee, 'Cafe Latte', 'Smooth espresso with steamed milk', 160.00, NULL,
    'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400', 1, 1, 8, NULL),
  (@cafe_id, @cat_snacks, 'Chicken Sandwich', 'Grilled chicken, lettuce and mayo on toasted bread', 220.00, NULL,
    'https://images.unsplash.com/photo-1553909489-cd47e0ef937f?w=400', 0, 1, 12, NULL),
  (@cafe_id, @cat_snacks, 'Chocolate Croissant', 'Buttery, flaky, filled with chocolate', 140.00, NULL,
    'https://images.unsplash.com/photo-1623334044303-241021148842?w=400', 1, 1, 5, 'popular');

-- ---------------------------------------------------------------------
-- CUSTOMER'S SAVED ADDRESS - so checkout has one ready to select
-- ---------------------------------------------------------------------
INSERT INTO user_addresses (user_id, label, address_line, city, latitude, longitude, is_default)
VALUES (@customer_id, 'Home', 'Ward 5, Dhambhoji Chowk', 'Nepalgunj', 28.0530, 81.6180, 1);

-- ---------------------------------------------------------------------
-- Done. Quick sanity check:
-- ---------------------------------------------------------------------
SELECT id, name, type, status, is_open, has_food_ordering FROM businesses;
SELECT id, name, price, is_available FROM menu_items ORDER BY business_id, category_id;