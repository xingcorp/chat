import { Injectable } from '@nestjs/common'
import { InjectAwsService } from 'nest-aws-sdk'
import { SQS } from 'aws-sdk'
import { assert } from 'console'


@Injectable()
export class SqsService {

    protected static readonly QUEUE_NAME = `srt-${process.env.NODE_ENV || 'stg'}-crm-Incident-Importing`

    constructor(
        @InjectAwsService(SQS)
        private readonly sqs: SQS,
    ) {}

    createQueue(): Promise<any> {
        return new Promise((resolve, reject) => {
            this.sqs.createQueue({
                QueueName: SqsService.QUEUE_NAME, 
                Attributes: {
                    DelaySeconds: '60',
                    MessageRetentionPeriod: '259200'
                },
                tags: {
                    Name: 'srt-crm-incident-importing'
                }
            }, (err, data) => {
                if (err) {
                    reject({ failure: true, error: err})
                } else {
                    resolve({ url: data.QueueUrl })
                }
            })
        })
    }

    deleteQueue(queueUrl: string): Promise<any> {
        return new Promise((resolve, reject) => {
            this.sqs.deleteQueue({QueueUrl: queueUrl}, (err, data) => {
                if (err) {
                    reject({ failure: true, error: err })
                } else {
                    resolve(data)
                }
            })
        })
    }

    getQueueUrl(): Promise<any> {
        return new Promise((resolve, reject) => {
            this.sqs.getQueueUrl({QueueName: SqsService.QUEUE_NAME}, (err, data) => {
                if (err) {
                    reject({ failure: true, error: err })
                } else {
                    resolve({ url: data.QueueUrl })
                }
            })
        })
    }

    sendPayloads(queueUrl: string, sheetName: string, payloads: any[]): Promise<any> {
        const now = new Date().getTime()
        assert((payloads || []).length <= 10, 'Only delivers maximum 10 messages')
        return new Promise((resolve, reject) => {
            this.sqs.sendMessageBatch({
                QueueUrl: queueUrl,
                Entries: payloads.map((p, idx) => {
                    const message: string = JSON.stringify(p)
                    return {
                        Id: `${now + idx}`,
                        MessageBody: message,
                        MessageAttributes: {
                            Characters: {
                                DataType: 'String',
                                StringValue: `${message.length}`
                            },
                            SheetName: {
                                DataType: 'String',
                                StringValue: sheetName
                            }
                        }
                    }
                })
            }, (err, data) => {
                if (err) {
                    reject({ failure: true, error: err })
                } else {
                    resolve(data)
                }
            })
        })
    }

    async receivePayloads(queueUrl: string, maximumOfMessages: number = 10, enableDelete: boolean = false): Promise<any> {
        assert(maximumOfMessages <= 10, 'Only receives maximum 10 messages for each time!')
        const resultPromise = new Promise((resolve, reject) => {
            this.sqs.receiveMessage({
                QueueUrl: queueUrl,
                MaxNumberOfMessages: maximumOfMessages,
                VisibilityTimeout: 300,
                WaitTimeSeconds: 20,
                MessageAttributeNames: ['All'],
                AttributeNames: ['All']
            }, (err, data) => {
                if (err) {
                    reject({ failure: true, error: err })
                } else {
                    resolve(data)
                }
            })
        })
        const result: any = await resultPromise
        if (enableDelete) {
            await this.deletePayloads(queueUrl, result)
        }
        return result
    }

    deletePayloads(queueUrl: string, data: SQS.ReceiveMessageResult): Promise<any> {
        return new Promise((resolve, reject) => {
            this.sqs.deleteMessage({
                QueueUrl: queueUrl,
                ReceiptHandle: data.Messages[0].ReceiptHandle
            }, (err, data) => {
                if (err) {
                    console.log('Delete message from SQS fail:', err)
                    reject({ failure: true, error: err })
                } else {
                    resolve(data)
                }
            })
        })
    }
}
