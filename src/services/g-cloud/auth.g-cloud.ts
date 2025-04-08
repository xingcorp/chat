import * as dotenv from 'dotenv';
dotenv.config();

import { GoogleAuth } from "googleapis-common";

const CREDENTIALS = JSON.parse(process.env.GOOGLE_AUTH_CERTS ?? "")

const auth = new GoogleAuth({
    credentials: CREDENTIALS,
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
});

export const gcpGetClient = async () => {
    return auth.getClient();
};

export const gclGetCredentialValue = (key: string) => CREDENTIALS[key] ?? null

export const gcpGetToken = async () => {
    return auth.getAccessToken();
}