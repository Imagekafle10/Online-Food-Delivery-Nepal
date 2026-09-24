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
