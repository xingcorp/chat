export const BRIDGE_TABLE_DB = {
    APPROVAL_FORM_USER: "office-user-have-approval-forms",
    USER_READ_APPROVAL: "relation-user-read-approval",
    TASK_CONFIG_ASSIGNEES: "relation-task-config-assignees",
    APPROVAL_FORM_IN_GROUP: "relation-approval-form-in-group",
    APPROVAL_FORM_GROUP_ORG_CHART: "relation-approval-form-group-org-chart",
    MEETING_SCHEDULE_PARTICIPANTS: "relation-meeting-schedule-participant",
    TASK_LINK_TASK: "relation-task-link-task",
}

export const BRIDGE_TABLE_DB_OBJ = {
    APPROVAL_FORWARD_TO_USER: {
        name: "relation-approval-forward-to-user",
        joinColumn: {
            name: "forwardId"
        },
        inverseJoinColumn: {
            name: "userId"
        },
    },
    WIKI_CATEGORY_ORG_CHART: {
        name: "relation-wiki-category-org-chart",
        joinColumn: {
            name: "categoryWikiId"
        },
        inverseJoinColumn: {
            name: "orgId"
        },
    },
    WIKI_CATEGORY: {
        name: "relation-wiki-category",
        joinColumn: {
            name: "categoryWikiId"
        },
        inverseJoinColumn: {
            name: "wikiId"
        },
    },
    DOCUMENT_TAG_ORG_CHART: {
        name: "relation-document-tag-org-chart",
        joinColumn: {
            name: "tagId"
        },
        inverseJoinColumn: {
            name: "orgId"
        },
    },
    WIKI_DOCUMENT_TAG: {
        name: "relation-wiki-document-tag",
        joinColumn: {
            name: "tagId"
        },
        inverseJoinColumn: {
            name: "wikiId"
        },
    },
    WIKI_VERSION_DOCUMENT_TAG: {
        name: "relation-wiki-versions-document-tag",
        joinColumn: {
            name: "tagId"
        },
        inverseJoinColumn: {
            name: "wikiVersionId"
        },
    },
    WIKI_ORG_CHART: {
        name: "relation-wiki-org-chart",
        joinColumn: {
            name: "wikiId"
        },
        inverseJoinColumn: {
            name: "orgId"
        },
    },
    LEARNING_PROJECT_DEPARTMENT: {
        name: "relation-learning-project-departments",
        joinColumn: {
            name: "projectId"
        },
        inverseJoinColumn: {
            name: "departmentId"
        },
    },
    LEARNING_PROJECT_ORG: {
        name: "relation-learning-project-org-charts",
        joinColumn: {
            name: "projectId"
        },
        inverseJoinColumn: {
            name: "orgId"
        },
    },
    LEARNING_PROJECT_SKILL: {
        name: "relation-learning-project-skill",
        joinColumn: {
            name: "projectId"
        },
        inverseJoinColumn: {
            name: "skillId"
        },
    },

    LEARNING_ADDRESS_PROJECT: {
        name: "relation-learning-project-address",
        joinColumn: {
            name: "projectId"
        },
        inverseJoinColumn: {
            name: "addressId"
        },
    },
    LEARNING_SKILL_ORG: {
        name: "relation-learning-skill-org",
        joinColumn: {
            name: "skillId"
        },
        inverseJoinColumn: {
            name: "orgId"
        },
    },
    LEARNING_PROJECT_CERTIFICATE: {
        name: "relation-learning-project-certificate",
        joinColumn: {
            name: "projectId"
        },
        inverseJoinColumn: {
            name: "certificateId"
        },
    },
    LEARNING_CERTIFICATE_ORG: {
        name: "relation-learning-certificate-org",
        joinColumn: {
            name: "certificateId"
        },
        inverseJoinColumn: {
            name: "orgId"
        },
    },
    LEARNING_EXAMINATION_ORG: {
        name: "relation-learning-examination-org",
        joinColumn: {
            name: "examinationId"
        },
        inverseJoinColumn: {
            name: "orgId"
        },
    },
    LEARNING_REQUIREMENT_PROJECT: {
        name: "relation-learning-requirement-project",
        joinColumn: {
            name: "requirementId"
        },
        inverseJoinColumn: {
            name: "projectId"
        },
    },
    LEARNING_REQUIREMENT_CERTIFICATE: {
        name: "relation-learning-requirement-certificate",
        joinColumn: {
            name: "requirementId"
        },
        inverseJoinColumn: {
            name: "certificateId"
        },
    },
}