import type { NextApiRequest, NextApiResponse } from "next";
import { b } from "../../../baml_client";
import { createServerSDK } from "../../../../server-sdk";

interface GenerateRequest {
  productId: string | number;
  customInformation?: string;
}

interface ErrorResponse {
  error: string;
  details?: string[];
}

interface GenerateResponse {
  recommendation: string;
  targetCustomer: string;
  pros: string[];
  cons: string[];
  customInformation?: string;
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse<GenerateResponse | ErrorResponse>
) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const body = req.body as Partial<GenerateRequest>;

  const productId = body.productId != null ? String(body.productId).trim() : "";
  if (!productId) {
    return res.status(400).json({
      error: "Missing required fields",
      details: ["productId"],
    });
  }

  const sdk = createServerSDK("ai-description", undefined, req);

  try {
    const product = (await sdk.hostApp.getProduct(productId)) as {
      name: string;
      description: string;
    };

    const result = await b.GenerateProductDescription(
      product.name,
      product.description,
      body.customInformation
    );

    const dataToSave = {
      recommendation: result.recommendation,
      targetCustomer: result.targetCustomer,
      pros: result.pros,
      cons: result.cons,
      ...(body.customInformation ? { customInformation: body.customInformation } : {}),
    };

    await sdk.thisPlugin.objects.save("description", productId, dataToSave, {
      entityType: "PRODUCT",
      entityId: productId,
    });

    return res.status(200).json(dataToSave);
  } catch (err) {
    console.error("Generate failed:", err);
    const message = err instanceof Error ? err.message : String(err);
    const statusMatch = message.match(/Host API error (\d+)/);
    const status = statusMatch ? parseInt(statusMatch[1], 10) : 500;
    return res.status(status).json({ error: message });
  }
}
