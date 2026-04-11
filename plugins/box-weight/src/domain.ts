export interface BoxWeight {
  weight: number;
  unit: "kg" | "g";
}

export function toBoxWeight(data: Record<string, unknown> | null): BoxWeight | null {
  if (!data || data.weight == null || data.unit == null) return null;
  return {
    weight: data.weight as number,
    unit: data.unit as "kg" | "g",
  };
}

export function formatWeight(bw: BoxWeight): string {
  return `Weight: ${bw.weight} ${bw.unit}`;
}
