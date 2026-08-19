import type { HealthResponse } from "@sasang/shared";
export function getHealthStatus(): HealthResponse {
  return {
    service: "sasang-backend",
    status: "ok",
    timestamp: new Date().toISOString(),
  };
}
