import { describe, expect, it } from "vitest";
import { getHealthStatus } from "./health.service";
describe("getHealthStatus", () => {
  it("uses the canonical service name", () => {
    expect(getHealthStatus()).toMatchObject({
      service: "sasang-backend",
      status: "ok",
    });
  });
});
