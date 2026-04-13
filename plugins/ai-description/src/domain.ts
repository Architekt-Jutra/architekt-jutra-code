import type { PluginObject } from "../../sdk";

export interface ProductDescription {
  objectId: string;
  recommendation: string;
  targetCustomer: string;
  pros: string[];
  cons: string[];
  customInformation?: string;
}

export function toProductDescription(obj: PluginObject): ProductDescription {
  return {
    objectId: obj.objectId,
    recommendation: obj.data.recommendation as string,
    targetCustomer: obj.data.targetCustomer as string,
    pros: (obj.data.pros as string[]) ?? [],
    cons: (obj.data.cons as string[]) ?? [],
    customInformation: obj.data.customInformation as string | undefined,
  };
}
