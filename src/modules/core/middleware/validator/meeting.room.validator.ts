import {
    registerDecorator,
    ValidationOptions,
    ValidatorConstraint,
    ValidatorConstraintInterface,
    ValidationArguments,
} from 'class-validator';
import { MeetingRoom } from '../../../../models/entities/meeting.room';
import { OfficeError } from '../../../../common/office.error';

@ValidatorConstraint({ async: true })
class IsMeetingRoomIdExistConstraint implements ValidatorConstraintInterface {
    async validate(id: string, args: ValidationArguments) {
        const meetingRoom = await MeetingRoom.findOne({ where: { id } });
        if (!meetingRoom) throw OfficeError.MeetingRoomNotFound;
        return true;
    }
}

export function IsMeetingRoomIdExist(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        registerDecorator({
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            constraints: [],
            validator: IsMeetingRoomIdExistConstraint,
        });
    };
}