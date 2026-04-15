import type { PluginObject } from "../../../sdk";
import { toProductDescription } from "../domain";

describe("toProductDescription", () => {
  test("maps_fullPluginObject_returnsAllFields", () => {
    const obj: PluginObject = {
      id: "abc-123",
      pluginId: "ai-description",
      objectType: "description",
      objectId: "42",
      data: {
        recommendation: "Great for outdoor use",
        targetCustomer: "Hikers and campers",
        pros: ["Durable", "Lightweight"],
        cons: ["Expensive"],
        customInformation: "Waterproof rating: IPX7",
      },
      entityType: "PRODUCT",
      entityId: "42",
    };

    const result = toProductDescription(obj);

    expect(result).toEqual({
      objectId: "42",
      recommendation: "Great for outdoor use",
      targetCustomer: "Hikers and campers",
      pros: ["Durable", "Lightweight"],
      cons: ["Expensive"],
      customInformation: "Waterproof rating: IPX7",
    });
  });

  test("maps_missingOptionalFields_returnsEmptyArraysAndNoCustomInfo", () => {
    const obj: PluginObject = {
      id: "def-456",
      pluginId: "ai-description",
      objectType: "description",
      objectId: "99",
      data: {
        recommendation: "Budget friendly option",
        targetCustomer: "Students",
      },
    };

    const result = toProductDescription(obj);

    expect(result).toEqual({
      objectId: "99",
      recommendation: "Budget friendly option",
      targetCustomer: "Students",
      pros: [],
      cons: [],
    });
    expect(result.customInformation).toBeUndefined();
  });
});
