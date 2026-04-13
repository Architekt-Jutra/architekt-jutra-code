/**
 * Type declarations for the PluginSDK loaded via script tag from the host.
 * The actual SDK is loaded as an IIFE that sets window.PluginSDK.
 *
 * Usage: import { getSDK } from "../../sdk";
 */

/** Context injected by the host when rendering a plugin iframe. */
export interface PluginContext {
  extensionPoint: string;
  pluginId: string;
  pluginName: string;
  hostOrigin: string;
  /** Present only for product-scoped extension points (product.detail.tabs, product.detail.info). */
  productId?: string;
}

/** A plugin-owned custom object stored in the host database. */
export interface PluginObject {
  id: string;
  pluginId: string;
  objectType: string;
  objectId: string;
  data: Record<string, unknown>;
  /** Bound entity type (e.g. "PRODUCT", "CATEGORY"). Null when unbound. */
  entityType?: string;
  /** Bound entity ID. Always paired with entityType — both present or both null. */
  entityId?: string;
}

export interface PluginSDKType {
  /** Access host application data (products, plugins, arbitrary API calls). */
  hostApp: {
    /** List products with optional filtering/sorting (e.g. { category: 1, search: "foo", sort: "name,asc" }). */
    getProducts(params?: Record<string, unknown>): Promise<unknown[]>;
    /** Get a single product by ID. */
    getProduct(productId: string): Promise<unknown>;
    /** List all registered plugins. */
    getPlugins(): Promise<unknown[]>;
    /** Get the current user's JWT token from the host. Use to authenticate plugin backend API calls. */
    getToken(): Promise<string | null>;
    /** Raw fetch against the host API. Only /api/ paths allowed; credentials stripped; no path traversal. */
    fetch(url: string, options?: { method?: string; headers?: Record<string, string>; body?: string }): Promise<{
      status: number;
      headers: Record<string, string>;
      body: string;
    }>;
  };
  /** Plugin-scoped operations — data storage, context, custom objects. */
  thisPlugin: {
    /** Synchronously returns the context the host passed when rendering this iframe. */
    getContext(): PluginContext;
    /** Shortcut for getContext().pluginId */
    readonly pluginId: string;
    /** Shortcut for getContext().pluginName */
    readonly pluginName: string;
    /** Shortcut for getContext().productId — present only for product-scoped extension points. */
    readonly productId: string | undefined;
    /** Read this plugin's data attached to a product. Each plugin has its own namespace. */
    getData(productId: string): Promise<unknown>;
    /** Replace this plugin's data on a product (full overwrite, not merge). */
    setData(productId: string, data: Record<string, unknown>): Promise<unknown>;
    /** Remove this plugin's data from a product. */
    removeData(productId: string): Promise<unknown>;
    /** CRUD for plugin-owned custom objects, stored in the host's plugin_objects table. */
    objects: {
      /**
       * List objects of a given type, optionally filtered by entity binding and/or JSONB data.
       * Without options: returns all objects of that type for this plugin.
       * With entityType+entityId: server-side filter to objects bound to that entity.
       * With filter: JSONB filter in "jsonPath:operator:value" format (operators: eq, gt, lt, exists, bool).
       */
      list(type: string, options?: { entityType?: string; entityId?: string; filter?: string }): Promise<PluginObject[]>;
      /**
       * List ALL objects (any type) bound to a specific entity. Useful for cross-type queries
       * like "give me everything this plugin stores for product #42".
       */
      listByEntity(entityType: string, entityId: string, options?: { filter?: string }): Promise<PluginObject[]>;
      /** Get a single object by type and ID. Throws if not found. */
      get(type: string, id: string): Promise<PluginObject>;
      /**
       * Upsert an object. Creates if new, replaces data if exists.
       * Pass entityType+entityId in options to bind the object to a host entity (e.g. PRODUCT).
       * Omitting entity options clears any existing binding — this is intentional (explicit intent model).
       */
      save(type: string, id: string, data: Record<string, unknown>, options?: { entityType?: string; entityId?: string }): Promise<PluginObject>;
      /** Delete an object. Throws if not found. */
      delete(type: string, id: string): Promise<unknown>;
    };
  };
}

declare global {
  interface Window {
    PluginSDK: PluginSDKType;
  }
}

/** Get the PluginSDK instance from the global window object. Only available when loaded inside a host iframe. */
export function getSDK(): PluginSDKType {
  return window.PluginSDK;
}
