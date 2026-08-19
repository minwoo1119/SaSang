import { describe, expect, it } from "vitest";

import { CreateVisitSchema } from "./visit.schema";

describe("CreateVisitSchema", () => {
  it("accepts a stable region code", () => {
    expect(CreateVisitSchema.parse({ regionCode: "11680" })).toEqual({
      regionCode: "11680",
    });
  });

  it("rejects an empty region code", () => {
    expect(() => CreateVisitSchema.parse({ regionCode: "" })).toThrow();
  });
});
