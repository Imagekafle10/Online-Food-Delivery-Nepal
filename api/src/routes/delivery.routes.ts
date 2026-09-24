import { Router } from 'express';
import { DeliveryController } from '../controllers/delivery.controller';
import { authenticate } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/role.middleware';

const router = Router();

router.use(authenticate);

router.post('/online', requireRole('rider'), DeliveryController.goOnline);
router.post('/offline', requireRole('rider'), DeliveryController.goOffline);
router.post('/ping', requireRole('rider'), DeliveryController.ping);
router.get('/mine', requireRole('rider'), DeliveryController.myDeliveries);
router.post('/:orderId/picked-up', requireRole('rider'), DeliveryController.pickedUp);
router.post('/:orderId/on-the-way', requireRole('rider'), DeliveryController.onTheWay);
router.post('/:orderId/delivered', requireRole('rider'), DeliveryController.delivered);

router.post('/:orderId/assign', requireRole('business_owner', 'super_admin'), DeliveryController.manualAssign);
router.get('/unassigned/ready', requireRole('business_owner', 'super_admin'), DeliveryController.unassignedReady);
router.get('/orders', requireRole('business_owner', 'super_admin'), DeliveryController.allOrders);

export default router;
