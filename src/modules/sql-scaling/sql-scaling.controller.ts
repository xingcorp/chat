import * as dotenv from 'dotenv';

dotenv.config();
import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import {
    CheckIn,
    CheckInDetail,
    OfficeOrgChart,
    OfficeTitle,
    OfficeUser,
    UserAddress,
    UserDepartment
} from "@models/entities";
import { ObjectStatus } from "@models/entities/profile.info.block";
import { SqlScalingService } from "@modules/sql-scaling/sql-scaling.service";
import {
    gcpCECheckConnectLoadBalancerInstance,
    gcpCEInstanceGet
} from "@services/g-cloud/compute-engine/instance.ce.g-cloud";
import { DataSource, DataSourceOptions } from "typeorm";
import { gcpGetListReplicaOfInstance, gcpSqlGetInstance } from "@services/g-cloud/sql-admin.g-cloud";
import { isCanConnect } from "@services/typeorm/create-connect.typeorm";
import { isEnvDeploy } from "@helpers/environment.helper";

@Controller('b283dd16-466d-4bf7-9bed-c69adba8016ahaha')
export class SqlScalingController {

    constructor(
        private dataSource: DataSource,
        private readonly sqlScalingService: SqlScalingService,
    ) {
    }

    @Post('46963907-3c99-4b3f-9fa8-afe59aa05f80-fksd')
    async createReplica(
        @Query('token') token: string,
        @Body() body: any
    ): Promise<boolean> {
        return !!(await this.sqlScalingService.createReplica(token, body))
    }

    @Post('ea19f63c-e9aa-4d70-afb1-045f0fc5e227-asdf34')
    async removeReplica(
        @Query('token') token: string,
        @Body() body: any
    ) {
        return this.sqlScalingService.removeReplica(token, body)
    }

    @Get('restart')
    async restart() {
        if (!isEnvDeploy) return '404'

        const loadBalancerInfoOptions: DataSourceOptions = {
            host: process.env.GCE_LOAD_BALANCER_INSTANCE_PRIVATE_IP,
            port: Number(process.env.DATABASE_PORT),
            username: process.env.DATABASE_USERNAME,
            password: process.env.DATABASE_PASSWORD,
            database: process.env.DATABASE_NAME,
            type: 'postgres',
            synchronize: false,
            connectTimeoutMS: 3 * 1000
        }

        if (!await isCanConnect(loadBalancerInfoOptions)) {
            return this.sqlScalingService.restartLoadBalancingServer()
        }

        return true
    }

/*    @Get('ttt')
    async ttt() {
        const query = CheckInDetail.createQueryBuilder('qb')
            .leftJoinAndMapMany('qb.ci', CheckIn, 'ci', 'ci."id"::text = qb."checkInId"')
            .where({
                createdBy: '5b7c18df-96d7-436b-bf23-845c420e63bd'
            })
            .where('EXTRACT(MONTH FROM qb."createdAt") = :month', {month: 10})
            .orderBy({
                createdAt: "ASC"
            })

        console.log(query.getQuery())
    }*/
}
