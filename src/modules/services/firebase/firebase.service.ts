import { Injectable } from '@nestjs/common';
import { ChatCollections, FirebaseFilterMessageArgs } from "@service-modules/firebase/firebase.arg";
import {
    firebaseCreateDoc,
    firebaseGetAllDocs, firebaseIsDocExist,
    firebaseListCollections, firebaseRemoveDoc, firebaseUpdateDoc
} from "@services/g-cloud/firebase.g-cloud";
import { normalizeSearchText } from "@utils/string.utils";


@Injectable()
export class FirebaseService {
    async searchMessages(filter: FirebaseFilterMessageArgs) {
        switch (filter.type) {
            case ChatCollections.GROUP:
                return this.searchMessagesOfGroupChat(filter)
            case ChatCollections.MESSAGE:
            default:
                return this.searchMessagesOfDirectMessage(filter)
        }

    }

    private async searchMessagesInConversation(filter: FirebaseFilterMessageArgs) {
        let path = `${filter.type}/${filter.senderId}/${filter.receiverId}`

        const docs = await this.getDocs(filter, path)

        if (!filter.keyword) return docs

        return docs
            .filter(doc =>
                normalizeSearchText(doc.message).indexOf(normalizeSearchText(filter.keyword)) >= 0
            )
    }

    private async searchMessagesByUser(filter: FirebaseFilterMessageArgs) {
        const listChat = await firebaseListCollections([{
            collection: ChatCollections.MESSAGE,
            doc: filter.senderId,
        }])

        const res = []

        for (const chat of listChat) {
            let tmp = await this.searchMessagesInConversation({
                ...filter,
                receiverId: chat
            })

            if (tmp.length) res[chat] = tmp
        }

        return res
    }

    private async searchMessagesOfDirectMessage(filter: FirebaseFilterMessageArgs) {
        if (filter.receiverId) {
            return this.searchMessagesInConversation(filter)
        }

        return this.searchMessagesByUser(filter)
    }

    private async searchMessagesOfGroupChat(filter: FirebaseFilterMessageArgs) {
        const groupsOfUser = (await firebaseGetAllDocs(ChatCollections.GROUP))
            .filter(group => group.membersList.includes(filter.senderId))

        const res = []
        for (const group of groupsOfUser) {
            let tmp = await this.searchMessagesInConversation({
                ...filter,
                senderId: group.id,
                receiverId: 'chats'
            })

            if (tmp.length) res[group.id] = tmp
        }

        return res
    }

    private async getDocs(filter: FirebaseFilterMessageArgs, path: string) {
        const optionsFilter = this.getOptionsFilter(filter)

        return firebaseGetAllDocs(path, optionsFilter)
    }

    private getOptionsFilter(filter: FirebaseFilterMessageArgs) {
        const options = {}
        options['where'] = []

        if (filter.messageType) {
            options['where'].push({
                name: 'messageType',
                operation: '==',
                value: filter.messageType
            })
        }

        return options
    }

    async createDoc(collections: string, docId: string, data: any) {
        return firebaseCreateDoc(collections, docId, data);
    }

    async updateDoc(collections: string, docId: string, data: any) {
        return firebaseUpdateDoc(collections, docId, data);
    }

    async removeDoc(collections: string, docId: string) {
        return firebaseRemoveDoc(collections, docId)
    }

    async isDocExist(collections: string, docId: string) {
        return firebaseIsDocExist(collections, docId);
    }
}
