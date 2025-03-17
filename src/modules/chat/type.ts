import { OfficeUser } from '@models/entities';
import { Socket } from 'socket.io';

export type AuthPayload = {
    officeUser: OfficeUser;
    requesterId: string;
    officeUserId: string;
};

export type RequestWithAuth = Request & AuthPayload;
export type SocketWithAuth = Socket & AuthPayload;