import { Router } from 'express';
import { DeviceController } from '../controllers/device.controller';
import { authenticate } from '../middlewares/auth.middleware';

const router = Router();
router.use(authenticate);

router.post('/', DeviceController.register);
router.post('/remove', DeviceController.unregister); // POST so it can carry a JSON body on every client

export default router;
