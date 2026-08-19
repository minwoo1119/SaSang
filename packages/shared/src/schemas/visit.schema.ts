import { z } from "zod";
export const CreateVisitSchema = z.object({
  regionCode: z.string().min(1),
  visitedAt: z.iso.datetime().optional(),
  memo: z.string().max(2000).optional(),
});
export type CreateVisitInput = z.infer<typeof CreateVisitSchema>;
