import { prisma } from "../../../infra/db/prisma";
import { ensureOrg } from "../../../infra/db/scoping";
import { projectAssetStatus } from "../../projections/assetStatus";
import type { AssetStatusView } from "../../projections/assetStatus";

export type ListAssetsWithStatusInput = {
  is_active?: boolean;
  today?: string; // optional YYYY-MM-DD for deterministic tests
};

export type AssetWithStatusView = {
  id: string;
  organisationId: string;
  name: string;
  is_active: boolean;
  last_inspection_date: string | Date | null;
  objectClassId: string;
  intervalOptionId: string;
  locationId?: string | null;
  responsibleRoleId?: string | null;
  inventoryNumber?: string | null;
  serialNumber?: string | null;
  description?: string | null;
  statusView: AssetStatusView;
};

export async function listAssetsWithStatus(
  ctx: { organisationId: string | null },
  input: ListAssetsWithStatusInput = {},
): Promise<{ data: AssetWithStatusView[] }> {
  const organisationId = ensureOrg(ctx);

  const where: any = { organisationId };

  if (typeof input.is_active === "boolean") {
    where.is_active = input.is_active;
  }

  const assets = await prisma.asset.findMany({
    where,
    include: { intervalOption: true },
    orderBy: { name: "asc" },
  });

  const mappedAssets: AssetWithStatusView[] = assets.map((asset) => {
    if (!asset.intervalOption) {
      throw new Error("Missing intervalOption for asset");
    }

    const intervalMonths = asset.intervalOption.months;

    const statusView = projectAssetStatus(
      {
        is_active: asset.is_active,
        last_inspection_date: asset.last_inspection_date,
        intervalMonths,
      },
      input.today ? { today: input.today } : undefined,
    );

    return {
      id: asset.id,
      organisationId: asset.organisationId,
      name: asset.name,
      is_active: asset.is_active,
      last_inspection_date: asset.last_inspection_date,
      objectClassId: asset.objectClassId,
      intervalOptionId: asset.intervalOptionId,
      locationId: asset.locationId,
      responsibleRoleId: asset.responsibleRoleId,
      inventoryNumber: asset.inventoryNumber,
      serialNumber: asset.serialNumber,
      description: asset.description,
      statusView,
    };
  });

  return { data: mappedAssets };
}
