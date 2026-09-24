import { Router } from 'express';
import { MenuController } from '../controllers/menu.controller';
import { authenticate } from '../middlewares/auth.middleware';
import { uploadSingleImage } from '../middlewares/upload.middleware';

const router = Router();

router.get('/search', MenuController.search);
router.get('/:businessId', MenuController.getMenu);
router.get('/:businessId/manage', authenticate, MenuController.getManageMenu);
router.post('/:businessId/categories', authenticate, MenuController.addCategory);
router.patch('/:businessId/categories/:categoryId', authenticate, MenuController.updateCategory);
router.delete('/:businessId/categories/:categoryId', authenticate, MenuController.removeCategory);
router.post('/:businessId/items', authenticate, uploadSingleImage, MenuController.addItem);
router.patch('/:businessId/items/:itemId', authenticate, uploadSingleImage, MenuController.updateItem);
router.patch('/:businessId/items/:itemId/availability', authenticate, MenuController.setAvailability);
router.delete('/:businessId/items/:itemId', authenticate, MenuController.removeItem);

export default router;
