export const GLOBAL_MODELS = ["ObjectClass", "IntervalOption"] as const;

export const TENANT_MODELS = [
  "Organisation",
  "Location",
  "ResponsibleRole",
  "User",
  "OrganisationObjectClass",
  "Asset",
  "InspectionRecord",
  "Document",
  "AuditLog",
] as const;

export function ensureOrg(ctx: { organisationId?: string | null }): string {
  const organisationId = ctx.organisationId;

  if (!organisationId || organisationId.trim() === "") {
    throw new Error("Missing organisationId");
  }

  return organisationId;
}

export function scopedWhere<TWhere extends Record<string, any>>(
  ctx: { organisationId?: string | null },
  where: TWhere,
): TWhere & { organisationId: string } {
  const organisationId = ensureOrg(ctx);

  if (
    "organisationId" in where &&
    where.organisationId != null &&
    where.organisationId !== organisationId
  ) {
    throw new Error("organisationId mismatch");
  }

  return {
    ...where,
    organisationId,
  };
}

export function scopedUniqueWhere(
  ctx: { organisationId?: string | null },
  id: string,
  extraWhere: Record<string, any> = {},
): { id: string; organisationId: string } & Record<string, any> {
  const organisationId = ensureOrg(ctx);

  return {
    ...extraWhere,
    id,
    organisationId,
  };
}
