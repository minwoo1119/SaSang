import { NextResponse } from "next/server";
import { getHealthStatus } from "@/modules/health/health.service";
export function GET() {
  return NextResponse.json(getHealthStatus());
}
