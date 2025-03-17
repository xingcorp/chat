import { Injectable } from '@nestjs/common';
import { ChatReactionMessageInput } from "@modules/chat/chat-reaction/dto/chat-reaction.args";
import { ChatMessageRepo, ReactionMessageChatRepo } from "@models/repositories";
import { OfficeError } from "@common/office.error";
import { RequestContext } from "@common/context/request.context";

@Injectable()
export class ChatReactionService {

    constructor(
        // private readonly reactionMessageChatRepo: ReactionMessageChatRepo,
        // private readonly chatMessageRepo: ChatMessageRepo,
    ) { }

    async reactionMessage(args: ChatReactionMessageInput) {
        return null
        // const message = await this.chatMessageRepo.getMessageUserCanReadById(args.messageId)

        // if (!message) {
        //     throw OfficeError.ChatMessageNotFound
        // }

        // const react = this.reactionMessageChatRepo.create()
        // react.stickerPath = args.stickerPath
        // react.user = await RequestContext.currentUser()
        // react.createdBy = react.user.id
        // react.messageId = args.messageId

        // return react.save();
    }
}
