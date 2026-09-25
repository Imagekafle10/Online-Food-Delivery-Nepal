-- =====================================================================
-- DUMMY SEED DATA  (for testing only)
-- 1 super admin + 5 business owners + 5 restaurants/cafes + sample menu
--
-- Password hashes below are real bcrypt ($2b$, cost 10) - no changes needed.
--
-- Run:  mysql -u root -p < seed_dummy_data.sql
-- =====================================================================
USE hotel_management_app;


-- ---------------------------------------------------------------------
-- USERS  (login = email or phone)
--   admin  : admin@bhansa.test   / Admin@123
--   owners : owner1..5@bhansa.test / Owner@123
-- ---------------------------------------------------------------------
INSERT INTO users (uuid, full_name, email, phone, password_hash, role, is_active, is_verified) VALUES
(UUID(), 'Bhansa Admin',    'admin@bhansa.test',  '9800000000', '$2b$10$Wq9iQ/2dPk60q18JbO/ai.gkbj7m8xgJzGATzla9PK1TN/z52Kada', 'super_admin',    1, 1),
(UUID(), 'Ramesh Chaudhary','owner1@bhansa.test', '9800000001', '$2b$10$w7oOasZDMTNQjH1HlGGtAefudUbfnIJMmTtipvmDAnuS8Q903tgTC', 'business_owner', 1, 1),
(UUID(), 'Sita Bohara',     'owner2@bhansa.test', '9800000002', '$2b$10$w7oOasZDMTNQjH1HlGGtAefudUbfnIJMmTtipvmDAnuS8Q903tgTC', 'business_owner', 1, 1),
(UUID(), 'Anil Joshi',      'owner3@bhansa.test', '9800000003', '$2b$10$w7oOasZDMTNQjH1HlGGtAefudUbfnIJMmTtipvmDAnuS8Q903tgTC', 'business_owner', 1, 1),
(UUID(), 'Pooja Rawal',     'owner4@bhansa.test', '9800000004', '$2b$10$w7oOasZDMTNQjH1HlGGtAefudUbfnIJMmTtipvmDAnuS8Q903tgTC', 'business_owner', 1, 1),
(UUID(), 'Kiran Thapa',     'owner5@bhansa.test', '9800000005', '$2b$10$w7oOasZDMTNQjH1HlGGtAefudUbfnIJMmTtipvmDAnuS8Q903tgTC', 'business_owner', 1, 1);

-- ---------------------------------------------------------------------
-- BUSINESSES  (3 restaurants + 2 cafes, all approved and open)
-- ---------------------------------------------------------------------
INSERT INTO businesses
 (uuid, owner_id, name, slug, type, description, phone, email, address, city, latitude, longitude,
  has_food_ordering, has_table_booking, has_room_booking, delivery_radius_km, base_delivery_fee,
  min_order_amount, avg_prep_time_mins, status, is_open, opens_at, closes_at)
VALUES
(UUID(), (SELECT id FROM users WHERE email='owner1@bhansa.test'),
 'Himalayan Spice Kitchen', 'himalayan-spice-kitchen', 'restaurant',
 'Nepali thali, curries and tandoor specials.', '9810000001', 'spice@bhansa.test',
 'Traffic Chowk, Butwal', 'Butwal', 27.7005000, 83.4485000,
 1, 1, 0, 6.00, 60.00, 200.00, 25, 'approved', 1, '09:00:00', '22:00:00'),

(UUID(), (SELECT id FROM users WHERE email='owner2@bhansa.test'),
 'Karnali Momo House', 'karnali-momo-house', 'restaurant',
 'Steamed, fried and jhol momo with fresh achar.', '9810000002', 'momo@bhansa.test',
 'Milanchowk, Butwal', 'Butwal', 27.6920000, 83.4470000,
 1, 1, 0, 5.00, 50.00, 150.00, 20, 'approved', 1, '10:00:00', '21:30:00'),

