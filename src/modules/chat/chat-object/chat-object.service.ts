import * as dotenv from 'dotenv';

dotenv.config();

import { Inject, Injectable } from '@nestjs/common';
import { buildExceptionResponse } from "@core/common/error.builder";
import { ChatObjectType } from "@modules/chat/chat-object/chat-object.resolver";
import { OfficeError } from "@common/office.error";
import { datetimeGetFormat, TIMESTAMP } from "@utils/datetime.utils";
import { gcpGenerateSignedUrlWriteObject } from "@services/g-cloud/store.g-cloud";
import { ChatConversationRepo } from "@models/repositories";
import { ObjectStoreServiceCloudInterface } from "@service-modules/object-store/object-store-cloud-service.interface";

const CHAT_OBJECT_STORE = process.env.CHAT_OBJECT_STORE

@Injectable()
export class ChatObjectService {

    constructor(
        private readonly chatConversationRepo: ChatConversationRepo,
        @Inject('ObjectStoreCloudService')
        private readonly objectStoreServiceInterface: ObjectStoreServiceCloudInterface,
    ) {
    }

    async genLinkUpload(args: {
        filename: string;
        conversationId: string;
        mimetype: string;
        type: ChatObjectType
    }, userId: string) {
        const { filename, mimetype, conversationId, type } = args;

        if (type === ChatObjectType.MESSAGE && !conversationId) {
            throw OfficeError.ChatObjectRequiredConversation
        }

        if (conversationId) {
            const conversation = await this.chatConversationRepo.getByIdIncludesMembers(conversationId)

            if (!conversation) {
                throw OfficeError.ChatConversationNotExist
            }

            if (!conversation.members.map(item => item.userId).includes(userId)) {
                throw OfficeError.ChatUserNotInConversation
            }
        }

        const filePath = this.getFilePath(filename, conversationId, type)

        try {
            return {
                uploadUrl: await this.genSignedUrlWriteObject(filePath, mimetype),
                path: filePath,
            }

        } catch (error) {
            console.log('Gen link upload document has failed: ', error)
            throw buildExceptionResponse(error)
        }
    }

    private getFilePath(filename: string, conversationId: string, type: ChatObjectType) {
        let path = type.toString();

        if (conversationId) path += `/${conversationId}`

        return `${path}/${datetimeGetFormat('YYYY-MM-DD-HH-mm-ss')}/${filename}`
    }

    private async genSignedUrlWriteObject(filePath: string, mimetype: string) {
        return gcpGenerateSignedUrlWriteObject(CHAT_OBJECT_STORE, filePath, mimetype);
    }

    async getFirebaseUrl(path: string) {
        const url = await this.objectStoreServiceInterface.getFirebaseUrl(CHAT_OBJECT_STORE, path)
        return {
            path: path,
            url,
        }
    }
}
