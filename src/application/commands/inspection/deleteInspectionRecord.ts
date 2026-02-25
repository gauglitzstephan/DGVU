import { AuditActionType, Prisma, type InspectionRecord } from "@prisma/client";

import type { Command } from "../command";
import { runInTransaction } from "../../../infra/db/transaction";
import { ensureOrg } from "../../../infra/db/scoping";

type DeleteInspectionRecordInput = {
  inspectionRecordId: string;
  reason?: string;
};

export const deleteInspectionRecordCommand: Command<
  DeleteInspectionRecordInput,
  InspectionRecord
> = async (ctx, input) => {
  if (!input.inspectionRecordId) {
    throw new Error("Missing required field: inspectionRecordId");
  }

  if (!ctx.actorUserId) {
    throw new Error("Missing actorUserId");
  }

  const organisationId = ensureOrg(ctx);

  return runInTransaction(async (tx) => {
    const deletedSnapshot = await tx.inspectionRecord.findFirst({
      where: {
        id: input.inspectionRecordId,
        organisationId,
      },
    });

    if (!deletedSnapshot) {
      throw new Error("InspectionRecord not found for organisation");
    }

    await tx.inspectionRecord.delete({
      where: {
        id: input.inspectionRecordId,
      },
    });

    const agg = await tx.inspectionRecord.aggregate({
      where: {
        assetId: deletedSnapshot.assetId,
        organisationId,
      },
      _max: {
        inspection_date: true,
      },
    });

    await tx.asset.update({
      where: {
        id: deletedSnapshot.assetId,
        organisationId,
      },
      data: {
        last_inspection_date: agg._max.inspection_date,
      },
    });

    const payloadSnapshot = JSON.parse(JSON.stringify(deletedSnapshot));
    const payload: Prisma.JsonObject = {
      deleted_record: payloadSnapshot,
    };

    if (typeof input.reason !== "undefined") {
      payload.reason = input.reason;
    }

    await tx.auditLog.create({
      data: {
        organisationId,
        actor_user_id: ctx.actorUserId,
        action_type: AuditActionType.DELETE_INSPECTION_RECORD,
        target_entity_type: "INSPECTION_RECORD",
        target_entity_id: deletedSnapshot.id,
        payload_json: payload,
      },
    });

    return { data: deletedSnapshot };
  });
};
