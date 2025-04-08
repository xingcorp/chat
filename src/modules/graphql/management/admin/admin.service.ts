import { Injectable } from '@nestjs/common';
import { UserLoginArgs } from "@core/iam/identity/identity.arg";
import { IdentityService } from "@core/iam/identity/identity.service";
import { RequestContext } from "@common/context/request.context";
import { OfficeUserRepo } from "@models/repositories";
import { OfficeError } from "@common/office.error";

@Injectable()
export class AdminService {

    constructor(
        private readonly identityService: IdentityService,
        private readonly officeUserRepo: OfficeUserRepo
    ) {
    }

    async linkWithUser(credential: UserLoginArgs) {

        const userLogin = await this.identityService.officeLogin(credential)
        const user = await this.officeUserRepo.getById(userLogin?.user?.id)
        const admin = await RequestContext.currentAdmin()

        if (user && admin) {
            admin.user = user
        }

        await admin.save()
        await admin.reload()

        return admin;
    }

    async unlinkUser() {
        const admin = await RequestContext.currentAdmin()

        if (!admin) {
            throw OfficeError.SysUserNotExisted
        }

        admin.user = null
        await admin.save()

        return admin
    }
}
