// This function creates a new access code in our main AccessCodes table.

const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  PutCommand,
} = require("@aws-sdk/lib-dynamodb");

const TABLE_NAME = process.env.TABLE_NAME;
const baseClient = new DynamoDBClient({});
const dbDocClient = DynamoDBDocumentClient.from(baseClient);

exports.handler = async (event) => {
  console.log("Received event:", JSON.stringify(event, null, 2));

  let requestBody;
  try {
    requestBody = JSON.parse(event.body);
  } catch (e) {
    return formatResponse(400, {
      message: "Invalid request body",
    });
  }

  const { accessCode, userName, role } = requestBody;

  if (!accessCode || !userName || !role) {
    return formatResponse(400, {
      message: "Missing required fields: accessCode, userName, and role are required.",
    });
  }

  // We can add expiration timestamps later if we want
  const params = {
    TableName: TABLE_NAME,
    Item: {
      accessCode: accessCode,
      userName: userName,
      role: role,
      createdAt: new Date().toISOString(),
    },
  };

  try {
    console.log(`Attempting to create code: ${accessCode}`);
    await dbDocClient.send(new PutCommand(params));

    console.log(`Successfully created code: ${accessCode}`);
    return formatResponse(201, {
      message: "Access code created successfully",
      item: params.Item,
    });
  } catch (error) {
    console.error("Error creating code in DynamoDB:", error);
    return formatResponse(500, {
      message: "Internal server error",
      error: error.message,
    });
  }
};

function formatResponse(statusCode, body) {
  return {
    statusCode: statusCode,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  };
}