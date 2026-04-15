import { useEffect, useState, useMemo } from "react";
import { getSDK } from "../../../sdk";
import { toProductDescription } from "../domain";
import type { ProductDescription } from "../domain";

export default function ProductTab() {
  const sdk = useMemo(() => (typeof window !== "undefined" ? getSDK() : null), []);
  const productId = sdk?.thisPlugin.productId ?? "";

  const [description, setDescription] = useState<ProductDescription | null>(null);
  const [customInformation, setCustomInformation] = useState("");
  const [loading, setLoading] = useState(true);
  const [generating, setGenerating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [canEdit, setCanEdit] = useState(false);

  useEffect(() => {
    if (!sdk) return;
    if (!productId) {
      setError("Product ID is missing. This tab must be opened from a product detail page.");
      setLoading(false);
      return;
    }

    async function load() {
      try {
        const token = await sdk!.hostApp.getToken();
        if (token) {
          try {
            const payload = JSON.parse(atob(token.split(".")[1]));
            const permissions = (payload.permissions ?? []) as string[];
            setCanEdit(permissions.includes("EDIT"));
          } catch { /* invalid token — leave canEdit false */ }
        }

        const objects = await sdk!.thisPlugin.objects.listByEntity("PRODUCT", productId);
        if (objects.length > 0) {
          const mapped = toProductDescription(objects[0]);
          setDescription(mapped);
          setCustomInformation(mapped.customInformation ?? "");
        }
      } catch {
        setError("Failed to load existing description.");
      } finally {
        setLoading(false);
      }
    }
    void load();
  }, [productId, sdk]);

  async function handleGenerate() {
    if (!sdk) return;
    setError(null);
    setGenerating(true);

    try {
      const token = await sdk.hostApp.getToken();
      const response = await fetch("/api/generate", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: JSON.stringify({
          productId,
          customInformation: customInformation.trim() || undefined,
        }),
      });

      if (!response.ok) {
        const body = (await response.json()) as { error?: string };
        throw new Error(body.error ?? "Failed to generate description.");
      }

      const result = (await response.json()) as {
        recommendation: string;
        targetCustomer: string;
        pros: string[];
        cons: string[];
        customInformation?: string;
      };

      setDescription({
        objectId: productId,
        recommendation: result.recommendation,
        targetCustomer: result.targetCustomer,
        pros: result.pros,
        cons: result.cons,
        customInformation: result.customInformation,
      });
    } catch (err) {
      if (err instanceof TypeError && err.message === "Failed to fetch") {
        setError("Network error. Please check your connection and try again.");
      } else {
        setError(err instanceof Error ? err.message : "An unexpected error occurred.");
      }
    } finally {
      setGenerating(false);
    }
  }

  if (loading) {
    return <div className="tc-plugin" style={{ padding: "1rem" }}>Loading...</div>;
  }

  return (
    <div className="tc-plugin" style={{ padding: "1.5rem" }}>
      <h3 style={{ margin: "0 0 1rem" }}>AI Description</h3>

      {error && <p className="tc-error">{error}</p>}

      {description && (
        <div className="tc-card" style={{ padding: "1rem", marginBottom: "1rem" }}>
          <h4 style={{ margin: "0 0 0.5rem" }}>Recommendation</h4>
          <p style={{ margin: "0 0 1rem" }}>{description.recommendation}</p>

          <h4 style={{ margin: "0 0 0.5rem" }}>Target Customer</h4>
          <p style={{ margin: "0 0 1rem" }}>{description.targetCustomer}</p>

          <h4 style={{ margin: "0 0 0.5rem" }}>Pros</h4>
          <ul style={{ margin: "0 0 1rem", paddingLeft: "1.25rem" }}>
            {description.pros.map((pro, i) => (
              <li key={i}>{pro}</li>
            ))}
          </ul>

          <h4 style={{ margin: "0 0 0.5rem" }}>Cons</h4>
          <ul style={{ margin: "0", paddingLeft: "1.25rem" }}>
            {description.cons.map((con, i) => (
              <li key={i}>{con}</li>
            ))}
          </ul>
        </div>
      )}

      {canEdit && (
        <>
          <div style={{ marginBottom: "1rem" }}>
            <label>
              <span style={{ display: "block", marginBottom: "0.25rem", fontSize: "13px", fontWeight: 500 }}>
                Custom Information (optional)
              </span>
              <textarea
                className="tc-input"
                rows={3}
                value={customInformation}
                onChange={(e) => setCustomInformation(e.target.value)}
                placeholder="Add any additional context for the AI to consider..."
                style={{ width: "100%", resize: "vertical" }}
              />
            </label>
          </div>

          <button
            className="tc-primary-button"
            onClick={() => void handleGenerate()}
            disabled={generating}
          >
            {generating ? "Generating..." : description ? "Regenerate" : "Generate"}
          </button>
        </>
      )}
    </div>
  );
}