(UUID(), (SELECT id FROM users WHERE email='owner3@bhansa.test'),
 'Tharu Bhoj Ghar', 'tharu-bhoj-ghar', 'restaurant',
 'Traditional Tharu cuisine: dhikri, ghonghi and sidhra.', '9810000003', 'tharu@bhansa.test',
 'Kalikanagar, Butwal', 'Butwal', 27.6800000, 83.4430000,
 1, 1, 0, 5.00, 50.00, 250.00, 30, 'approved', 1, '11:00:00', '21:00:00'),

(UUID(), (SELECT id FROM users WHERE email='owner4@bhansa.test'),
 'Brew & Bean Cafe', 'brew-and-bean-cafe', 'cafe',
 'Coffee, shakes, sandwiches and desserts.', '9810000004', 'brew@bhansa.test',
 'Manigram Chowk, Manigram', 'Manigram', 27.6610000, 83.4420000,
 1, 1, 0, 4.00, 40.00, 100.00, 12, 'approved', 1, '07:30:00', '21:00:00'),

(UUID(), (SELECT id FROM users WHERE email='owner5@bhansa.test'),
 'Cafe Mahakali', 'cafe-mahakali', 'cafe',
 'Cozy cafe with tea, baked goods and light snacks.', '9810000005', 'mahakali@bhansa.test',
 'Manigram Bazaar, Manigram', 'Manigram', 27.6580000, 83.4400000,
 1, 1, 0, 4.00, 40.00, 100.00, 10, 'approved', 1, '08:00:00', '20:30:00');

-- Link each owner as manager of their own business
INSERT INTO business_staff (business_id, user_id, role)
SELECT id, owner_id, 'manager' FROM businesses
WHERE slug IN ('himalayan-spice-kitchen','karnali-momo-house','tharu-bhoj-ghar','brew-and-bean-cafe','cafe-mahakali');

-- ---------------------------------------------------------------------
-- SAMPLE MENU (one category per business, 2 items each)
-- ---------------------------------------------------------------------
INSERT INTO menu_categories (business_id, name, sort_order)
SELECT id, 'Popular', 1 FROM businesses
WHERE slug IN ('himalayan-spice-kitchen','karnali-momo-house','tharu-bhoj-ghar','brew-and-bean-cafe','cafe-mahakali');

INSERT INTO menu_items (business_id, category_id, name, description, price, is_veg, prep_time_mins)
SELECT b.id, c.id, v.item_name, v.descr, v.price, v.is_veg, v.prep
FROM (
  SELECT 'himalayan-spice-kitchen' AS slug, 'Chicken Thali'  AS item_name, 'Rice, dal, chicken curry, saag, achar' AS descr, 350.00 AS price, 0 AS is_veg, 25 AS prep
  UNION ALL SELECT 'himalayan-spice-kitchen', 'Paneer Butter Masala', 'Creamy paneer curry with naan', 320.00, 1, 20
  UNION ALL SELECT 'karnali-momo-house', 'Chicken Steam Momo', '10 pcs with tomato achar', 180.00, 0, 15
  UNION ALL SELECT 'karnali-momo-house', 'Veg Jhol Momo', '10 pcs in spicy soup', 160.00, 1, 15
  UNION ALL SELECT 'tharu-bhoj-ghar', 'Dhikri Set', 'Rice-flour dhikri with gravy and pickle', 300.00, 1, 30
  UNION ALL SELECT 'tharu-bhoj-ghar', 'Ghonghi Curry', 'Snail curry, Tharu style', 380.00, 0, 30
  UNION ALL SELECT 'brew-and-bean-cafe', 'Cappuccino', 'Espresso with steamed milk foam', 220.00, 1, 8
  UNION ALL SELECT 'brew-and-bean-cafe', 'Club Sandwich', 'Grilled, with fries', 280.00, 0, 12
  UNION ALL SELECT 'cafe-mahakali', 'Masala Tea', 'Fresh ginger and cardamom tea', 80.00, 1, 5
  UNION ALL SELECT 'cafe-mahakali', 'Chocolate Brownie', 'Warm brownie with ice cream', 200.00, 1, 8
) v
JOIN businesses b ON b.slug = v.slug
JOIN menu_categories c ON c.business_id = b.id AND c.name = 'Popular';