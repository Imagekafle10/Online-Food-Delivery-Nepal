import { Router } from 'express';
import { BusinessController } from '../controllers/business.controller';
import { authenticate } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/role.middleware';

const router = Router();

router.get('/', BusinessController.list);
router.get('/admin/all', authenticate, requireRole('super_admin'), BusinessController.adminList);
router.post('/admin', authenticate, requireRole('super_admin'), BusinessController.adminCreate);
router.get('/:id', BusinessController.getOne);
router.post('/', authenticate, requireRole('business_owner', 'super_admin'), BusinessController.register);
router.patch('/:id', authenticate, BusinessController.update);
router.patch('/:id/open-status', authenticate, BusinessController.toggleOpen);
router.patch('/:id/approve', authenticate, requireRole('super_admin'), BusinessController.approve);
router.patch('/:id/suspend', authenticate, requireRole('super_admin'), BusinessController.suspend);
router.delete('/:id', authenticate, requireRole('super_admin'), BusinessController.remove);

export default router;
