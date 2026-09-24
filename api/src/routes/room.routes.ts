import { Router } from 'express';
import { RoomController } from '../controllers/room.controller';
import { authenticate } from '../middlewares/auth.middleware';

const router = Router();

router.get('/:businessId/rooms', RoomController.listRooms);
router.post('/:businessId/rooms', authenticate, RoomController.addRoom);
router.get('/:businessId/rooms/available', RoomController.searchAvailable);
router.get('/:businessId/bookings', authenticate, RoomController.businessBookings);

router.post('/bookings', authenticate, RoomController.book);
router.get('/bookings/mine', authenticate, RoomController.myBookings);
router.patch('/bookings/:id/status', authenticate, RoomController.updateStatus);

export default router;
