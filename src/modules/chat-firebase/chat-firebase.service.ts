import * as dotenv from 'dotenv';

dotenv.config();

import { Inject, Injectable } from '@nestjs/common';
import { FileUpload } from "graphql-upload";
import { changeFilename } from "@utils/file.utils";
import { FirebaseService } from "@service-modules/firebase/firebase.service";
import { ChatCollections, FirebaseFilterMessageArgs } from "@service-modules/firebase/firebase.arg";
import { OfficeUser } from "@models/entities";
import { ObjectLiteral, Repository } from "typeorm";
import { InjectRepository } from "@nestjs/typeorm";
import { normalizeSearchText, StringCase, substringArray } from "@utils/string.utils";
import { ObjectStoreServiceCloudInterface } from "@service-modules/object-store/object-store-cloud-service.interface";
import {
    OfficeChatMessageSearchArgs
} from "@modules/chat-firebase/dto/chat-firebase.arg";
import { SearchEngineServiceInterface } from "@modules/search-engine/search-engine.service.interface";
import { OfficeChatMessageSearchResponse } from "@modules/chat-firebase/dto/chat-firebase.response";
import { getLinkPreview } from "link-preview-js";

const CHAT_OBJECT_STORE = process.env.CHAT_OBJECT_STORE

@Injectable()
export class ChatFirebaseService {
    constructor(
        @Inject('ObjectStoreCloudService')
        private readonly objectStoreService: ObjectStoreServiceCloudInterface,
        private readonly firebaseService: FirebaseService,
        @InjectRepository(OfficeUser)
        private officeUserRepository: Repository<OfficeUser>,
        @Inject('SearchEngineFirebaseService')
        private readonly searchEngineServiceInterface: SearchEngineServiceInterface,
    ) {
    }

    public async storeObject(args: {
        file: FileUpload;
        messageId: string; //message id
    }): Promise<any> {
        const {messageId, file} = args
        const newFilename = changeFilename(messageId, file.filename)

        await this.objectStoreService.storeNewObject(CHAT_OBJECT_STORE, newFilename, file.createReadStream())

        return this.objectStoreService.getForeverDownloadUrl(CHAT_OBJECT_STORE, newFilename)
    }

    async searchMessage(filter: FirebaseFilterMessageArgs) {
        return this.firebaseService.searchMessages(filter)
    }


    async createUser(user: OfficeUser) {
        const {docId, data} = await this.getUserDocData(user)
        return this.firebaseService.createDoc(ChatCollections.USER, docId, data)
    }

    private getCaseSearch(user: OfficeUser | ObjectLiteral) {
        const res = []

        res.push(...substringArray(user.fullname))
        res.push(...substringArray(user.code))
        res.push(...substringArray(user.code.toLowerCase()))
        res.push(...substringArray(user.code.toUpperCase()))
        res.push(...substringArray(normalizeSearchText(user.fullname)))
        res.push(...substringArray(normalizeSearchText(user.fullname, StringCase.Lower)))
        res.push(...substringArray(normalizeSearchText(user.fullname, StringCase.Upper)))

        return [...new Set(res)];
    }

    async updateUser(user: ObjectLiteral) {
        const {docId, data} = await this.getUserDocData(user)

        delete data.createdAt

        return this.firebaseService.updateDoc(ChatCollections.USER, docId, data)
    }

    private async getUserDocData(user: OfficeUser | ObjectLiteral) {
        const docId = user.id
        const data = {
            name: user.fullname,
            caseSearch: this.getCaseSearch(user),
            createdAt: new Date(),
            updatedAt: new Date(),
            email: user.email,
            phoneNumber: user.phone,
            photoUrl: (user.imageUrls && user.imageUrls.length) ? user.imageUrls.at(-1) : '',
            uid: docId,
        }

        return {docId, data}
    }

    async removeUser(entity: OfficeUser) {
        return this.firebaseService.removeDoc(ChatCollections.USER, entity.id)
    }

    async createExistUserToFirebase() {
        const users = await OfficeUser.find({
            withDeleted: true
        })

        console.log('start create user to firebase, count users: ', users.length)
        for (const user of users) {
            const isExist = await this.firebaseService.isDocExist(ChatCollections.USER, user.id)

            if (!isExist) {
                console.log('create user to firebase: ', user.id)
                await this.createUser(user)
            }
        }
        console.log('end create user to firebase')

        return true
    }

    async list(args: OfficeChatMessageSearchArgs): Promise<OfficeChatMessageSearchResponse> {
        const rawData = await this.searchEngineServiceInterface.searchMessage(args)

        return {
            count: rawData.hits.length,
            total: rawData.nbHits,
            records: rawData.hits
        }
    }

    async linkPreviewGet(url: string) {
        try {
            return {
                success: true,
                data: await getLinkPreview(url)
            }
        } catch (e) {
            return {
                success: false,
                data: e
            }
        }
    }

    async linkPreviewGetData(url: string) {
        return (await this.linkPreviewGet(url))['data']
    }
}
