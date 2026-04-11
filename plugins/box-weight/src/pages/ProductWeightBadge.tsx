import { useEffect, useState } from "react";
import { getSDK } from "../../../sdk";
import { toBoxWeight, formatWeight } from "../domain";

export function ProductWeightBadge() {
  const [label, setLabel] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const sdk = getSDK();
  const productId = sdk.thisPlugin.productId ?? "";

  useEffect(() => {
    if (!productId) {
      setLoading(false);
      return;
    }

    async function load() {
      try {
        const data = (await sdk.thisPlugin.getData(productId)) as Record<string, unknown> | null;
        const bw = toBoxWeight(data);
        if (bw) setLabel(formatWeight(bw));
      } catch {
        // no data yet
      } finally {
        setLoading(false);
      }
    }
    void load();
  }, [productId]);

  if (loading || !label) return null;

  return <span className="tc-badge tc-badge--success">{label}</span>;
}
