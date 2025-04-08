import * as dotenv from 'dotenv';

dotenv.config();

import { cert, initializeApp as initializeAppAdmin } from "firebase-admin/app";
import { getFirestore as getFirestoreAdmin } from "firebase-admin/firestore";
import { getDownloadURL, getStorage } from "firebase-admin/storage";

const firestoreAdmin = initializeAppAdmin({
    credential: cert(JSON.parse(process.env.GOOGLE_AUTH_CERTS_FIREBASE_ADMIN)),
    databaseURL: JSON.parse(process.env.GOOGLE_AUTH_CERTS_FIREBASE)['databaseURL'],
});

const storage = getStorage(firestoreAdmin)

const dbAdmin = getFirestoreAdmin(firestoreAdmin);

type SourceDoc = {
    collection: string,
    doc: string,
}

export const firebaseGetSubDocSnap = async (source: SourceDoc[]) => {
    let ref: any = dbAdmin

    source.map(item => ref = ref.collection(item.collection).doc(item.doc))

    return ref.get()
}

export const firebaseListCollections = async (source: SourceDoc[] = []) => {
    const list = []
    let ref: any = dbAdmin

    source.map(item => ref = ref.collection(item.collection).doc(item.doc))

    await ref.listCollections()
        .then(snapshot => {
            snapshot.forEach(snaps => {
                list.push(snaps["_queryOptions"].collectionId)
            })
        })
        .catch(error => console.error(error));

    // console.log(list)
    return list
}

export const firebaseDownloadUrl = async (bucket: string, path: string) => {
    const file = storage.bucket(bucket).file(path);

    return getDownloadURL(file)
}

export const firebaseGetAllDocs = async (path: string, options?: any) => {
    let snapshot: any = dbAdmin.collection(path)

    if (options) {
        if (options.orderBy) {
            snapshot = snapshot.orderBy(options.orderBy.name, options.orderBy.ordinal)
        }

        if (options.where && options.where.length) {
            options.where.map(where => {
                snapshot = snapshot.where(where.name, where.operation, where.value)
            })
        }
    }

    return (await snapshot.get()).docs.map(doc => doc.data());
}

export const firebaseCreateDoc = async (collections: string, docId: string, data: any) => {
    try {
        const doc = dbAdmin.collection(collections).doc(docId);

        return doc.set(data)
    } catch (e) {
        console.log('create user to firebase error:', e)
        return null
    }
}

export const firebaseUpdateDoc = async (collections: string, docId: string, data: any) => {
    try {
        const doc = dbAdmin.collection(collections).doc(docId);

        return doc.update(data)
    } catch (e) {
        console.log('firebaseUpdateDoc', e)
        return null
    }
}

export const firebaseRemoveDoc = async (collections: string, docId: string) => {
    const doc = dbAdmin.collection(collections).doc(docId);

    return doc.delete()
}

export const firebaseIsDocExist = async (collections: string, docId: string) => {
    let isExist = false

    await dbAdmin.collection(collections).doc(docId).get()
        .then(docSnapshot => {
            isExist = docSnapshot.exists
        })

    return isExist
}

export const firebaseListDocumentIds = async (collection: string) => {
    let snapshot: any = dbAdmin.collection(collection)

    return (await snapshot.listDocuments()).map(doc => doc.id)
    // return (await snapshot.listDocuments()).map(async doc => {
    //     console.log(doc)
    //     let res = []
    //     res[doc.id] = await (await doc.listCollections()).map(item => item.id)
    //     return res
    // });
}
