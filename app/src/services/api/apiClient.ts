const API_URL = process.env.EXPO_PUBLIC_API_URL ?? "http://localhost:3000";
export class ApiError extends Error {
  constructor(
    message: string,
    readonly status: number,
  ) {
    super(message);
    this.name = "ApiError";
  }
}
export async function apiRequest<T>(
  path: string,
  init?: RequestInit,
): Promise<T> {
  const response = await fetch(`${API_URL}${path}`, {
    ...init,
    headers: { "Content-Type": "application/json", ...init?.headers },
  });
  if (!response.ok)
    throw new ApiError("요청을 처리하지 못했습니다.", response.status);
  return (await response.json()) as T;
}
