import type { Product } from "./types";
import { sendMessageAndWait } from "./messaging";

function getHostOrigin(): string {
  return (window as unknown as { __pluginHostOrigin: string }).__pluginHostOrigin;
}

export const hostApp = {
  getProducts(params?: Record<string, unknown>): Promise<Product[]> {
    return sendMessageAndWait("getProducts", params ?? {}, getHostOrigin()) as Promise<Product[]>;
  },

  getProduct(productId: string): Promise<Product> {
    return sendMessageAndWait("getProduct", { productId }, getHostOrigin()) as Promise<Product>;
  },

  getPlugins(): Promise<unknown[]> {
    return sendMessageAndWait("getPlugins", {}, getHostOrigin()) as Promise<unknown[]>;
  },

  getToken(): Promise<string | null> {
    return sendMessageAndWait("getToken", {}, getHostOrigin()) as Promise<string | null>;
  },

  fetch(url: string, options?: { method?: string; headers?: Record<string, string>; body?: string }): Promise<{
    status: number;
    headers: Record<string, string>;
    body: string;
  }> {
    return sendMessageAndWait("pluginFetch", { url, ...options }, getHostOrigin()) as Promise<{
      status: number;
      headers: Record<string, string>;
      body: string;
    }>;
  },
};
