import { Router } from 'express';
import { RiderController } from '../controllers/rider.controller';
import { authenticate } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/role.middleware';

const router = Router();

router.use(authenticate);

// Roster of riders, used by the admin panel to populate the "assign rider" dropdown.
router.get('/', requireRole('business_owner', 'super_admin'), RiderController.list);

// Only super_admin onboards new riders onto the platform.
router.post('/', requireRole('super_admin'), RiderController.create);

export default router;
