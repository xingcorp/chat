import { IndexDefinition } from "./open-search.interface";

export const messageIndexName = 'office_chat_message'
const messageIndex: IndexDefinition = {
    "settings": {
        "analysis": {
            "tokenizer": {
                "ngram_tokenizer": {
                    "type": "ngram",
                    "min_gram": 2,
                    "max_gram": 3,
                    "token_chars": [
                        "letter",
                        "digit"
                    ]
                }
            },
            "analyzer": {
                "file_message_analyzer": {
                    "type": "custom",
                    "tokenizer": "ngram_tokenizer",
                    "filter": [
                        "lowercase"
                    ]
                }
            }
        }
    },
    "mappings": {
        "properties": {
            "conversationId": {
                "type": "keyword"
            },
            "createdAt": {
                "type": "long"
            },
            "id": {
                "type": "keyword"
            },
            "message": {
                "type": "text",
                "analyzer": "file_message_analyzer"
            },
            "fileName": {
                "type": "text",
                "analyzer": "file_message_analyzer"
            },
            "senderId": {
                "type": "keyword"
            },
            "type": {
                "type": "keyword"
            }
        }
    }
};

export const MapIndexOpenSearch = {
    [messageIndexName]: messageIndex
} as Record<string, IndexDefinition>;
