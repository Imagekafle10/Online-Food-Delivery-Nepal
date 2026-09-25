-- =====================================================================
-- Multi Hotel / Restaurant / Cafe / Guest House Management System
-- MySQL 8+ schema
-- =====================================================================

CREATE DATABASE IF NOT EXISTS hotel_management_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE hotel_management_app;

-- ---------------------------------------------------------------------
-- USERS (customers, business owners/staff, riders, platform admins)
-- ---------------------------------------------------------------------
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  full_name VARCHAR(150) NOT NULL,
  email VARCHAR(150) UNIQUE,
  phone VARCHAR(20) UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('customer','business_owner','staff','rider','super_admin') NOT NULL DEFAULT 'customer',
  avatar_url VARCHAR(255),
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  is_verified TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE user_addresses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  label VARCHAR(50) DEFAULT 'Home',
  address_line VARCHAR(255) NOT NULL,
  city VARCHAR(100),
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  is_default TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- BUSINESSES (tenants) - hotel / restaurant / cafe / guest_house
-- ---------------------------------------------------------------------
CREATE TABLE businesses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  owner_id INT NOT NULL,
  name VARCHAR(150) NOT NULL,
  slug VARCHAR(170) NOT NULL UNIQUE,
  type ENUM('hotel','restaurant','cafe','guest_house') NOT NULL,
  description TEXT,
  logo_url VARCHAR(255),
  cover_image_url VARCHAR(255),
  phone VARCHAR(20),
  email VARCHAR(150),
  address VARCHAR(255),
  city VARCHAR(100),
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  has_food_ordering TINYINT(1) DEFAULT 1,
  has_table_booking TINYINT(1) DEFAULT 1,
  has_room_booking TINYINT(1) DEFAULT 0,
  delivery_radius_km DECIMAL(5,2) DEFAULT 5.00,
  base_delivery_fee DECIMAL(10,2) DEFAULT 50.00,
  min_order_amount DECIMAL(10,2) DEFAULT 0.00,
  avg_prep_time_mins INT DEFAULT 20,
  commission_percent DECIMAL(5,2) DEFAULT 15.00,
  status ENUM('pending','approved','suspended','rejected') NOT NULL DEFAULT 'pending',
  is_open TINYINT(1) DEFAULT 1,
  opens_at TIME DEFAULT '08:00:00',
  closes_at TIME DEFAULT '22:00:00',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE business_staff (
  id INT AUTO_INCREMENT PRIMARY KEY,
  business_id INT NOT NULL,
  user_id INT NOT NULL,
  role ENUM('manager','kitchen','front_desk','waiter') NOT NULL DEFAULT 'manager',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_biz_user (business_id, user_id),
  FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- MENU (food ordering - primary focus)
-- ---------------------------------------------------------------------
CREATE TABLE menu_categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  business_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  sort_order INT DEFAULT 0,
  is_active TINYINT(1) DEFAULT 1,
  FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE
);

CREATE TABLE menu_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  business_id INT NOT NULL,
  category_id INT,
  name VARCHAR(150) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  discount_percent DECIMAL(5,2),
  image_url VARCHAR(255),
  is_veg TINYINT(1) DEFAULT 1,
  is_available TINYINT(1) DEFAULT 1,
  prep_time_mins INT DEFAULT 15,
  tags VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES menu_categories(id) ON DELETE SET NULL,
  CONSTRAINT chk_menu_items_discount_percent
    CHECK (discount_percent IS NULL OR (discount_percent >= 5 AND discount_percent <= 90))
);

CREATE TABLE menu_item_addons (
  id INT AUTO_INCREMENT PRIMARY KEY,
  menu_item_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  price DECIMAL(10,2) NOT NULL DEFAULT 0,
  FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- ORDERS (dine-in / pickup / delivery) - CORE of the system
-- ---------------------------------------------------------------------
CREATE TABLE orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  order_number VARCHAR(20) NOT NULL UNIQUE,
  business_id INT NOT NULL,
  user_id INT NOT NULL,
  order_type ENUM('delivery','pickup','dine_in') NOT NULL DEFAULT 'delivery',
  status ENUM('placed','accepted','cooking','on_the_way','delivered','cancelled') NOT NULL DEFAULT 'placed',
  subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
  delivery_fee DECIMAL(10,2) NOT NULL DEFAULT 0,
  tax_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  payment_method ENUM('esewa','khalti','cod') NOT NULL DEFAULT 'cod',
  payment_status ENUM('unpaid','pending','paid','failed','refunded') NOT NULL DEFAULT 'unpaid',
  delivery_address_id INT,
  delivery_latitude DECIMAL(10,7),
  delivery_longitude DECIMAL(10,7),
  delivery_instructions VARCHAR(255),
  table_id INT NULL,
  rider_id INT NULL,
  special_instructions VARCHAR(255),
  estimated_delivery_time DATETIME,
  placed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  accepted_at TIMESTAMP NULL,
  ready_at TIMESTAMP NULL,
  picked_up_at TIMESTAMP NULL,
  delivered_at TIMESTAMP NULL,
  cancelled_reason VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (business_id) REFERENCES businesses(id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (delivery_address_id) REFERENCES user_addresses(id) ON DELETE SET NULL
);

CREATE TABLE order_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  menu_item_id INT NOT NULL,
  item_name VARCHAR(150) NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  addons_json JSON,
  item_subtotal DECIMAL(10,2) NOT NULL,
  notes VARCHAR(255),
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (menu_item_id) REFERENCES menu_items(id)
);

