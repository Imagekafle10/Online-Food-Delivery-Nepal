import { Request, Response, NextFunction } from 'express';
import { verifyAccessToken } from '../utils/auth.util';
import { AppError } from '../utils/AppError';

export function authenticate(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return next(new AppError('Authentication token missing', 401));
  }
  const token = header.split(' ')[1];
  try {
    const payload = verifyAccessToken(token);
    req.user = payload;
    next();
  } catch (err) {
    next(new AppError('Invalid or expired token', 401));
  }
}

// Doesn't fail if no token - useful for public endpoints that behave
// differently for logged-in users (e.g. showing "is favorited")
export function optionalAuth(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (header && header.startsWith('Bearer ')) {
    try {
      req.user = verifyAccessToken(header.split(' ')[1]);
    } catch {
      // ignore invalid token, continue as guest
    }
  }
  next();
}
