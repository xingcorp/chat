import { Inject, Injectable } from "@nestjs/common";
import { OfficeChatMessage, OfficeChatMessageReaction } from "@models/entities";
import { ChatAddMessageInput, ChatMessageGetListFilter } from "@modules/chat/chat-message/dto/chat-message.args";
import { DynamoDBClient, QueryCommand, QueryCommandInput } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand, GetCommand, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { marshall, unmarshall } from "@aws-sdk/util-dynamodb";
import { extractUserIdsInMessage, replaceUserIdsWithNamesInMessage } from "@utils/common.utils";
import { RedisService } from "@core/common/redis.service";
import { OfficeUserRepo } from "../profile.user.repo";
import { LoggerService } from "@core/common/logger.service";
import { OrderBy } from "@modules/graphql/management/document/document.args";

@Injectable()
export class ChatMessageRepo {
    logger = new LoggerService(ChatMessageRepo.name)
    private docClient: DynamoDBDocumentClient;
    private tableName = `${process.env.SERVICE_CODE}-${process.env.STAGE}-chat-messages-table`;

    constructor(
        @Inject(DynamoDBClient) private readonly dynamoDBClient: DynamoDBClient,
        private readonly redisService: RedisService,
        private readonly userRepo: OfficeUserRepo
    ) {
        this.docClient = DynamoDBDocumentClient.from(this.dynamoDBClient);
    }

    async createMessage(args: ChatAddMessageInput): Promise<OfficeChatMessage> {
        delete args.receiverId
        const current = args.createdAt ? (new Date(args.createdAt)).getTime() : (new Date()).getTime()
        const item = {
            ...args as any,
            id: `${args.conversationId}_${current}`,
            message: args.message?.trim() || '',
            fileName: args.fileName || undefined,
            createdAt: current
        }
        const params = {
            TableName: this.tableName,
            Item: item,
        };
        await this.docClient.send(new PutCommand(params));
        return item
    }

    async getById(id: string): Promise<OfficeChatMessage> {
        if (!id) return null

        const [conversationId, createdAt] = id.split('_')

        try {
            const params = {
                TableName: this.tableName,
                Key: {
                    conversationId,
                    createdAt: +createdAt,
                },
            }

            const result = await this.docClient.send(new GetCommand(params));
            const item = result.Item as OfficeChatMessage;

            // Return null if item has deletedAt property
            if (item?.deletedAt) {
                return null;
            }

            return item; // Returns the single item if found
        } catch (err) {
            this.logger.error('getById', err);
            return null;
        }
    }

    async updateReaderIds(
        id: string,
        readerIds: string[], // Replace with the actual type of your reactions (e.g., array or object)
    ): Promise<boolean> {
        try {
            if (!id) return null

            const [conversationId, createdAt] = id.split('_')

            await this.docClient.send(new UpdateCommand({
                TableName: this.tableName,
                Key: {
                    conversationId: conversationId, // Partition Key
                    createdAt: +createdAt,          // Sort Key
                },
                UpdateExpression: 'SET readerIds = :readerIds',
                ExpressionAttributeValues: {
                    ':readerIds': readerIds,
                },
                ReturnValues: 'UPDATED_NEW', // Return updated attributes
            }));
            return true;
        } catch (error) {
            this.logger.error('Error updating reactions:', error);
            return false;
        }
    }

    async updateReactions(
        id: string,
        reactions: OfficeChatMessageReaction[], // Replace with the actual type of your reactions (e.g., array or object)
    ): Promise<boolean> {
        try {
            if (!id) return null

            const [conversationId, createdAt] = id.split('_')

            await this.docClient.send(new UpdateCommand({
                TableName: this.tableName,
                Key: {
                    conversationId: conversationId, // Partition Key
                    createdAt: +createdAt,          // Sort Key
                },
                UpdateExpression: 'SET reactions = :reactions',
                ExpressionAttributeValues: {
                    ':reactions': reactions,
                },
                ReturnValues: 'UPDATED_NEW', // Return updated attributes
            }));
            return true;
        } catch (error) {
            this.logger.error('Error updating reactions:', error);
            return false;
        }
    }

