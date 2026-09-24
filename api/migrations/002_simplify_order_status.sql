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
