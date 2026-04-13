import { api } from "../api/client";
import type { iframeRegistry as IframeRegistryType } from "./iframeRegistry";

interface PluginMessage {
  requestId: string;
  type: string;
  payload: Record<string, unknown>;
}

interface PluginMessageResponse {
  responseId: string;
  payload: unknown;
  error?: string;
}

interface MessageHandlerOptions {
  onFilterChange?: (pluginId: string, payload: Record<string, unknown>) => void;
}

type IframeRegistry = typeof IframeRegistryType;

const REQUEST_ID_PREFIX = "aj.plugin.";

// CORS-safelisted response headers per Req 11c
const SAFELISTED_HEADERS = new Set([
  "cache-control",
  "content-language",
  "content-length",
  "content-type",
  "expires",
  "last-modified",
  "pragma",
]);

function sendResponse(source: MessageEventSource, origin: string, response: PluginMessageResponse): void {
  (source as Window).postMessage(response, origin);
}

function sendError(source: MessageEventSource, origin: string, requestId: string, error: string): void {
  sendResponse(source, origin, { responseId: requestId, payload: null, error });
}

async function handlePluginFetch(
  payload: Record<string, unknown>,
): Promise<{ status: number; headers: Record<string, string>; body: string }> {
  const url = payload.url as string;
  const method = (payload.method as string) ?? "GET";
  const headers = (payload.headers as Record<string, string>) ?? {};
  const body = payload.body as string | undefined;

  // Req 11c: Reject URLs with path traversal
  if (url.includes("..")) {
    throw new Error("URL must not contain path traversal (..)");
  }

  // Security: Restrict to /api/ prefix only to prevent SSRF
  if (!url.startsWith("/api/")) {
    throw new Error("pluginFetch only allows /api/ URLs");
  }

  // Inject JWT token for authenticated plugin fetch requests
  const token = localStorage.getItem("auth_token");

  // Req 11c: Strip security-sensitive options, add X-Requested-With
  const fetchOptions: RequestInit = {
    method,
    credentials: "omit",
    headers: {
      ...headers,
      "X-Requested-With": "PluginFetch",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
  };

  if (body && method !== "GET" && method !== "HEAD") {
    fetchOptions.body = body;
  }

  const response = await fetch(url, fetchOptions);

  // Req 11c: Only return CORS-safelisted headers
  const responseHeaders: Record<string, string> = {};
  response.headers.forEach((value, key) => {
    if (SAFELISTED_HEADERS.has(key.toLowerCase())) {
      responseHeaders[key] = value;
    }
  });

  const responseBody = await response.text();

  return {
    status: response.status,
    headers: responseHeaders,
    body: responseBody,
  };
}

// API-based message handlers that proxy SDK calls to backend
async function handleApiMessage(
  type: string,
  payload: Record<string, unknown>,
  pluginId: string,
): Promise<unknown> {
  switch (type) {
    case "getProducts": {
      const params = payload as { category?: number; search?: string; sort?: string };
      const searchParams = new URLSearchParams();
      if (params.category) searchParams.set("category", String(params.category));
      if (params.search) searchParams.set("search", params.search);
      if (params.sort) searchParams.set("sort", params.sort);
      const query = searchParams.toString();
      return api.get(`/products${query ? `?${query}` : ""}`);
    }
    case "getProduct":
      return api.get(`/products/${payload.productId}`);
    case "getPlugins":
      return api.get("/plugins");
    case "getData":
      return api.get(`/plugins/${pluginId}/products/${payload.productId}/data`);
    case "setData":
      return api.put(`/plugins/${pluginId}/products/${payload.productId}/data`, payload.data);
    case "removeData":
      return api.delete(`/plugins/${pluginId}/products/${payload.productId}/data`);
    case "objectsList": {
      const listParams = new URLSearchParams();
      if (payload.entityType) listParams.set("entityType", String(payload.entityType));
      if (payload.entityId) listParams.set("entityId", String(payload.entityId));
      if (payload.filter) listParams.set("filter", String(payload.filter));
      const listQuery = listParams.toString();
      return api.get(`/plugins/${pluginId}/objects/${payload.objectType}${listQuery ? `?${listQuery}` : ""}`);
    }
    case "objectsListByEntity": {
      const entityParams = new URLSearchParams();
      entityParams.set("entityType", String(payload.entityType));
      entityParams.set("entityId", String(payload.entityId));
      if (payload.filter) entityParams.set("filter", String(payload.filter));
      return api.get(`/plugins/${pluginId}/objects?${entityParams.toString()}`);
    }
    case "objectsGet":
      return api.get(`/plugins/${pluginId}/objects/${payload.objectType}/${payload.objectId}`);
    case "objectsSave": {
      const saveParams = new URLSearchParams();
      if (payload.entityType) saveParams.set("entityType", String(payload.entityType));
      if (payload.entityId) saveParams.set("entityId", String(payload.entityId));
      const saveQuery = saveParams.toString();
      return api.put(
        `/plugins/${pluginId}/objects/${payload.objectType}/${payload.objectId}${saveQuery ? `?${saveQuery}` : ""}`,
        payload.data,
      );
    }
    case "objectsDelete":
      return api.delete(`/plugins/${pluginId}/objects/${payload.objectType}/${payload.objectId}`);
    default:
      throw new Error(`Unknown message type: ${type}`);
  }
}

export function createMessageHandler(
  registry: IframeRegistry,
  options?: MessageHandlerOptions,
): (event: MessageEvent) => void {
  return (event: MessageEvent) => {
    const data = event.data as PluginMessage | undefined;
    if (!data?.requestId || !data?.type) return;

    // Validate "aj.plugin." prefix
    if (!data.requestId.startsWith(REQUEST_ID_PREFIX)) return;

    // Resolve plugin by source iframe
    const pluginInfo = registry.findBySource(event.source);
    if (!pluginInfo) return;

    // Validate origin matches registered plugin URL
    try {
      const expectedOrigin = new URL(pluginInfo.pluginUrl).origin;
      if (event.origin !== expectedOrigin) return;
    } catch {
      return;
    }

    const { requestId, type, payload } = data;

    // Fire-and-forget: filterChange (Req 11b)
    if (type === "filterChange") {
      options?.onFilterChange?.(pluginInfo.pluginId, payload);
      return; // No response sent
    }

    // Return the current user's JWT token to the plugin
    if (type === "getToken") {
      const token = localStorage.getItem("auth_token");
      if (event.source) {
        sendResponse(event.source, event.origin, {
          responseId: requestId,
          payload: token,
        });
      }
      return;
    }

    // Route pluginFetch separately (different response format)
    if (type === "pluginFetch") {
      handlePluginFetch(payload)
        .then((result) => {
          if (event.source) {
            sendResponse(event.source, event.origin, {
              responseId: requestId,
              payload: result,
            });
          }
        })
        .catch((err) => {
          if (event.source) {
            sendError(event.source, event.origin, requestId, err instanceof Error ? err.message : "Unknown error");
          }
        });
      return;
    }

    // Route all other API-backed message types
    handleApiMessage(type, payload, pluginInfo.pluginId)
      .then((result) => {
        if (event.source) {
          sendResponse(event.source, event.origin, {
            responseId: requestId,
            payload: result,
          });
        }
      })
      .catch((err) => {
        if (event.source) {
          sendError(event.source, event.origin, requestId, err instanceof Error ? err.message : "Unknown error");
        }
      });
  };
}
