import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Supabase Storage over its REST API, with the service-role key — the bucket
 * is private, so clients only ever touch it through short-lived signed URLs
 * this service hands out.
 */
@Injectable()
export class StorageService {
  constructor(private readonly configService: ConfigService) {}

  private get bucket(): string {
    return this.configService.getOrThrow<string>('supabase.photoBucket');
  }

  /** A one-time URL the client PUTs the file to. */
  async createSignedUploadUrl(path: string): Promise<string> {
    // Storage rejects a JSON request with an empty body, hence the `{}`.
    const body = await this.request<{ url: string }>(
      'POST',
      `/object/upload/sign/${this.bucket}/${path}`,
      {},
    );
    return this.absolute(body.url);
  }

  /** Signed download URLs, keyed by path; paths that fail are left out. */
  async createSignedUrls(paths: string[]): Promise<Map<string, string>> {
    const urls = new Map<string, string>();
    if (paths.length === 0) {
      return urls;
    }
    const rows = await this.request<
      { path: string | null; signedURL: string | null }[]
    >('POST', `/object/sign/${this.bucket}`, {
      expiresIn: this.configService.getOrThrow<number>(
        'supabase.photoUrlTtlSeconds',
      ),
      paths,
    });
    for (const row of rows) {
      if (row.path && row.signedURL) {
        urls.set(row.path, this.absolute(row.signedURL));
      }
    }
    return urls;
  }

  async remove(paths: string[]): Promise<void> {
    if (paths.length > 0) {
      await this.request('DELETE', `/object/${this.bucket}`, {
        prefixes: paths,
      });
    }
  }

  private absolute(relative: string): string {
    const base = this.configService.getOrThrow<string>('supabase.url');
    return `${base}/storage/v1${relative}`;
  }

  private async request<T>(
    method: string,
    path: string,
    body?: unknown,
  ): Promise<T> {
    const key = this.configService.get<string>('supabase.serviceRoleKey');
    if (!key) {
      throw new ServiceUnavailableException('Photo storage is not configured');
    }
    const response = await fetch(this.absolute(path), {
      method,
      headers: {
        Authorization: `Bearer ${key}`,
        apikey: key,
        'Content-Type': 'application/json',
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    if (!response.ok) {
      throw new ServiceUnavailableException(
        `Photo storage request failed (${response.status})`,
      );
    }
    return (await response.json()) as T;
  }
}
