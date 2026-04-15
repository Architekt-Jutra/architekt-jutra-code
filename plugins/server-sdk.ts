/**
 * Server-side SDK for plugins to communicate with the host API.
 * Mirrors the browser SDK's API surface but uses HTTP fetch instead of postMessage.
 *
 * Usage:
 *   import { createServerSDK } from "../../server-sdk";
 *   const sdk = createServerSDK("my-plugin");
 */

export interface PluginObject {
  id: string;
  pluginId: string;
  objectType: string;
  objectId: string;
  data: Record<string, unknown>;
  entityType?: string;
  entityId?: string;
}

export interface ServerSDK {
  hostApp: {
    getProducts(params?: Record<string, unknown>): Promise<unknown[]>;
    getProduct(productId: string): Promise<unknown>;
    fetch(path: string, options?: { method?: string; headers?: Record<string, string>; body?: string }): Promise<Response>;
  };
  thisPlugin: {
    getData(productId: string): Promise<unknown>;
    setData(productId: string, data: Record<string, unknown>): Promise<unknown>;
    removeData(productId: string): Promise<unknown>;
    objects: {
      list(type: string, options?: { entityType?: string; entityId?: string; filter?: string }): Promise<PluginObject[]>;
      listByEntity(entityType: string, entityId: string, options?: { filter?: string }): Promise<PluginObject[]>;
      get(type: string, id: string): Promise<PluginObject>;
      save(type: string, id: string, data: Record<string, unknown>, options?: { entityType?: string; entityId?: string }): Promise<PluginObject>;
      delete(type: string, id: string): Promise<unknown>;
    };
  };
}

const DEFAULT_HOST_BASE_URL = "http://localhost:8080";

/**
 * Create a server-side SDK instance for a plugin.
 *
 * @param pluginId - The plugin's unique identifier
 * @param hostBaseUrl - Base URL of the host application (defaults to HOST_BASE_URL env or localhost:8080)
 * @param request - Optional incoming HTTP request. The SDK extracts the Authorization header
 *   and forwards it to all host API calls, so the plugin acts on behalf of the logged-in user.
 */
export function createServerSDK(
  pluginId: string,
  hostBaseUrl?: string,
  request?: { headers: { authorization?: string } },
): ServerSDK {
  const baseUrl = hostBaseUrl ?? process.env.HOST_BASE_URL ?? DEFAULT_HOST_BASE_URL;
  const raw = request?.headers?.authorization;
  const bearerToken = raw?.startsWith("Bearer ") ? raw.slice(7) : raw;

  async function hostFetch(path: string, options?: { method?: string; headers?: Record<string, string>; body?: string }): Promise<Response> {
    const url = `${baseUrl}${path}`;
    return fetch(url, {
      method: options?.method ?? "GET",
      headers: {
        "Content-Type": "application/json",
        ...options?.headers,
        ...(bearerToken ? { Authorization: `Bearer ${bearerToken}` } : {}),
      },
      body: options?.body,
    });
  }

  async function hostFetchJson<T>(path: string, options?: { method?: string; headers?: Record<string, string>; body?: string }): Promise<T> {
    const res = await hostFetch(path, options);
    if (!res.ok) {
      const body = await res.text();
      throw new Error(`Host API error ${res.status} ${options?.method ?? "GET"} ${path}: ${body}`);
    }
    return (await res.json()) as T;
  }

  return {
    hostApp: {
      async getProducts(params) {
        const query = params ? "?" + new URLSearchParams(
          Object.entries(params).map(([k, v]) => [k, String(v)])
        ).toString() : "";
        return hostFetchJson<unknown[]>(`/api/products${query}`);
      },
      async getProduct(productId) {
        return hostFetchJson<unknown>(`/api/products/${productId}`);
      },
      fetch: hostFetch,
    },
    thisPlugin: {
      async getData(productId) {
        return hostFetchJson<unknown>(`/api/plugins/${pluginId}/products/${productId}/data`);
      },
      async setData(productId, data) {
        return hostFetchJson<unknown>(`/api/plugins/${pluginId}/products/${productId}/data`, {
          method: "PUT",
          body: JSON.stringify(data),
        });
      },
      async removeData(productId) {
        return hostFetchJson<unknown>(`/api/plugins/${pluginId}/products/${productId}/data`, {
          method: "DELETE",
        });
      },
      objects: {
        async list(type, options) {
          const params = new URLSearchParams();
          if (options?.entityType) params.set("entityType", options.entityType);
          if (options?.entityId) params.set("entityId", options.entityId);
          if (options?.filter) params.set("filter", options.filter);
          const query = params.toString() ? `?${params}` : "";
          return hostFetchJson<PluginObject[]>(`/api/plugins/${pluginId}/objects/${type}${query}`);
        },
        async listByEntity(entityType, entityId, options) {
          const params = new URLSearchParams({ entityType, entityId });
          if (options?.filter) params.set("filter", options.filter);
          return hostFetchJson<PluginObject[]>(`/api/plugins/${pluginId}/objects?${params}`);
        },
        async get(type, id) {
          return hostFetchJson<PluginObject>(`/api/plugins/${pluginId}/objects/${type}/${id}`);
        },
        async save(type, id, data, options) {
          const params = new URLSearchParams();
          if (options?.entityType) params.set("entityType", options.entityType);
          if (options?.entityId) params.set("entityId", options.entityId);
          const query = params.toString() ? `?${params}` : "";
          return hostFetchJson<PluginObject>(`/api/plugins/${pluginId}/objects/${type}/${id}${query}`, {
            method: "PUT",
            body: JSON.stringify(data),
          });
        },
        async delete(type, id) {
          return hostFetchJson<unknown>(`/api/plugins/${pluginId}/objects/${type}/${id}`, {
            method: "DELETE",
          });
        },
      },
    },
  };
}
