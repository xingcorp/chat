import { OfficeTaskProject } from "@models/entities";

export async function seedUpdateProjectData() {
    const projects = await OfficeTaskProject.find({
        where: {
            rootOrg: {
                id: process.env.K_ORG_ID
            }
        }
    })

    for (const item of projects) {
        item.showKey = false

        await item.save()
    }

    return true
}