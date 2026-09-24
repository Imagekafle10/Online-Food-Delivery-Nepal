import { Router } from 'express';
import authRoutes from './auth.routes';
import businessRoutes from './business.routes';
import menuRoutes from './menu.routes';
import orderRoutes from './order.routes';
import deliveryRoutes from './delivery.routes';
import riderRoutes from './rider.routes';
import tableRoutes from './table.routes';
import roomRoutes from './room.routes';
import paymentRoutes from './payment.routes';
import addressRoutes from './address.routes';
import userRoutes from './user.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/businesses', businessRoutes);
router.use('/menu', menuRoutes);
router.use('/orders', orderRoutes);
router.use('/delivery', deliveryRoutes);
router.use('/riders', riderRoutes);
router.use('/tables', tableRoutes);
router.use('/rooms', roomRoutes);
router.use('/payments', paymentRoutes);
router.use('/addresses', addressRoutes);
router.use('/users', userRoutes);

router.get('/health', (_req, res) => res.json({ success: true, message: 'API is healthy' }));

export default router;
