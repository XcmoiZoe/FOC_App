import { randomInt } from "crypto";
import { NextRequest, NextResponse } from "next/server";
import mysql from "mysql2/promise";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const codeColumn = process.env.USER_CODE_COLUMN ?? "code";
const allowedCodeColumns = new Set(["code", "login_code"]);

function jsonResponse(body: unknown, status = 200) {
  return NextResponse.json(body, { status });
}

function requireEnv(name: string) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing environment variable: ${name}`);
  }
  return value;
}

async function getConnection() {
  return mysql.createConnection({
    host: requireEnv("DB_HOST"),
    port: Number(process.env.DB_PORT ?? 3306),
    user: requireEnv("DB_USER"),
    password: requireEnv("DB_PASSWORD"),
    database: requireEnv("DB_NAME"),
  });
}

async function sendMoviderSms(phone: string, otp: string) {
  const apiUrl = process.env.MOVIDER_SMS_URL ?? "https://api.movider.co/v1/sms";
  const sender = process.env.MOVIDER_SENDER ?? "FREEWIFI";
  const apiKey = requireEnv("MOVIDER_API_KEY");
  const apiSecret = process.env.MOVIDER_API_SECRET;

  const message = `Your YES! Rewards login code is ${otp}.`;
  const body: Record<string, string> = {
    to: phone,
    from: sender,
    text: message,
    api_key: apiKey,
  };

  if (apiSecret) {
    body.api_secret = apiSecret;
  }

  const response = await fetch(apiUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Movider SMS failed (${response.status}): ${errorText}`);
  }
}

export async function POST(request: NextRequest) {
  if (!allowedCodeColumns.has(codeColumn)) {
    return jsonResponse(
      {
        success: false,
        message: "Invalid USER_CODE_COLUMN. Use code or login_code.",
      },
      500,
    );
  }

  try {
    const body = await request.json();
    const phone = body?.phone?.toString().trim();

    if (!phone) {
      return jsonResponse(
        {
          success: false,
          message: "Phone number is required",
        },
        400,
      );
    }

    const otp = randomInt(100000, 1000000).toString();
    const db = await getConnection();

    try {
      const [users] = await db.execute<mysql.RowDataPacket[]>(
        "SELECT id, member_code FROM users WHERE phone = ? LIMIT 1",
        [phone],
      );

      if (users.length === 0) {
        return jsonResponse(
          {
            success: false,
            message: "Phone number not found",
          },
          404,
        );
      }

      await sendMoviderSms(phone, otp);

      await db.execute(`UPDATE users SET ${codeColumn} = ? WHERE id = ?`, [
        otp,
        users[0].id,
      ]);

      return jsonResponse({
        success: true,
        message: "OTP sent successfully",
        member_code: users[0].member_code,
      });
    } finally {
      await db.end();
    }
  } catch (error) {
    console.error("forgot-password error:", error);

    return jsonResponse(
      {
        success: false,
        message: "Unable to send OTP",
      },
      500,
    );
  }
}
