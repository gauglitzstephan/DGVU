type ComputeStatusInput = {
  is_active: boolean;
  last_inspection_date: string | null;
  intervalMonths: number;
  today: string;
};

type AssetStatus = "GREEN" | "YELLOW" | "RED" | "INACTIVE";

type ComputeStatusResult = {
  status: AssetStatus;
  next_due_date: string | null;
  days_remaining: number | null;
};

function parseDateString(dateString: string): { year: number; month: number; day: number } {
  const parts = dateString.split("-");
  if (parts.length !== 3) {
    throw new Error("Invalid date format");
  }

  const year = Number(parts[0]);
  const month = Number(parts[1]);
  const day = Number(parts[2]);

  if (!Number.isInteger(year) || !Number.isInteger(month) || !Number.isInteger(day)) {
    throw new Error("Invalid date format");
  }

  if (month < 1 || month > 12) {
    throw new Error("Invalid date format");
  }

  const dim = daysInMonth(year, month);
  if (day < 1 || day > dim) {
    throw new Error("Invalid date format");
  }

  return { year, month, day };
}

function daysInMonth(year: number, month: number): number {
  return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

function formatDateUTC(year: number, month: number, day: number): string {
  const yyyy = String(year).padStart(4, "0");
  const mm = String(month).padStart(2, "0");
  const dd = String(day).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}

function addMonths(dateString: string, months: number): string {
  const { year, month, day } = parseDateString(dateString);

  const zeroBasedMonth = month - 1;
  const totalMonths = year * 12 + zeroBasedMonth + months;
  const targetYear = Math.floor(totalMonths / 12);
  const targetZeroBasedMonth = totalMonths % 12;
  const targetMonth = targetZeroBasedMonth + 1;
  const targetDay = Math.min(day, daysInMonth(targetYear, targetMonth));

  return formatDateUTC(targetYear, targetMonth, targetDay);
}

function toUTCMidnightMs(dateString: string): number {
  const { year, month, day } = parseDateString(dateString);
  return Date.UTC(year, month - 1, day);
}

function daysBetween(dateA: string, dateB: string): number {
  const msPerDay = 24 * 60 * 60 * 1000;
  return Math.floor((toUTCMidnightMs(dateA) - toUTCMidnightMs(dateB)) / msPerDay);
}

export function computeAssetStatus(input: ComputeStatusInput): ComputeStatusResult {
  const { is_active, last_inspection_date, intervalMonths, today } = input;

  if (!is_active) {
    return {
      status: "INACTIVE",
      next_due_date: null,
      days_remaining: null,
    };
  }

  if (intervalMonths <= 0) {
    throw new Error("Invalid intervalMonths");
  }

  if (last_inspection_date === null) {
    return {
      status: "RED",
      next_due_date: null,
      days_remaining: null,
    };
  }

  const next_due_date = addMonths(last_inspection_date, intervalMonths);
  const days_remaining = daysBetween(next_due_date, today);

  let status: AssetStatus;
  if (days_remaining <= 0) {
    status = "RED";
  } else if (days_remaining <= 30) {
    status = "YELLOW";
  } else {
    status = "GREEN";
  }

  return {
    status,
    next_due_date,
    days_remaining,
  };
}
