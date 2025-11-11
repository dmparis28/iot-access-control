/**
 * This is the "AuthorizeAccess" Lambda function.
 *
 * It now includes logic to write an audit log for every
 * access attempt to a separate DynamoDB table.
 */

const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
// --- UPDATED IMPORTS ---
const {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand, // Import PutCommand
} = require("@aws-sdk/lib-dynamodb");
const { v4: uuidv4 } = require("uuid"); // Import the uuid library
// --- END UPDATED IMPORTS ---

// Get environment variables
const TABLE_NAME = process.env.TABLE_NAME;
const LOGS_TABLE_NAME = process.env.LOGS_TABLE_NAME; // New logs table

const baseClient = new DynamoDBClient({});
const dbDocClient = DynamoDBDocumentClient.from(baseClient);

/**
 * Main Lambda Handler
 */
exports.handler = async (event) => {
  console.log("Received event:", JSON.stringify(event, null, 2));

  let requestBody;
  let accessCode = "unknown";
  let hardwareId = "unknown";

  try {
    requestBody = JSON.parse(event.body);
    // Get hardwareId and accessCode for logging, even if one is missing
    accessCode = requestBody.accessCode || "missing";
    hardwareId = requestBody.hardwareId || "missing";
  } catch (e) {
    console.error("Failed to parse request body:", e);
    // Log the bad request
    await logAccessAttempt(hardwareId, accessCode, "ERROR_400");
    return formatResponse(400, {
      status: "ERROR",
      message: "Invalid request body",
    });
  }

  if (!requestBody.accessCode || !requestBody.hardwareId) {
    await logAccessAttempt(hardwareId, accessCode, "ERROR_400");
    return formatResponse(400, {
      status: "ERROR",
      message: "Missing accessCode or hardwareId",
    });
  }

  const params = {
    TableName: TABLE_NAME,
    Key: {
      accessCode: accessCode,
    },
  };

  try {
    // 1. Query the AccessCodes table
    console.log(`Checking for code: ${accessCode}`);
    const { Item } = await dbDocClient.send(new GetCommand(params));

    // 2. Check if the item was found
    if (Item) {
      const foundItem = Item;
      console.log(`SUCCESS: Code ${accessCode} found. Item:`, foundItem);

      // Check for expiration
      if (foundItem.expirationTimestamp) {
        const currentTime = Math.floor(Date.now() / 1000);
        if (currentTime > foundItem.expirationTimestamp) {
          console.warn(`DENIED: Code ${accessCode} is EXPIRED.`);
          // Log the "EXPIRED" attempt
          await logAccessAttempt(hardwareId, accessCode, "EXPIRED");
          return formatResponse(403, { status: "EXPIRED" });
        }
      }

      // If here, the code is valid and not expired.
      // Log the "OPEN" event
      await logAccessAttempt(hardwareId, accessCode, "OPEN");
      return formatResponse(200, { status: "OPEN" });
    } else {
      // Item does not exist.
      console.warn(`DENIED: Code ${accessCode} not found.`);
      // Log the "DENIED" attempt
      await logAccessAttempt(hardwareId, accessCode, "DENIED");
      return formatResponse(401, { status: "DENIED" });
    }
  } catch (error) {
    console.error("Error communicating with DynamoDB:", error);
    // Log the internal server error
    await logAccessAttempt(hardwareId, accessCode, "ERROR_500");
    // Return the full error for debugging (as we did before)
    return formatResponse(500, {
      status: "ERROR",
      message: "Internal server error",
      errorMessage: error.message,
      errorName: error.name,
    });
  }
};

/**
 * Helper function to format the response for API Gateway.
 */
function formatResponse(statusCode, body) {
  return {
    statusCode: statusCode,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  };
}

/**
 * --- NEW LOGGING FUNCTION ---
 * Writes a log entry to the AccessLogs table.
 * We wrap this in its own try/catch so that a logging
 * failure *never* stops the main function from returning.
 */
async function logAccessAttempt(hardwareId, accessCodeUsed, result) {
  try {
    const logId = uuidv4();
    const timestamp = new Date().toISOString();

    const params = {
      TableName: LOGS_TABLE_NAME,
      Item: {
        logId: logId,
        timestamp: timestamp,
        hardwareId: hardwareId,
        accessCodeUsed: accessCodeUsed,
        result: result, // e.g., "OPEN", "DENIED", "EXPIRED", "ERROR_400"
      },
    };

    console.log(`Logging access attempt: ${result} for ${hardwareId}`);
    await dbDocClient.send(new PutCommand(params));
  } catch (logError) {
    // If logging fails, just print the error and continue.
    // The main function must always succeed.
    console.error("CRITICAL: Failed to write to logs table:", logError);
  }
}