import { describe, expect, it, vi, beforeEach } from "vitest";
import { waitFor } from "@testing-library/react";

describe("Plugin SDK Auth", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  describe("handlePluginFetch JWT injection", () => {
    it("injects Authorization header from localStorage auth_token", async () => {
      // Store a token in localStorage
      localStorage.setItem("auth_token", "test-jwt-token");

      const { createMessageHandler } = await import("../plugins/PluginMessageHandler");

      const mockIframe = document.createElement("iframe");
      document.body.appendChild(mockIframe);

      const mockRegistry = {
        findBySource: vi.fn().mockReturnValue({
          pluginId: "warehouse",
          pluginUrl: "http://localhost:3001",
        }),
      };

      const fetchSpy = vi.spyOn(globalThis, "fetch").mockResolvedValue(
        new Response(JSON.stringify({ ok: true }), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }),
      );

      const postMessageSpy = vi.fn();
      Object.defineProperty(mockIframe.contentWindow, "postMessage", {
        value: postMessageSpy,
        writable: true,
      });

      const handler = createMessageHandler(mockRegistry as any);

      const event = new MessageEvent("message", {
        data: {
          requestId: "aj.plugin.auth-test",
          type: "pluginFetch",
          payload: { url: "/api/products", method: "GET" },
        },
        origin: "http://localhost:3001",
        source: mockIframe.contentWindow,
      });

      handler(event);

      await waitFor(() => {
        expect(fetchSpy).toHaveBeenCalled();
      });

      const [, fetchOptions] = fetchSpy.mock.calls[0];
      const headers = fetchOptions?.headers as Record<string, string>;
      expect(headers["Authorization"]).toBe("Bearer test-jwt-token");

      fetchSpy.mockRestore();
      localStorage.removeItem("auth_token");
      document.body.removeChild(mockIframe);
    });
  });

  describe("server-sdk JWT propagation", () => {
    it("includes Authorization header when token is provided", async () => {
      const fetchSpy = vi.spyOn(globalThis, "fetch").mockResolvedValue(
        new Response(JSON.stringify([]), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }),
      );

      const { createServerSDK } = await import("../../../../../plugins/server-sdk");
      const sdk = createServerSDK("test-plugin", "http://localhost:8080", { headers: { authorization: "Bearer my-jwt-token" } });

      await sdk.hostApp.getProducts();

      expect(fetchSpy).toHaveBeenCalledOnce();
      const [, fetchOptions] = fetchSpy.mock.calls[0];
      const headers = fetchOptions?.headers as Record<string, string>;
      expect(headers["Authorization"]).toBe("Bearer my-jwt-token");

      fetchSpy.mockRestore();
    });
  });

  describe("server-sdk data endpoint URLs", () => {
    it("uses /products/{id}/data path for getData, setData, removeData", async () => {
      const fetchSpy = vi.spyOn(globalThis, "fetch").mockImplementation(() =>
        Promise.resolve(
          new Response(JSON.stringify({}), {
            status: 200,
            headers: { "Content-Type": "application/json" },
          }),
        ),
      );

      const { createServerSDK } = await import("../../../../../plugins/server-sdk");
      const sdk = createServerSDK("my-plugin", "http://localhost:8080");

      // Test getData URL
      await sdk.thisPlugin.getData("42");
      expect(fetchSpy.mock.calls[0][0]).toBe(
        "http://localhost:8080/api/plugins/my-plugin/products/42/data",
      );

      // Test setData URL
      await sdk.thisPlugin.setData("42", { stock: true });
      expect(fetchSpy.mock.calls[1][0]).toBe(
        "http://localhost:8080/api/plugins/my-plugin/products/42/data",
      );

      // Test removeData URL
      await sdk.thisPlugin.removeData("42");
      expect(fetchSpy.mock.calls[2][0]).toBe(
        "http://localhost:8080/api/plugins/my-plugin/products/42/data",
      );

      fetchSpy.mockRestore();
    });
  });
});
