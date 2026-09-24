import { Router } from 'express';
import { UserController } from '../controllers/user.controller';
import { authenticate } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/role.middleware';

const router = Router();

router.use(authenticate, requireRole('super_admin'));

router.get('/admin/all', UserController.adminList);
router.patch('/:id/suspend', UserController.suspend);
router.patch('/:id/activate', UserController.activate);
router.delete('/:id', UserController.remove);

export default router;
