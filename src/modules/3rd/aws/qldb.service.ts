import { Injectable } from '@nestjs/common';
import { QldbDriver, Result, RetryConfig, TransactionExecutor,  } from "amazon-qldb-driver-nodejs";
import { ClientConfiguration } from 'aws-sdk/clients/acm';
import { Agent } from 'https';
import { NFCInfoArgs } from '@modules/graphql/management/asset/old/asset.args';

@Injectable()
export class AwsQLDBService {
    private qldbDriver: QldbDriver = null
    constructor() {
        const maxConcurrentTransactions: number = Number(process.env.AWS_QLDB_MAX_SESSION || 100);
        const agentForQldb: Agent = new Agent({
            keepAlive: true,
            maxSockets: maxConcurrentTransactions
        });

        const serviceConfigurationOptions: ClientConfiguration = {
            region: process.env.AWS_QLDB_REGION || 'ap-southeast-1',
            httpOptions: {
                agent: agentForQldb
            },
            credentials: {
                accessKeyId: process.env.AWS_IAM_ACCESS_KEY_ID,
                secretAccessKey: process.env.AWS_IAM_ACCESS_KEY_SECRET
            }
        };

        const retryLimit: number = 4;
        // Use driver's default backoff function for this example (no second parameter provided to RetryConfig)
        const retryConfig: RetryConfig = new RetryConfig(retryLimit);
        this.qldbDriver = new QldbDriver(
            process.env.AWS_QLDB_LEDGER || 'srt-iotp-factory-dev-ledger',
            serviceConfigurationOptions,
            maxConcurrentTransactions,
            retryConfig
        );
    }

    public findCommitedCodeEventBySerial = async (serial: string) => {
        let rs = null;
        if (this.qldbDriver) {
            await this.qldbDriver.executeLambda(async (txn: TransactionExecutor) => {
                await txn.execute(`SELECT * FROM ${process.env.AWS_QLDB_COMMITED_CODE_EVENTS_TABLE || '_ql_committed_office_asset_events'} AS r WHERE r.data.code = ?`, serial).then((result: Result) => {
                    const resultList = result.getResultList()
                    if (resultList.length === 0) {
                        console.log(`Unable to find serial: ${serial}`)
                    }
                    // console.log("resultList: ", resultList[0])
                    rs = resultList[0]
                })
            })
        }
        return rs
    }

    public findUniqueCodeEventBySerialAndRollingCode = async (serial: string, rollingCode: string) => {
        let rs = null
        const existed = await this.findCommitedCodeEventBySerial(serial)
        if (existed) {
            if (this.qldbDriver) {
                await this.qldbDriver.executeLambda(async (txn: TransactionExecutor) => {
                    await txn.execute(`SELECT * FROM history(${process.env.AWS_QLDB_CODE_EVENTS_TABLE || 'office_asset_events'}) AS h WHERE h.metadata.id = ? AND h.data.rollingCode = ?`, existed.metadata?.id, rollingCode).then((result: Result) => {
                    // await txn.execute(`SELECT * FROM history(${process.env.AWS_QLDB_CODE_EVENTS_TABLE || 'office_asset_events'}) AS h WHERE h.metadata.id = ?`, existed.metadata?.id).then((result: Result) => {
                        const resultList = result.getResultList()
                        if (resultList.length === 0) {
                            console.log(`Unable to find serial ${serial} with rollingCode ${rollingCode}`)
                        }
                        // console.log("resultList: ", resultList[0])
                        rs = resultList[0]
                    })
                })
            }
        }
        return rs
    }

    public findLastestUniqueCodeEventBySerialHasRollingCode = async (serial: string) => {
        let rs = null
        const existed = await this.findCommitedCodeEventBySerial(serial)
        if (existed) {
            if (this.qldbDriver) {
                await this.qldbDriver.executeLambda(async (txn: TransactionExecutor) => {
                    await txn.execute(`SELECT * FROM history(${process.env.AWS_QLDB_CODE_EVENTS_TABLE || 'office_asset_events'}) AS h WHERE h.metadata.id = ? AND h.data.rollingCode <> ''`, existed.metadata?.id).then((result: Result) => {
                        const resultList = result.getResultList()
                        if (resultList.length === 0) {
                            console.log(`Unable to find serial ${serial} with lastest rollingCode`)
                        }
                        // console.log("resultList: ", resultList[0])
                        // rs = resultList[resultList.length - 1]
                        resultList.forEach((r: any) => {
                            if (r?.data?.rollingCode) rs = r
                        })
                    })
                })
            }
        }
        return rs
    }

    public findUniqueCodeEventBySerial = async (serial: string) => {
        let rs = null;
        if (this.qldbDriver) {
            await this.qldbDriver.executeLambda(async (txn: TransactionExecutor) => {
                await txn.execute(`SELECT * FROM ${process.env.AWS_QLDB_CODE_EVENTS_TABLE || 'office_asset_events'} WHERE code = ?`, serial).then((result: Result) => {
                    const resultList = result.getResultList()
                    if (resultList.length === 0) {
                        console.log(`Unable to find serial: ${serial}`)
                    }
                    // console.log("resultList: ", resultList[0])
                    rs = resultList[0]
                })
            })
        }
        return rs
    }

    public updateSerialRollingCode = async (serial: string, nfc: NFCInfoArgs) => {
        let rs = null
        if (this.qldbDriver) {
            await this.qldbDriver.executeLambda(async (txn: TransactionExecutor) => {
                await txn.execute(`UPDATE ${process.env.AWS_QLDB_CODE_EVENTS_TABLE || 'office_asset_events'} AS p SET p.rollingCode = ?, p.longitude = ?, p.latitude = ? WHERE p.code = ?`, nfc.rollingCode, (nfc.longitude ? `${nfc.longitude}` : null), (nfc.latitude ? `${nfc.latitude}` : null), serial).then((result: Result) => {
                    const resultList = result.getResultList()
                    if (resultList.length === 0) {
                        console.log(`Unable to update rollingCode for Serial: ${serial}`)
                    }
                    rs = resultList[0]
                })
            })
        }
        return rs
    }

    public insertSerialRollingCode = async (serial: string, nfc: NFCInfoArgs, rsSerial: any) => {
        let rs = null
        if (this.qldbDriver) {
            await this.qldbDriver.executeLambda(async (txn: TransactionExecutor) => {
                await txn.execute(`INSERT INTO ${process.env.AWS_QLDB_CODE_EVENTS_TABLE || 'office_asset_events'} ?`, {
                    code: serial,
                    assetCode: rsSerial?.code,
                    assetName: rsSerial?.name,
                    rollingCode: nfc.rollingCode,
                    longitude: nfc.longitude ? `${nfc.longitude}` : null,
                    latitude: nfc.latitude ? `${nfc.latitude}` : null
                }).then((result: Result) => {
                    const resultList = result.getResultList()
                    if (resultList.length === 0) {
                        console.log(`Unable to insert rollingCode for Serial: ${serial}`)
                    }
                    rs = resultList[0]
                })
            })
        }
        return rs
    }
}
