import { Injectable } from '@nestjs/common';
import { Cron, Timeout } from "@nestjs/schedule";
import { EmployeeService } from "@modules/graphql/management/employee/employee.service";
import { OfficeUser } from "@models/entities";
import { LessThanOrEqual } from "typeorm";
import { ObjectStatus } from "@models/entities/profile.info.block";
import { IdentityService } from "@core/iam/identity/identity.service";

@Injectable()
export class EmployeeJobService {

    constructor(
        private employeeService: EmployeeService,
        private readonly identityService: IdentityService,
    ) {
    }

    @Cron('0 15 0 * * *', {
        name: 'DeactivateStaffAccounts',
        timeZone: process.env.TIMEZONE
    })
    async deactivateStaffAccounts() {
        try {
            return this.employeeService.deactivateStaffAccounts()
        } catch (e) {
            console.log('DeactivateStaffAccounts err', e)
        }
    }

    // @Timeout(5000)
    async removeToken() {
        try {
            if(process.env.STAGE === 'dev') return
            console.log('removeToken start')

            const users = await OfficeUser.find({
                where: {
                    status: ObjectStatus.Inactive
                },
                withDeleted: true,
                select: ["iamUserId"]
            });

            for (const user of users) {
                console.log('removeToken user:', user.iamUserId)
                await this.identityService.deleteSessionTokenUserInActive(user?.iamUserId)
            }
        } catch (e) {
            console.log('removeToken err', e)
        }
    }
}
