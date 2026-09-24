import { Server } from 'socket.io';
import http from 'http';

let io: Server | null = null;

export function initSocket(server: http.Server) {
  io = new Server(server, {
    cors: { origin: '*' },
  });

  io.on('connection', (socket) => {
    // Clients join rooms scoped to what they care about:
    //  - `order:<id>`      customer/rider tracking a single order
    //  - `business:<id>`   business dashboard (new orders, status changes)
    //  - `rider:<id>`      a specific rider's app
    socket.on('join', (room: string) => socket.join(room));
    socket.on('leave', (room: string) => socket.leave(room));
  });

  return io;
}

export function emitToOrder(orderId: number, event: string, payload: any) {
  io?.to(`order:${orderId}`).emit(event, payload);
}

export function emitToBusiness(businessId: number, event: string, payload: any) {
  io?.to(`business:${businessId}`).emit(event, payload);
}

export function emitToRider(riderId: number, event: string, payload: any) {
  io?.to(`rider:${riderId}`).emit(event, payload);
}
