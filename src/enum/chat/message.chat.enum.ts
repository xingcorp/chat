export enum ChatMessageType {
    TEXT = 'TEXT',
    IMAGE = 'IMAGE',
    VIDEO = 'VIDEO',
    LOCATION = 'LOCATION',
    CALL = 'CALL',
    VOICE_NOTE = 'VOICE_NOTE',
    DOC = 'DOC',
    AUDIO = 'AUDIO',
    STICKER = 'STICKER',
}

export enum ChatMessageReactionAct {
    ADD = 1,
    REVOKE = 0,
}

export enum ChatMessageAct {
    EDIT = 1,
    DEL = 0,
}