import { computeAssetStatus } from "../../domain/status/computeStatus";

export type AssetStatusView = {
  status: "GREEN" | "YELLOW" | "RED" | "INACTIVE";
  next_due_date: string | null;
  days_remaining: number | null;
};

export type AssetStatusProjectionInput = {
  is_active: boolean;
  last_inspection_date: string | Date | null;
  intervalMonths: number;
};

function getTodayUtcDateString(): string {
  const now = new Date();
  const yyyy = now.getUTCFullYear();
  const mm = String(now.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(now.getUTCDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}

function normalizeDateField(value: string | Date | null): string | null {
  if (value === null) {
    return null;
  }

  if (typeof value === "string") {
    return value;
  }

  if (value instanceof Date) {
    return value.toISOString().split("T")[0];
  }

  throw new Error("Invalid last_inspection_date type");
}

export function projectAssetStatus(
  asset: { is_active: boolean; last_inspection_date: string | Date | null; intervalMonths: number },
  opts?: { today?: string }
): AssetStatusView {
  const today = opts?.today ?? getTodayUtcDateString();
  const normalized = normalizeDateField(asset.last_inspection_date);

  return computeAssetStatus({
    is_active: asset.is_active,
    last_inspection_date: normalized,
    intervalMonths: asset.intervalMonths,
    today,
  });
}
