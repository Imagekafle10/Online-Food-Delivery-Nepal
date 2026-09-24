import { Router } from 'express';
import { PaymentController } from '../controllers/payment.controller';
import { authenticate } from '../middlewares/auth.middleware';

const router = Router();

router.post('/initiate', authenticate, PaymentController.initiate);
router.get('/status/:uuid', authenticate, PaymentController.status);

// Gateway redirect callbacks (public - hit by the browser returning from the gateway)
router.get('/esewa/success', PaymentController.esewaSuccess);
router.get('/esewa/failure', PaymentController.esewaFailure);
router.get('/khalti/callback', PaymentController.khaltiCallback);

export default router;
