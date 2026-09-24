import { Router } from 'express';
import { TableController } from '../controllers/table.controller';
import { authenticate } from '../middlewares/auth.middleware';

const router = Router();

router.get('/:businessId/tables', TableController.listTables);
router.post('/:businessId/tables', authenticate, TableController.addTable);
router.get('/:businessId/bookings', authenticate, TableController.businessBookings);

router.post('/bookings', authenticate, TableController.book);
router.get('/bookings/mine', authenticate, TableController.myBookings);
router.patch('/bookings/:id/status', authenticate, TableController.updateStatus);

export default router;
