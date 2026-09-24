import { Router } from 'express';
import { OrderController } from '../controllers/order.controller';
import { authenticate } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/role.middleware';

const router = Router();

router.post('/', authenticate, OrderController.place);
router.get('/mine', authenticate, OrderController.myOrders);
router.get('/business/:businessId', authenticate, OrderController.businessOrders);
// super_admin: all orders across all businesses (declared before '/:id')
router.get('/admin/all', authenticate, requireRole('super_admin'), OrderController.adminList);
router.get('/admin/:id', authenticate, requireRole('super_admin'), OrderController.adminGetOne);
router.delete('/admin/:id', authenticate, requireRole('super_admin'), OrderController.adminRemove);
router.get('/:id', authenticate, OrderController.getOne);
router.patch('/:id/status', authenticate, OrderController.updateStatus);
router.post('/:id/cancel', authenticate, OrderController.cancel);

export default router;
