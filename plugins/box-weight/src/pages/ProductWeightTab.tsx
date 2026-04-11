import { useEffect, useState } from "react";
import { getSDK } from "../../../sdk";
import { toBoxWeight } from "../domain";
import type { BoxWeight } from "../domain";

export function ProductWeightTab() {
  const sdk = getSDK();
  const productId = sdk.thisPlugin.productId ?? "";

  const [weight, setWeight] = useState("");
  const [unit, setUnit] = useState<"kg" | "g">("kg");
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!productId) {
      setLoading(false);
      return;
    }

    async function load() {
      try {
        const data = (await sdk.thisPlugin.getData(productId)) as Record<string, unknown> | null;
        const bw = toBoxWeight(data);
        if (bw) {
          setWeight(String(bw.weight));
          setUnit(bw.unit);
        }
      } catch {
        // no data yet
      } finally {
        setLoading(false);
      }
    }
    void load();
  }, [productId]);

  async function handleSave() {
    setError(null);
    const w = parseFloat(weight);
    if (isNaN(w) || w <= 0) {
      setError("Weight must be a positive number.");
      return;
    }

    setSaving(true);
    try {
      const data: BoxWeight = { weight: w, unit };
      await sdk.thisPlugin.setData(productId, data as unknown as Record<string, unknown>);
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save weight.");
    } finally {
      setSaving(false);
    }
  }

  async function handleRemove() {
    setSaving(true);
    setError(null);
    try {
      await sdk.thisPlugin.removeData(productId);
      setWeight("");
      setUnit("kg");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to remove weight.");
    } finally {
      setSaving(false);
    }
  }

  if (loading) return <div className="tc-plugin" style={{ padding: "1rem" }}>Loading...</div>;

  const labelStyle: React.CSSProperties = { display: "flex", alignItems: "center", gap: "0.75rem" };
  const labelTextStyle: React.CSSProperties = { width: 60, fontSize: "13px", fontWeight: 500, color: "#334155" };
  const inputStyle: React.CSSProperties = { width: 120 };

  return (
    <div className="tc-plugin" style={{ padding: "1.5rem" }}>
      <h3 style={{ margin: "0 0 1rem" }}>Box Weight</h3>
      <div style={{ display: "flex", flexDirection: "column", gap: "0.625rem" }}>
        <label style={labelStyle}>
          <span style={labelTextStyle}>Weight</span>
          <input className="tc-input" type="number" min="0" step="any" value={weight} onChange={(e) => setWeight(e.target.value)} style={inputStyle} />
          <select className="tc-select" value={unit} onChange={(e) => setUnit(e.target.value as "kg" | "g")} style={{ width: 70 }}>
            <option value="kg">kg</option>
            <option value="g">g</option>
          </select>
        </label>
      </div>
      {error && <p className="tc-error">{error}</p>}
      <div className="tc-flex" style={{ marginTop: "1rem" }}>
        <button className="tc-primary-button" onClick={handleSave} disabled={saving}>
          {saved ? "Saved!" : "Save"}
        </button>
        <button className="tc-ghost-button tc-ghost-button--danger" onClick={handleRemove} disabled={saving}>
          Remove
        </button>
      </div>
    </div>
  );
}
