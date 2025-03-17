import { Injectable } from '@nestjs/common';
import { Timeout } from "@nestjs/schedule";
import {
    ApprovalFromGroupService
} from "@modules/graphql/management/approval/approval-from-group/approval-from-group.service";

@Injectable()
export class GroupFormJobService {
    constructor(private readonly fromGroupService: ApprovalFromGroupService) {
    }

    /*done*/
    // @Timeout(5000)
    async genGroupDefault() {
        return this.fromGroupService.genGroupDefault()
    }
}
