import { Router } from 'express';
import { ReviewController } from '../controllers/review.controller';
import { authenticate } from '../middlewares/auth.middleware';

const router = Router();

router.post('/', authenticate, ReviewController.create);
router.get('/business/:businessId', ReviewController.forBusiness);
router.get('/order/:orderId', authenticate, ReviewController.forOrder);

export default router;
