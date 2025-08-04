const fs = require("fs");
const readline = require("readline-sync");
const fetch = require("node-fetch");
const crypto = require("crypto");

process.stdout.write('\x1Bc');

function generateCode() {
  const charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  let code = "CA";
  for (let i = 0; i < 10; i++) {
    const rand = crypto.randomInt(0, charset.length);
    code += charset[rand];
  }
  return code;
}

function generateUniqueCodes(total) {
  const set = new Set();
  while (set.size < total) {
    set.add(generateCode());
  }
  return Array.from(set);
}

async function sendDiscordWebhook(webhookUrl, content, fields) {
  try {
    const embed = {
      title: "VMOS Code Checker",
      description: "Make by konmeo22132 " + new Date().toLocaleString(),
      color: 0x00ff00,
      fields: fields
    };

    const payload = {
      content: content,
      embeds: [embed]
    };

    const response = await fetch(webhookUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      console.error("Webhook Error:", response.statusText);
    } else {
      console.log("Webhook sent.");
    }
  } catch (err) {
    console.error("Webhook Error:", err.message);
  }
}

async function checkCodeWithAPI(code) {
  try {
    const response = await fetch("https://vsvmos.androidmodvip.io.vn/apicheckcode.php", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Origin": "https://vsvmos.androidmodvip.io.vn",
        "Referer": "https://vsvmos.androidmodvip.io.vn/checkcode.php",
        "User-Agent": "Mozilla/5.0"
      },
      body: JSON.stringify({ code: code, type: "vmos" })
    });

    const contentType = response.headers.get('content-type');
    if (!contentType || !contentType.includes("application/json")) {
      const raw = await response.text();
      console.error("API returned non-JSON:", raw.slice(0, 80));
      return false;
    }

    const data = await response.json();
    return data.status === "live";
  } catch (err) {
    console.error("API Error:", err.message);
    return false;
  }
}

async function main() {
  let webhookUrl = "";
  const maxThreads = 20;
  let liveCount = 0;
  let checked = 0;

  const useWebhook = readline.question("Add Discord Webhook? (y/n): ").toLowerCase();
  if (useWebhook === "y") {
    webhookUrl = readline.question("Enter Discord Webhook URL: ");
    await sendDiscordWebhook(webhookUrl, "Konmeo22132 was here!", []);
  }

  const useAPI = readline.question("Use API to check codes? (y/n): ").toLowerCase();
  if (useAPI !== "y") {
    console.log("Exiting...");
    return;
  }

  const numCodes = parseInt(readline.question("Enter number of codes (min 1): "));
  if (isNaN(numCodes) || numCodes < 1) {
    console.log("Invalid number.");
    return;
  }

  const codes = generateUniqueCodes(numCodes);

  for (let i = 0; i < codes.length; i += maxThreads) {
    const batch = codes.slice(i, i + maxThreads);

    await Promise.all(
      batch.map(async (code) => {
        const isValid = await checkCodeWithAPI(code);
        checked++;

        if (isValid) {
          liveCount++;
          console.log(`[${checked}] ${code} - Status: Live`);
          fs.appendFileSync("livecode.txt", `${code}\n`, "utf8");

          if (webhookUrl) {
            await sendDiscordWebhook(
              webhookUrl,
              "@everyone",
              [
                { name: "Code", value: code, inline: true },
                { name: "Status", value: "Live", inline: true },
                { name: "Total", value: String(liveCount), inline: true }
              ]
            );
          }
        } else {
          console.log(`[${checked}] ${code} - Status: Die`);
        }
      })
    );
  }

  console.log(`\nDone! Live codes saved to livecode.txt. Total live code: ${liveCount}`);
}

main();
