import { Request, Response } from 'express';
import { asyncHandler } from '../utils/AppError';
import { ok, created } from '../utils/response.util';
import { RoomService } from '../services/room.service';
import { BusinessService } from '../services/business.service';

export const RoomController = {
  addRoom: asyncHandler(async (req: Request, res: Response) => {
    const businessId = Number(req.params.businessId);
    await BusinessService.assertCanManage(businessId, req.user!);
    const room = await RoomService.addRoom(businessId, req.body);
    created(res, room, 'Room added');
  }),

  listRooms: asyncHandler(async (req: Request, res: Response) => {
    const rooms = await RoomService.listRooms(Number(req.params.businessId));
    ok(res, rooms);
  }),

  searchAvailable: asyncHandler(async (req: Request, res: Response) => {
    const { check_in, check_out, guests } = req.query;
    const rooms = await RoomService.searchAvailable(
      Number(req.params.businessId), String(check_in), String(check_out), guests ? Number(guests) : undefined
    );
    ok(res, rooms);
  }),

  book: asyncHandler(async (req: Request, res: Response) => {
    const booking = await RoomService.book(req.user!.id, req.body);
    created(res, booking, 'Room booked');
  }),

  myBookings: asyncHandler(async (req: Request, res: Response) => {
    const bookings = await RoomService.listForUser(req.user!.id);
    ok(res, bookings);
  }),

  businessBookings: asyncHandler(async (req: Request, res: Response) => {
    const businessId = Number(req.params.businessId);
    await BusinessService.assertCanManage(businessId, req.user!);
    const bookings = await RoomService.listForBusiness(businessId);
    ok(res, bookings);
  }),

  updateStatus: asyncHandler(async (req: Request, res: Response) => {
    const booking = await RoomService.updateStatus(Number(req.params.id), req.body.status);
    ok(res, booking, 'Booking status updated');
  }),
};
