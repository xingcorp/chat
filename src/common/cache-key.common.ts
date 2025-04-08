export const CACHE_KEY = {
    K_ORG_WORK_PROFILE : 'K_ORG_WORK_PROFILE',
    SEED: {
        seedUpdateProjectData: 'seedUpdateProjectData',
        seedUpdateTaskKey: 'seedUpdateTaskKey',
    },
    TASK: {
        GET_KEY: (id: string) => `TASK__GET_KEY_${id}`,
        NOTIFY: {
            NEED_TO_DO: `TASK__NOTIFY__NEED_TO_DO`,
            LATE: `TASK__NOTIFY__LATE`,
        },
        LOG: {
            ATTACHMENT: 'TASK__LOG__ATTACHMENT'
        }
    },
    USER: {
        IDENTITY_PROFILE: 'USER__IDENTITY_PROFILE',
    },
    MEETING_SCHEDULE: {
        RESOLVER_FIELD: {
            HOST: (id: string) => `MEETING_SCHEDULE__RESOLVER_FIELD__HOST__${id}`,
            PARTICIPANTS: (id: string) => `MEETING_SCHEDULE__RESOLVER_FIELD__PARTICIPANTS__${id}`,
        }
    },
    WIKI: {
        LATEST_LIST: (id: string) => `WIKI__LATEST_LIST__${id}`,
        VERSION: {
            THUMBNAIL: (id: string) => `WIKI__VERSION__THUMBNAIL__${id}`,
            ATTACHMENT: (id: string) => `WIKI__VERSION__ATTACHMENT__${id}`,
        }
    }
}