import { Request, Response } from 'express';
import { asyncHandler } from '../utils/AppError';
import { ok, created } from '../utils/response.util';
import { RiderModel } from '../models/rider.model';
import { AuthService } from '../services/auth.service';

export const RiderController = {
  // Full roster for the admin panel (name, phone, status, vehicle, delivery count).
  list: asyncHandler(async (req: Request, res: Response) => {
    const onlyAvailable = req.query.status === 'available';
    const riders = onlyAvailable ? await RiderModel.listAvailable() : await RiderModel.listAll();
    ok(res, riders);
  }),

  // Lets an admin onboard a rider account directly from the panel instead of
  // sending them through the public /auth/register flow.
  create: asyncHandler(async (req: Request, res: Response) => {
    const { full_name, email, phone, password, vehicle_type, vehicle_number } = req.body;
    const result = await AuthService.register({
      full_name,
      email,
      phone,
      password,
      role: 'rider',
    });

    if (vehicle_type || vehicle_number) {
      const rider = await RiderModel.findByUserId(result.user.id);
      if (rider) {
        await RiderModel.updateVehicle(rider.id, vehicle_type, vehicle_number);
      }
    }

    created(res, result.user, 'Rider account created');
  }),
};
