import * as dotenv from 'dotenv';

dotenv.config();

import { Injectable } from '@nestjs/common';
import { RedisService } from "@core/common/redis.service";
import {
    gcpCreateReplica,
    gcpGetListReplicaOfInstance,
    gcpSqlGetInstance,
    gcpSqlGetPrivateIpOfInstance,
    gcpSqlIsInstanceRunnable,
    gcpSqlRemoveInstance
} from "@services/g-cloud/sql-admin.g-cloud";
import {
    gcpCERestartLoadBalancingInstance, gcpCEStoreInstanceRemoveNameToServer,
    gcpCEUpdateAndRestartLoadBalancingInstance
} from "@services/g-cloud/compute-engine/instance.ce.g-cloud";
import { isEnvDeploy } from "@helpers/environment.helper";
import { isCanConnect } from "@services/typeorm/create-connect.typeorm";
import { DataSourceOptions } from "typeorm";

const WAITING_REPLICA_INSTANCE_RUNNING = 'WAITING_REPLICA_INSTANCE_RUNNING'
const WAITING_REPLICA_INSTANCE_REMOVING = 'WAITING_REPLICA_INSTANCE_REMOVING'
const JOB_SAVE_LIST_IP_SQL_REPLICA = 'JOB_SAVE_LIST_IP_SQL_REPLICA'
const WAIT_TIME = 10 * 60

@Injectable()
export class SqlScalingService {
    constructor(
        private readonly cacheService: RedisService,
        // private schedulerRegistry: SchedulerRegistry
    ) {
    }

    async createReplica(token: string, body: any) {
        if (token !== process.env.SQL_SCALING_REPLICA_TOKEN) {
            console.log('wrong token')
            return false
        }

        if (body && body?.subscription !== process.env.PUB_SUB_NOTIFY_CREATE_REPLICA_INSTANCE) {
            console.log('wrong pub/sub')
            return false
        }

        if (await this.cacheService.get(WAITING_REPLICA_INSTANCE_RUNNING)) return

        try {
            const cpu = parseInt(process.env.CLOUD_SQL_REPLICA_INSTANCE_CPU ?? '1')
            const ram = parseInt(process.env.CLOUD_SQL_REPLICA_INSTANCE_RAM ?? '3840')
            const res = await gcpCreateReplica(cpu, ram)

            if (res) {
                console.log(`Start create instance ${(res as any)?.name}`, new Date())
                await this.cacheService.setWithTtl(WAITING_REPLICA_INSTANCE_RUNNING, true, WAIT_TIME)

                // this.makeJobAddIpReplica()
            }

            return res
        } catch (error) {
            console.error("ERR: ", error.message)
            return false
        }
    }

    async removeReplica(token: string, body: any) {
        if (token !== process.env.SQL_SCALING_REPLICA_TOKEN) {
            console.log('wrong token')
            return false
        }

        if (body && body?.subscription !== process.env.PUB_SUB_NOTIFY_REMOVE_REPLICA_INSTANCE) {
            console.log('wrong pub/sub')
            return false
        }

        if (await this.cacheService.get(WAITING_REPLICA_INSTANCE_REMOVING)) return

        try {
            const listReplica = await gcpGetListReplicaOfInstance(process.env.CLOUD_SQL_PRIMARY_NAME)

            if (listReplica?.length) {
                const replicaRemoveName = listReplica.find(ip => ip !== process.env.CLOUD_SQL_PRIMARY_NAME)

                const res = await gcpCEStoreInstanceRemoveNameToServer(replicaRemoveName)

                /*not remove*/
                // const replicaRemoveIp = gcpSqlGetPrivateIpOfInstance(await gcpSqlGetInstance(replicaRemoveName))
                // console.log('Start reduce sql instance', replicaRemoveName, replicaRemoveIp)
                //
                // // Remove ip of load balancer
                // await this.restartLoadBalancingServer(replicaRemoveIp)
                //
                // // Remove instance of cloud sql
                // const res = await gcpSqlRemoveInstance(replicaRemoveName)

                if (res) {
                    await this.cacheService.setWithTtl(WAITING_REPLICA_INSTANCE_REMOVING, true, WAIT_TIME)
                }

                return res
            }

            return true

        } catch (error) {
            console.error("ERR: ", error.message)
            return false
        }
    }


    // private makeJobAddIpReplica() {
    //     const job = new CronJob(CronExpression.EVERY_5_MINUTES, async () => this.restartLoadBalancingServer());
    //
    //     this.schedulerRegistry.addCronJob(`${JOB_SAVE_LIST_IP_SQL_REPLICA}- ${new Date().getTime()}`, job);
    //     console.log('restartLoadBalancingServer job create', new Date())
    //     job.start();
    // }

    /*Not running in here*/
    // @Cron(CronExpression.EVERY_5_MINUTES)
    async restartLoadBalancingServer(deleteIp: string = '') {
        if (!isEnvDeploy) return

        console.log('restart load balancer', new Date())
        const ips = await this.checkAndGetListReplicaIps()
        const list = ips.filter(ip => ip !== deleteIp)

        await this.updateAndRestartLoadBalancingServer(list.length ? list : [process.env.CLOUD_SQL_PRIMARY_IP])
    }

    private async checkAndGetListReplicaIps() {
        console.log('checkAndGetListReplicaIps', new Date())

        const instance = process.env.CLOUD_SQL_PRIMARY_NAME
        const list = (await gcpGetListReplicaOfInstance(instance)) ?? []

        const ips = []
        for (const item of list) {
            const instance = await gcpSqlGetInstance(item)

            // if (gcpSqlIsInstancePendingCreate(instance)) {
            //     this.makeJobAddIpReplica()
            //
            //     console.log('restartLoadBalancingServer job result', new Date, `wait to create instance ${item}`)
            //     return false
            // }

            if (gcpSqlIsInstanceRunnable(instance)) ips.push(gcpSqlGetPrivateIpOfInstance(instance))
        }

        return ips
    }

    private async updateAndRestartLoadBalancingServer(ips: string[]) {
        await gcpCEUpdateAndRestartLoadBalancingInstance(ips)
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

        let count = 0
        while (!(await isCanConnect(loadBalancerInfoOptions)) && count < 100) {
            // await gcpCEUpdateAndRestartLoadBalancingInstance(ips)
            await gcpCERestartLoadBalancingInstance()
            count++
        }
    }
}
