import { prisma } from "../../../infra/db/prisma";
import { ensureOrg } from "../../../infra/db/scoping";

export type ListInspectionHistoryInput = {
  assetId: string;
};

export type InspectionHistoryItem = {
  id: string;
  inspection_date: string | Date;
  inspector_name: string;
  comment?: string | null;
  intervalOptionId_at_time: string;
  recorded_at: Date;
  documentId?: string | null;
};

export async function listInspectionHistory(
  ctx: { organisationId: string | null },
  input: ListInspectionHistoryInput,
): Promise<{ data: InspectionHistoryItem[] }> {
  if (!input.assetId) {
    throw new Error("Missing required field: assetId");
  }

  const organisationId = ensureOrg(ctx);

  const asset = await prisma.asset.findFirst({
    where: {
      id: input.assetId,
      organisationId,
    },
    select: { id: true },
  });

  if (!asset) {
    throw new Error("Asset not found");
  }

  const inspections = await prisma.inspectionRecord.findMany({
    where: {
      assetId: input.assetId,
      organisationId,
    },
    orderBy: {
      inspection_date: "desc",
    },
    select: {
      id: true,
      inspection_date: true,
      inspector_name: true,
      comment: true,
      intervalOptionId_at_time: true,
      recorded_at: true,
      documentId: true,
    },
  });

  return { data: inspections };
}