    async updateMessage(
        id: string,
        message: string, // Replace with the actual type of your reactions (e.g., array or object)
    ): Promise<boolean> {
        try {
            if (!id) return null

            const [conversationId, createdAt] = id.split('_')

            await this.docClient.send(new UpdateCommand({
                TableName: this.tableName,
                Key: {
                    conversationId: conversationId, // Partition Key
                    createdAt: +createdAt,          // Sort Key
                },
                UpdateExpression: 'SET message = :message, editAt = :editAt',
                ExpressionAttributeValues: {
                    ':message': message,
                    ':editAt': (new Date()).getTime()
                },
                ReturnValues: 'UPDATED_NEW', // Return updated attributes
            }));
            return true;
        } catch (error) {
            this.logger.error('Error updating message:', error);
            return false;
        }
    }

    async deleteMessage(id: string): Promise<boolean> {
        try {
            if (!id) return null

            const [conversationId, createdAt] = id.split('_')

            await this.docClient.send(new UpdateCommand({
                TableName: this.tableName,
                Key: {
                    conversationId: conversationId, // Partition Key
                    createdAt: +createdAt,          // Sort Key
                },
                UpdateExpression: 'SET deletedAt = :deletedAt',
                ExpressionAttributeValues: {
                    ':deletedAt': (new Date()).getTime()
                },
                ReturnValues: 'UPDATED_NEW', // Return updated attributes
            }));
            return true;
        } catch (error) {
            this.logger.error('Error updating message:', error);
            return false;
        }
    }

    async getMessagesForConversation(args: ChatMessageGetListFilter): Promise<{
        messages: OfficeChatMessage[];
        lastKey: Record<string, any> | null;
    }> {
        try {
            const params: QueryCommandInput = {
                TableName: this.tableName, // Replace with your table name
                KeyConditionExpression: 'conversationId = :conversationId AND createdAt >= :createdAt',
                ExpressionAttributeValues: marshall({
                    ":conversationId": args.conversationId,
                    ":createdAt": args.from || 1000000
                }),
                FilterExpression: 'attribute_not_exists(deletedAt)',
                ScanIndexForward: args.order === OrderBy.ASC ? true : false,
                Limit: args.size,
                ExclusiveStartKey: args.lastKey
                    ? marshall({
                        "conversationId": args.lastKey.conversationId,
                        "createdAt": args.lastKey.createdAt
                    })
                    : undefined, // Pagination
            };

            if (args.type) {
                params.IndexName = 'type-index'
                params.KeyConditionExpression = 'conversationId = :conversationId AND #type = :type';
                params.ExpressionAttributeValues = marshall({
                    ":type": args.type,
                    ":conversationId": args.conversationId
                });
                params.ExpressionAttributeNames = {
                    '#type': 'type',
                };
            }
            const result = await this.docClient.send(new QueryCommand(params));

            return {
                messages: result.Items?.map((item) => unmarshall(item) as OfficeChatMessage) || [],
                lastKey: result.LastEvaluatedKey ? unmarshall(result.LastEvaluatedKey) : null,
            };
        } catch (err) {
            this.logger.error('getMessagesForConversation ', err);
            return {
                messages: [],
                lastKey: null,
            };
        }
    }

    async handleMessageForClient(message: string) {
        const referentIds = extractUserIdsInMessage(message)
        if (referentIds.length <= 0) return message

        const userMap = {}
        for (const userId of referentIds) {
            let redisValue = await this.redisService.get(userId);

            if (!redisValue) {
                const user = await this.userRepo.findOne({
                    where: { id: userId }
                })
                redisValue = JSON.stringify(user)
                await this.redisService.setWithTtl(userId, redisValue, 15 * 60) //Caching for 15 minutes
            }
            userMap[userId] = (JSON.parse(redisValue)).fullname
        }
        return replaceUserIdsWithNamesInMessage(message, userMap)
    }
}