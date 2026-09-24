import dotenv from 'dotenv';
dotenv.config();

export const env = {
  port: Number(process.env.PORT) || 5000,
  nodeEnv: process.env.NODE_ENV || 'development',
  clientUrl: process.env.CLIENT_URL || '*',

  jwtSecret: process.env.JWT_SECRET || 'dev_secret_change_me',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET || 'dev_refresh_secret_change_me',
  jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',

  esewa: {
    merchantCode: process.env.ESEWA_MERCHANT_CODE || 'EPAYTEST',
    secretKey: process.env.ESEWA_SECRET_KEY || '',
    successUrl: process.env.ESEWA_SUCCESS_URL || '',
    failureUrl: process.env.ESEWA_FAILURE_URL || '',
    baseUrl: process.env.ESEWA_BASE_URL || 'https://rc-epay.esewa.com.np',
  },

  khalti: {
    secretKey: process.env.KHALTI_SECRET_KEY || '',
    baseUrl: process.env.KHALTI_BASE_URL || 'https://dev.khalti.com/api/v2',
    returnUrl: process.env.KHALTI_RETURN_URL || '',
  },

  uploadDir: process.env.UPLOAD_DIR || 'uploads',
};
