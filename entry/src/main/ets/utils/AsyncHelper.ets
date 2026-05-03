import { fileIo } from '@kit.CoreFileKit';

export async function processInChunks<T, R>(
  items: T[],
  processor: (item: T, index: number) => Promise<R>,
  chunkSize: number = 50,
  delayMs: number = 10,
  onProgress?: (processed: number, total: number) => void
): Promise<R[]> {
  const results: R[] = [];
  const total = items.length;

  for (let i = 0; i < total; i += chunkSize) {
    const chunk = items.slice(i, Math.min(i + chunkSize, total));

    for (let j = 0; j < chunk.length; j++) {
      const result = await processor(chunk[j], i + j);
      results.push(result);
    }

    if (onProgress) {
      onProgress(Math.min(i + chunkSize, total), total);
    }

    if (i + chunkSize < total && delayMs > 0) {
      await sleep(delayMs);
    }
  }

  return results;
}

export async function readLargeFile(
  filePath: string,
  chunkSize: number = 1024 * 1024,
  onChunk?: (chunk: string, offset: number, total: number) => void
): Promise<string> {
  let file: fileIo.File | null = null;
  try {
    file = await fileIo.open(filePath, fileIo.OpenMode.READ_ONLY);

    const stat = await fileIo.stat(filePath);
    const totalSize = stat.size;

    let result = '';
    let offset = 0;

    while (offset < totalSize) {
      const readSize = Math.min(chunkSize, totalSize - offset);
      const buffer = new ArrayBuffer(readSize);
      const readLen = await fileIo.read(file.fd, buffer);

      if (readLen <= 0) {
        break;
      }

      const uint8Array = new Uint8Array(buffer, 0, readLen);
      const chunk = String.fromCharCode.apply(null, Array.from(uint8Array));
      result += chunk;

      if (onChunk) {
        onChunk(chunk, offset, totalSize);
      }

      offset += readLen;
    }

    return result;
  } finally {
    if (file) {
      await fileIo.close(file.fd);
    }
  }
}

export async function processBatch<T, R>(
  items: T[],
  processor: (item: T, index: number) => Promise<R>,
  batchSize: number = 10,
  onProgress?: (completed: number, total: number) => void
): Promise<R[]> {
  const results: R[] = [];
  const total = items.length;

  for (let i = 0; i < total; i += batchSize) {
    const batch = items.slice(i, Math.min(i + batchSize, total));
    const batchPromises = batch.map((item, idx) => processor(item, i + idx));
    const batchResults = await Promise.all(batchPromises);
    for (let k = 0; k < batchResults.length; k++) {
      results.push(batchResults[k]);
    }

    if (onProgress) {
      onProgress(Math.min(i + batchSize, total), total);
    }
  }

  return results;
}

export async function parseJsonAsync<T>(jsonString: string): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    setTimeout(() => {
      try {
        const result = JSON.parse(jsonString);
        resolve(result as T);
      } catch (error) {
        reject(error);
      }
    }, 0);
  });
}

export async function stringifyJsonAsync(data: object, space?: number): Promise<string> {
  return new Promise<string>((resolve) => {
    setTimeout(() => {
      resolve(JSON.stringify(data, null, space));
    }, 0);
  });
}

export function sleep(ms: number): Promise<void> {
  return new Promise<void>((resolve) => setTimeout(resolve, ms));
}

export async function filterAsync<T>(
  items: T[],
  predicate: (item: T, index: number) => Promise<boolean>
): Promise<T[]> {
  const results = await Promise.all(items.map(predicate));
  return items.filter((_, index) => results[index]);
}

export async function mapAsync<T, R>(
  items: T[],
  mapper: (item: T, index: number) => Promise<R>,
  concurrency: number = 10
): Promise<R[]> {
  const results: R[] = new Array(items.length);
  let index = 0;

  const worker = async () => {
    while (index < items.length) {
      const currentIndex = index++;
      results[currentIndex] = await mapper(items[currentIndex], currentIndex);
    }
  };

  const workers: Promise<void>[] = [];
  const workerCount = Math.min(concurrency, items.length);
  for (let w = 0; w < workerCount; w++) {
    workers.push(worker());
  }
  await Promise.all(workers);

  return results;
}

export async function forEachAsync<T>(
  items: T[],
  iterator: (item: T, index: number) => Promise<void>,
  chunkSize: number = 100,
  onProgress?: (index: number, total: number) => void
): Promise<void> {
  const total = items.length;

  for (let i = 0; i < total; i += chunkSize) {
    const chunk = items.slice(i, Math.min(i + chunkSize, total));

    for (let j = 0; j < chunk.length; j++) {
      await iterator(chunk[j], i + j);
    }

    if (onProgress) {
      onProgress(Math.min(i + chunkSize, total), total);
    }

    if (i + chunkSize < total) {
      await sleep(0);
    }
  }
}

export function isLargeArray<T>(items: T[], threshold: number = 100): boolean {
  return items.length > threshold;
}

export function getRecommendedChunkSize<T>(items: T[]): number {
  const length = items.length;
  if (length < 100) return length;
  if (length < 1000) return 100;
  if (length < 10000) return 500;
  return 1000;
}

export async function readFileAsync(filePath: string): Promise<ArrayBuffer> {
  let file: fileIo.File | null = null;
  try {
    file = await fileIo.open(filePath, fileIo.OpenMode.READ_ONLY);
    const stat = await fileIo.stat(filePath);
    const buffer = new ArrayBuffer(stat.size);
    await fileIo.read(file.fd, buffer);
    return buffer;
  } finally {
    if (file) {
      await fileIo.close(file.fd);
    }
  }
}

export async function writeFileAsync(filePath: string, data: ArrayBuffer): Promise<void> {
  let file: fileIo.File | null = null;
  try {
    file = await fileIo.open(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
    await fileIo.write(file.fd, data);
  } finally {
    if (file) {
      await fileIo.close(file.fd);
    }
  }
}

export async function statFileAsync(filePath: string): Promise<fileIo.Stat> {
  return await fileIo.stat(filePath);
}

export async function existsFileAsync(filePath: string): Promise<boolean> {
  try {
    await fileIo.stat(filePath);
    return true;
  } catch {
    return false;
  }
}