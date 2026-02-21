import { NextResponse } from "next/server";

import { getDepositStatus } from "@/lib/daimo";

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const sessionId = searchParams.get("sessionId");

  if (!sessionId || !/^[0-9a-f]{32}$/.test(sessionId)) {
    return NextResponse.json(
      { error: "sessionId required (32-char hex)" },
      { status: 400 }
    );
  }

  try {
    const status = await getDepositStatus(sessionId);
    return NextResponse.json(status);
  } catch (err) {
    const message = err instanceof Error ? err.message : "unknown error";
    return NextResponse.json({ error: message }, { status: 502 });
  }
}
