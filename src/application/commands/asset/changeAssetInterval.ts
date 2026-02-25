import { AuditActionType, Prisma, type Asset } from "@prisma/client";

import type { Command } from "../command";
import { runInTransaction } from "../../../infra/db/transaction";
import { ensureOrg, scopedUniqueWhere } from "../../../infra/db/scoping";

type ChangeAssetIntervalInput = {
  assetId: string;
  intervalOptionId: string;
};

export const changeAssetIntervalCommand: Command<ChangeAssetIntervalInput, Asset> = async (
  ctx,
  input,
) => {
  if (!input.assetId) {
    throw new Error("Missing required field: assetId");
  }

  if (!input.intervalOptionId) {
    throw new Error("Missing required field: intervalOptionId");
  }

  if (!ctx.actorUserId) {
    throw new Error("Missing actorUserId");
  }

  const organisationId = ensureOrg(ctx);

  return runInTransaction(async (tx) => {
    let updatedAsset: Asset;

    try {
      updatedAsset = await tx.asset.update({
        where: scopedUniqueWhere(ctx, input.assetId),
        data: {
          intervalOptionId: input.intervalOptionId,
        },
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2025") {
        throw new Error("Asset not found for organisation");
      }

      throw error;
    }

    const payloadSnapshot = JSON.parse(JSON.stringify(updatedAsset));

    await tx.auditLog.create({
      data: {
        organisationId,
        actor_user_id: ctx.actorUserId,
        action_type: AuditActionType.CHANGE_ASSET_INTERVAL,
        target_entity_type: "Asset",
        target_entity_id: updatedAsset.id,
        payload_json: payloadSnapshot,
      },
    });

    return { data: updatedAsset };
  });
};
