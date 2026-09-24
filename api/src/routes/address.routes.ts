import { Router } from 'express';
import { AddressController } from '../controllers/address.controller';
import { authenticate } from '../middlewares/auth.middleware';

const router = Router();
router.use(authenticate);

router.get('/', AddressController.list);
router.post('/', AddressController.add);
router.delete('/:id', AddressController.remove);

export default router;
