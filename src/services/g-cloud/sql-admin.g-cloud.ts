import * as dotenv from 'dotenv';

dotenv.config();

import { gclGetCredentialValue, gcpGetClient } from "@services/g-cloud/auth.g-cloud";
import { sqladmin } from "@googleapis/sqladmin";

export enum SqlInstanceState {
    RUNNABLE = 'RUNNABLE',
    PENDING_DELETE = 'PENDING_DELETE',
    PENDING_CREATE = 'PENDING_CREATE',
}

export enum SqlInstanceIpAddressType {
    PRIMARY = 'PRIMARY',
    OUTGOING = 'OUTGOING',
    PRIVATE = 'PRIVATE',
}

export const gcpCreateReplica = async (cpu: number = 1, memory: number = 3840) => {
    const client = await gcpGetClient()
    const projectId = gclGetCredentialValue('project_id')
    const sqlNetwork = process.env.CLOUD_SQL_NETWORK
    const sqlRegion = process.env.CLOUD_SQL_REGION
    const dbVersion = process.env.CLOUD_SQL_DB_VERSION
    const masterInstanceName = process.env.CLOUD_SQL_PRIMARY_NAME
    const replicaName = `${masterInstanceName}-replica-${
        new Date()
            .toISOString()
            .replaceAll(':', '-')
            .replaceAll('.', '-')
            .toLowerCase()
    }`

    try {
        const create = await sqladmin('v1beta4')
            .instances
            .insert({
                    // Project ID of the project to which the newly created Cloud SQL instances should belong.
                    project: projectId,

                    requestBody: {
                        "masterInstanceName": masterInstanceName,
                        "project": projectId,
                        "databaseVersion": dbVersion,
                        "name": replicaName,
                        "region": sqlRegion,
                        "settings": {
                            "tier": `db-custom-${cpu}-${memory}`,
                            "settingsVersion": '0',
                            "ipConfiguration": {
                                "ipv4Enabled": false,
                                "privateNetwork": `projects/${projectId}/global/networks/${sqlNetwork}`
                            },
                        }
                    },

                    auth: client as any,
                })

        console.log('create', create)
        return create
    } catch (e) {
        console.error('error', e);
        return false
    }
}

export const gcpSqlGetInstance = async (instance: string) => {
    const client = await gcpGetClient()
    const projectId = gclGetCredentialValue('project_id')

    try {
        const query = await sqladmin('v1beta4')
            .instances
            .get({
                project: projectId,

                instance,

                auth: client as any,
            })

        // console.log(query)

        return query.data
    } catch (e) {
        console.error(e);
    }
}

export const gcpSqlRemoveInstance = async (instance: string) => {
    const client = await gcpGetClient()
    const projectId = gclGetCredentialValue('project_id')

    try {
        const query = await sqladmin('v1beta4')
            .instances
            .delete({
                project: projectId,

                instance,

                auth: client as any,
            })

        console.log(query)

        return query.data
    } catch (e) {
        console.error(e);
        return false
    }
}

export const gcpSqlListInstance = async (filter: string = '') => {
    const client = await gcpGetClient()
    const projectId = gclGetCredentialValue('project_id')

    try {
        const query = await sqladmin('v1beta4')
            .instances
            .list({
                // Project ID of the project to which the newly created Cloud SQL instances should belong.
                project: projectId,

                filter,

                auth: client as any,
            })

        return query.data.items
    } catch (e) {
        console.error(e);
    }
}

export const gcpGetListReplicaOfInstance = async (instanceName: string) => {
    const projectId = gclGetCredentialValue('project_id')
    const instance = await gcpSqlListInstance(`instanceType:CLOUD_SQL_INSTANCE name:${instanceName} project:${projectId}`)

    return instance[0].replicaNames
}

export const gcpGetListReplicaByStateOfInstance = async (instanceName: string, state: SqlInstanceState) => {
    const projectId = gclGetCredentialValue('project_id')
    const instance = await gcpSqlListInstance(`instanceType:CLOUD_SQL_INSTANCE name:${instanceName} project:${projectId} state:${state}`)

    return instance[0].replicaNames
}

export const gcpSqlIsInstanceRunnable = (i: any) => i.state === SqlInstanceState.RUNNABLE
export const gcpSqlIsInstancePendingCreate = (i: any) => i.state === SqlInstanceState.PENDING_CREATE
export const gcpSqlIsInstancePendingDelete = (i: any) => i.state === SqlInstanceState.PENDING_DELETE

export const gcpSqlGetPrimaryIpOfInstance = (i: any) => i.ipAddresses.find(item => item.type === SqlInstanceIpAddressType.PRIMARY).ipAddress
export const gcpSqlGetPrivateIpOfInstance = (i: any) => i.ipAddresses.find(item => item.type === SqlInstanceIpAddressType.PRIVATE).ipAddress
