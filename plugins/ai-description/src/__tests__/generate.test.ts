import { createMocks } from "node-mocks-http";
import type { NextApiRequest, NextApiResponse } from "next";

const mockGenerateProductDescription = jest.fn();

jest.mock("../../baml_client", () => ({
  b: {
    GenerateProductDescription: (...args: unknown[]) =>
      mockGenerateProductDescription(...args),
  },
}));

const mockGetProduct = jest.fn();
const mockObjectsSave = jest.fn();

jest.mock("../../../server-sdk", () => ({
  createServerSDK: () => ({
    hostApp: {
      getProduct: (...args: unknown[]) => mockGetProduct(...args),
    },
    thisPlugin: {
      objects: {
        save: (...args: unknown[]) => mockObjectsSave(...args),
      },
    },
  }),
}));

import handler from "../pages/api/generate";

describe("POST /api/generate", () => {
  beforeEach(() => {
    mockGenerateProductDescription.mockReset();
    mockGetProduct.mockReset();
    mockObjectsSave.mockReset();
  });

  test("rejects_missingProductId_returns400WithDetails", async () => {
    const { req, res } = createMocks<NextApiRequest, NextApiResponse>({
      method: "POST",
      body: {},
    });

    await handler(req, res);

    expect(res._getStatusCode()).toBe(400);
    const body = JSON.parse(res._getData());
    expect(body.error).toBe("Missing required fields");
    expect(body.details).toContain("productId");
  });

  test("accepts_validRequest_fetchesProductAndReturns200", async () => {
    mockGetProduct.mockResolvedValue({
      name: "Test Product",
      description: "A test product",
    });
    mockGenerateProductDescription.mockResolvedValue({
      recommendation: "Great product",
      targetCustomer: "Developers",
      pros: ["Fast"],
      cons: ["Expensive"],
    });
    mockObjectsSave.mockResolvedValue({});

    const { req, res } = createMocks<NextApiRequest, NextApiResponse>({
      method: "POST",
      body: { productId: "5" },
    });

    await handler(req, res);

    expect(res._getStatusCode()).toBe(200);
    expect(mockGetProduct).toHaveBeenCalledWith("5");
    expect(mockGenerateProductDescription).toHaveBeenCalledWith(
      "Test Product",
      "A test product",
      undefined
    );
  });

  test("generate_successfulCall_returnsStructuredResponseAndSaves", async () => {
    mockGetProduct.mockResolvedValue({
      name: "Widget Pro",
      description: "A productivity widget",
    });
    mockGenerateProductDescription.mockResolvedValue({
      recommendation: "Highly recommended for daily use",
      targetCustomer: "Small business owners",
      pros: ["Affordable", "Easy to use"],
      cons: ["Limited integrations"],
    });
    mockObjectsSave.mockResolvedValue({});

    const { req, res } = createMocks<NextApiRequest, NextApiResponse>({
      method: "POST",
      body: { productId: "42" },
    });

    await handler(req, res);

    expect(res._getStatusCode()).toBe(200);
    const body = JSON.parse(res._getData());
    expect(body.recommendation).toBe("Highly recommended for daily use");
    expect(body.targetCustomer).toBe("Small business owners");
    expect(body.pros).toEqual(["Affordable", "Easy to use"]);
    expect(body.cons).toEqual(["Limited integrations"]);

    expect(mockObjectsSave).toHaveBeenCalledWith(
      "description",
      "42",
      expect.objectContaining({ recommendation: "Highly recommended for daily use" }),
      { entityType: "PRODUCT", entityId: "42" }
    );
  });

  test("generate_bamlFailure_returns500WithUserFacingError", async () => {
    mockGetProduct.mockResolvedValue({
      name: "Widget Pro",
      description: "A productivity widget",
    });
    mockGenerateProductDescription.mockRejectedValue(
      new Error("LLM provider timeout")
    );

    const { req, res } = createMocks<NextApiRequest, NextApiResponse>({
      method: "POST",
      body: { productId: "42" },
    });

    await handler(req, res);

    expect(res._getStatusCode()).toBe(500);
    const body = JSON.parse(res._getData());
    expect(body.error).toBeDefined();
    expect(body.error).not.toContain("LLM provider timeout");
  });

  test("generate_withCustomInformation_passesItToBamlFunction", async () => {
    mockGetProduct.mockResolvedValue({
      name: "Widget Pro",
      description: "A productivity widget",
    });
    mockGenerateProductDescription.mockResolvedValue({
      recommendation: "Good product",
      targetCustomer: "Everyone",
      pros: ["Nice"],
      cons: ["None"],
    });
    mockObjectsSave.mockResolvedValue({});

    const { req, res } = createMocks<NextApiRequest, NextApiResponse>({
      method: "POST",
      body: {
        productId: "42",
        customInformation: "Focus on eco-friendly aspects",
      },
    });

    await handler(req, res);

    expect(mockGenerateProductDescription).toHaveBeenCalledWith(
      "Widget Pro",
      "A productivity widget",
      "Focus on eco-friendly aspects"
    );
  });

  test("generate_productFetchFails_returns500", async () => {
    mockGetProduct.mockRejectedValue(new Error("Host API error 404"));

    const { req, res } = createMocks<NextApiRequest, NextApiResponse>({
      method: "POST",
      body: { productId: "999" },
    });

    await handler(req, res);

    expect(res._getStatusCode()).toBe(500);
  });
});
