import * as dotenv from 'dotenv';

dotenv.config();

import { InfoBlock, InfoField } from "@models/entities";
import { OfficeBlockType } from "@enum/block/block.enum";
import { DataType } from "@models/entities/profile.info.field";
import { LinkFieldType, LinkTableType } from "@enum/block/field.enum";

const data = [
    {
        order: 1,
        name: "Loại nhân viên",
        dataType: DataType.List,
        optionItems: ["Cộng tác viên",
            "Nhân viên chính thức",
            "Nhân viên học việc",
            "Nhân viên thời vụ",
            "Nhân viên thử việc",
            "Thực tập sinh"],
        blockId: "",
    },
    {
        order: 2,
        name: "Nơi làm việc",
        dataType: DataType.List,
        optionItems: [
            "Aoen",
            "Cao Phong",
            "Chợ Lớn",
            "CPN",
            "Điện máy xanh Miền Bắc",
            "Điện máy xanh Miền Nam",
            "Eco",
            "HC",
            "Kho Bình Dương",
            "Kinh doanh GT KV1",
            "Kinh doanh GT KV10A",
            "Kinh doanh GT KV10B",
            "Kinh doanh GT KV11",
            "Kinh doanh GT KV2",
            "Kinh doanh GT KV3",
            "Kinh doanh GT KV3A",
            "Kinh doanh GT KV3B",
            "Kinh doanh GT KV4",
            "Kinh doanh GT KV5",
            "Kinh doanh GT KV6",
            "Kinh doanh GT KV6A",
            "Kinh doanh GT KV6B",
            "Kinh doanh GT KV7",
            "Kinh doanh GT KV8A",
            "Kinh doanh GT KV8B",
            "Kinh doanh GT KV9A",
            "Kinh doanh GT KV9B",
            "KV8B",
            "Media",
            "Nguyễn Kim",
            "Nguyễn Kim Miền Bắc",
            "Nguyễn Kim Miền Nam",
            "Nhà máy",
            "Pico",
            "Samnec",
            "Thị trường",
            "Thiên Hòa",
            "Văn phòng",
            "Văn phòng HN",
            "VP Kiên Giang",
            "VP LVT",
            "VP Quảng Nam"
        ],
        blockId: "",
    },
    {
        order: 3,
        name: "Khu vực làm việc",
        dataType: DataType.List,
        optionItems: ["Miền Bắc", "Miền Nam"],
        blockId: "",
    },
    {
        order: 4,
        name: "Nhóm chi phí",
        dataType: DataType.List,
        optionItems: ["Gián tiếp", "Trực tiếp"],
        blockId: "",
    },
    {
        order: 5,
        name: "Nhóm",
        dataType: DataType.List,
        optionItems: [
            "Nhóm C",
            "Nhóm E",
            "Nhóm L",
            "Nhóm P"
        ],
        blockId: "",
    },
    {
        order: 6,
        name: "Tuyến",
        dataType: DataType.Text,
        blockId: "",
    },
    {
        order: 7,
        name: "Q1/Q2",
        dataType: DataType.List,
        optionItems: [
            "46/54",
            "57/43",
            "65/35",
            "67/33",
            "70/30",
            "75/25",
            "78/22",
            "80/20",
            "82/18",
            "84/16",
            "85/15",
            "87/13",
            "88/12",
            "89/11",
            "90/10",
            "91/09"
        ],
        blockId: "",
    },
    {
        order: 8,
        name: "DL/PT",
        dataType: DataType.List,
        optionItems: [
            "0/100",
            "40/60",
            "46/54",
            "50/50",
            "60/40",
            "67/33",
            "85/15",
            "89/11"
        ],
        blockId: "",
    },
]
const resignData = [
    {
        order: 9,
        name: "Ngày làm việc cuối cùng",
        dataType: DataType.Date,
        blockId: "",
        required: true,
        linkTableType: LinkTableType.User,
        linkFieldType: LinkFieldType.lastWorkingOn
    },
    {
        order: 10,
        name: "Ngày hiệu lực thôi việc",
        dataType: DataType.Date,
        blockId: "",
        required: true,
        linkTableType: LinkTableType.User,
        linkFieldType: LinkFieldType.leaveOn
    },
    {
        order: 11,
        name: "Loại thôi việc",
        dataType: DataType.List,
        blockId: "",
        required: true,
        linkTableType: LinkTableType.User,
        linkFieldType: LinkFieldType.resignationType,
        optionItems: [
            "Nghỉ không lý do",
            "Cho thôi việc",
            "Có đơn xin chấm dứt HĐLĐ",
            "Giảm biên",
            "Không đạt thử việc",
            "Không nhận việc",
            "Không tái ký HĐLĐ",
            "Sa thải do kỷ luật lao động",
            "Thuyên chuyển",
            "Không xác định",
            "Khác",
        ],
    },
    {
        order: 12,
        name: "Lý do thôi việc",
        dataType: DataType.List,
        blockId: "",
        required: true,
        linkTableType: LinkTableType.User,
        linkFieldType: LinkFieldType.resignationReason,
        optionItems: [
            "Chấm dứt HĐLĐ do NLĐ bị áp dụng hình thức KL sa thải",
            "Có đơn xin chấm dứt HĐLĐ",
            "Không tái ký HĐLĐ",
            "NLĐ nghỉ hưu trí, chế độ",
            "Khác",
        ],
    },
    {
        order: 13,
        name: "Diễn giải lý do",
        dataType: DataType.Text_Area,
        blockId: "",
        linkTableType: LinkTableType.User,
        linkFieldType: LinkFieldType.resignationDetailReason,
    },
]

export async function seedFieldWorkProfile() {
    const block = InfoBlock.create({
        name: "Quá trình làm việc",
        relationType: OfficeBlockType.WorkProfile,
        relationId: process.env.K_ORG_ID
    })

    await block.save()
    await block.reload()

    for (const item of data) {
        const field = InfoField.create({
            ...item,
            blockId: block.id
        })

        await field.save()
    }

    return block
}

export async function seedWorkProfileResignSoftField(id: string) {
    const block = await InfoBlock.findOne({
        where: {
            relationType: OfficeBlockType.WorkProfile,
            relationId: id
        }
    })

    for (const item of resignData) {
        const field = InfoField.create({
            ...item,
            blockId: block.id
        })

        await field.save()
    }

    return block
}