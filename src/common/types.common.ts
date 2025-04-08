import { Stream } from "stream";

export type MediaType = "audio" | "image" | "video" | "file";

export async function streamToBuffer(stream: Stream): Promise<Buffer> {
  return new Promise<Buffer>((resolve, reject) => {
    const buffers = Array<any>();

    stream.on("data", (chunk) => buffers.push(chunk));
    stream.on("end", () => resolve(Buffer.concat(buffers)));
    stream.on("error", (err) => reject(`error converting stream - ${err}`));
  });
}

export function extractMediaTypeFromMimeType(mimetye: string): MediaType {
  const rawMediaType = mimetye.split("/").shift();
  switch (rawMediaType) {
    case "image":
      return "image";
    case "audio":
      return "audio";
    case "video":
      return "video";
    default:
      return "file";
  }
}