-- Live status log for tracking screen (order history / rider path)
CREATE TABLE order_status_log (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  status VARCHAR(30) NOT NULL,
  note VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- RIDERS (delivery personnel) + live location pings
-- ---------------------------------------------------------------------
CREATE TABLE riders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL UNIQUE,
  vehicle_type ENUM('bike','scooter','bicycle','car') DEFAULT 'bike',
  vehicle_number VARCHAR(30),
  license_number VARCHAR(50),
  status ENUM('offline','available','busy') NOT NULL DEFAULT 'offline',
  current_latitude DECIMAL(10,7),
  current_longitude DECIMAL(10,7),
  rating DECIMAL(3,2) DEFAULT 5.00,
  total_deliveries INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE rider_location_pings (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  rider_id INT NOT NULL,
  order_id INT NULL,
  latitude DECIMAL(10,7) NOT NULL,
  longitude DECIMAL(10,7) NOT NULL,
  recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (rider_id) REFERENCES riders(id) ON DELETE CASCADE,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE SET NULL
);

-- ---------------------------------------------------------------------
-- TABLE BOOKING (restaurant/cafe dine-in reservations)
-- ---------------------------------------------------------------------
CREATE TABLE restaurant_tables (
  id INT AUTO_INCREMENT PRIMARY KEY,
  business_id INT NOT NULL,
  table_number VARCHAR(20) NOT NULL,
  capacity INT NOT NULL DEFAULT 2,
  location_note VARCHAR(100),
  status ENUM('available','reserved','occupied','inactive') DEFAULT 'available',
  FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE
);

CREATE TABLE table_bookings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_id INT NOT NULL,
  table_id INT NULL,
  user_id INT NOT NULL,
  guest_name VARCHAR(150) NOT NULL,
  guest_phone VARCHAR(20) NOT NULL,
  party_size INT NOT NULL DEFAULT 2,
  booking_date DATE NOT NULL,
  booking_time TIME NOT NULL,
  status ENUM('pending','confirmed','seated','completed','cancelled','no_show') DEFAULT 'pending',
  special_request VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (business_id) REFERENCES businesses(id),
  FOREIGN KEY (table_id) REFERENCES restaurant_tables(id) ON DELETE SET NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ---------------------------------------------------------------------
-- ROOM BOOKING (hotel / guest house)
-- ---------------------------------------------------------------------
CREATE TABLE rooms (
  id INT AUTO_INCREMENT PRIMARY KEY,
  business_id INT NOT NULL,
  room_number VARCHAR(20) NOT NULL,
  room_type VARCHAR(50) NOT NULL DEFAULT 'Standard',
  description TEXT,
  price_per_night DECIMAL(10,2) NOT NULL,
  capacity INT DEFAULT 2,
  image_url VARCHAR(255),
  amenities VARCHAR(255),
  status ENUM('available','maintenance','inactive') DEFAULT 'available',
  FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE
);

CREATE TABLE room_bookings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_id INT NOT NULL,
  room_id INT NOT NULL,
  user_id INT NOT NULL,
  guest_name VARCHAR(150) NOT NULL,
  guest_phone VARCHAR(20) NOT NULL,
  check_in DATE NOT NULL,
  check_out DATE NOT NULL,
  num_guests INT DEFAULT 1,
  nights INT NOT NULL,
  price_per_night DECIMAL(10,2) NOT NULL,
  total_amount DECIMAL(10,2) NOT NULL,
  payment_method ENUM('esewa','khalti','cod') NOT NULL DEFAULT 'cod',
  payment_status ENUM('unpaid','pending','paid','failed','refunded') NOT NULL DEFAULT 'unpaid',
  status ENUM('pending','confirmed','checked_in','checked_out','cancelled') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (business_id) REFERENCES businesses(id),
  FOREIGN KEY (room_id) REFERENCES rooms(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ---------------------------------------------------------------------
-- PAYMENTS (eSewa / Khalti / COD) - polymorphic against orders or room_bookings
-- ---------------------------------------------------------------------
CREATE TABLE payments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  reference_type ENUM('order','room_booking') NOT NULL,
  reference_id INT NOT NULL,
  user_id INT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  method ENUM('esewa','khalti','cod') NOT NULL,
  gateway_txn_id VARCHAR(100),
  gateway_ref_id VARCHAR(100),
  status ENUM('initiated','pending','success','failed','refunded') NOT NULL DEFAULT 'initiated',
  raw_response JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ---------------------------------------------------------------------
-- REVIEWS
-- ---------------------------------------------------------------------
CREATE TABLE reviews (
  id INT AUTO_INCREMENT PRIMARY KEY,
  business_id INT NOT NULL,
  user_id INT NOT NULL,
  order_id INT NULL,
  rating TINYINT NOT NULL,
  comment VARCHAR(500),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ---------------------------------------------------------------------
-- Indexes for hot paths
-- ---------------------------------------------------------------------
CREATE INDEX idx_menu_items_business ON menu_items(business_id, is_available);
CREATE INDEX idx_orders_business_status ON orders(business_id, status);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_rider ON orders(rider_id);
CREATE INDEX idx_riders_status ON riders(status);
CREATE INDEX idx_table_bookings_biz_date ON table_bookings(business_id, booking_date);
CREATE INDEX idx_room_bookings_room_dates ON room_bookings(room_id, check_in, check_out);
CREATE INDEX idx_businesses_type_status ON businesses(type, status);


-- =====================================================================
-- Simplify order statuses to:
--   accepted -> cooking -> on_the_way -> delivered   (cancelled if there is a problem)
--
-- Run ONCE on an existing database (fresh installs already get the new enum from schema.sql):
--   mysql -u root -p < migrations/002_simplify_order_status.sql
--
-- Old -> new mapping
--   placed                          -> accepted
--   accepted                        -> accepted
--   preparing, ready, rider_assigned-> cooking
--   picked_up, on_the_way           -> on_the_way
--   delivered, completed            -> delivered
--   cancelled, rejected             -> cancelled  (rejected keeps a reason)
-- =====================================================================
USE hotel_management_app;

-- 1) Temporarily allow old + new values together
ALTER TABLE orders MODIFY status ENUM(
  'placed','accepted','preparing','ready','rider_assigned','picked_up',
  'on_the_way','delivered','completed','cancelled','rejected','cooking'
) NOT NULL DEFAULT 'accepted';

-- 2) Convert existing rows
UPDATE orders SET cancelled_reason = COALESCE(cancelled_reason, 'Rejected by restaurant') WHERE status = 'rejected';
UPDATE orders SET status = 'accepted'   WHERE status = 'placed';
UPDATE orders SET status = 'cooking'    WHERE status IN ('preparing','ready','rider_assigned');
UPDATE orders SET status = 'on_the_way' WHERE status = 'picked_up';
UPDATE orders SET status = 'delivered'  WHERE status = 'completed';
UPDATE orders SET status = 'cancelled'  WHERE status = 'rejected';

-- Same mapping for the status history shown on the order timeline (plain VARCHAR column)
UPDATE order_status_log SET status = 'accepted'   WHERE status = 'placed';
UPDATE order_status_log SET status = 'cooking'    WHERE status IN ('preparing','ready','rider_assigned');
UPDATE order_status_log SET status = 'on_the_way' WHERE status = 'picked_up';
UPDATE order_status_log SET status = 'delivered'  WHERE status = 'completed';
UPDATE order_status_log SET status = 'cancelled'  WHERE status = 'rejected';

-- 3) Lock the column down to the final set
ALTER TABLE orders MODIFY status ENUM('accepted','cooking','on_the_way','delivered','cancelled')
  NOT NULL DEFAULT 'accepted';


-- =====================================================================
-- Re-introduce "placed" as the initial order status.
-- New flow: placed -> accepted -> cooking -> on_the_way -> delivered
--
-- Run ONCE on an existing database (after 002_simplify_order_status.sql):
--   mysql -u root -p < migrations/003_add_placed_status.sql
--
-- Existing rows stay as they are (accepted / cooking / ...).
-- Only NEW orders will start as "placed".
-- =====================================================================
USE hotel_management_app;

ALTER TABLE orders MODIFY status ENUM(
  'placed','accepted','cooking','on_the_way','delivered','cancelled'
) NOT NULL DEFAULT 'placed';
