import { Request, Response } from 'express';
import { asyncHandler } from '../utils/AppError';
import { ok, created } from '../utils/response.util';
import { TableService } from '../services/table.service';
import { BusinessService } from '../services/business.service';

export const TableController = {
  addTable: asyncHandler(async (req: Request, res: Response) => {
    const businessId = Number(req.params.businessId);
    await BusinessService.assertCanManage(businessId, req.user!);
    const table = await TableService.addTable(businessId, req.body.table_number, req.body.capacity, req.body.location_note);
    created(res, table, 'Table added');
  }),

  listTables: asyncHandler(async (req: Request, res: Response) => {
    const tables = await TableService.listTables(Number(req.params.businessId));
    ok(res, tables);
  }),

  book: asyncHandler(async (req: Request, res: Response) => {
    const booking = await TableService.book(req.user!.id, req.body);
    created(res, booking, 'Table booked');
  }),

  myBookings: asyncHandler(async (req: Request, res: Response) => {
    const bookings = await TableService.listForUser(req.user!.id);
    ok(res, bookings);
  }),

  businessBookings: asyncHandler(async (req: Request, res: Response) => {
    const businessId = Number(req.params.businessId);
    await BusinessService.assertCanManage(businessId, req.user!);
    const bookings = await TableService.listForBusiness(businessId, req.query.date as string);
    ok(res, bookings);
  }),

  updateStatus: asyncHandler(async (req: Request, res: Response) => {
    const booking = await TableService.updateStatus(Number(req.params.id), req.body.status);
    ok(res, booking, 'Booking status updated');
  }),
};
