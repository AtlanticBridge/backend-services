import json
import logging
import os
import requests

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):

    headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "OPTIONS, POST",
        "Access-Control-Allow-Credentials": True,
        "Access-Control-Allow-Headers": "x-api-key,Content-Type,DNT,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,Accept,Origin,Referer",
    }

    if event["httpMethod"] == "OPTIONS":
        return {"statusCode": 200, "headers": headers, "body": json.dumps("Success")}

    logging.info(event)

    try:
        client_id = os.environ.get("CLIENT_ID")
        client_secret = os.environ.get("CLIENT_SECRET")
        redirect_uri = os.environ.get("REDIRECT_URI")
        jwt_secret = os.environ.get("JWT_SECRET")
        table_name = os.environ.get("TABLE_NAME")

        token = json.loads(event["body"])["token"]

        auth_response = requests.post(
            "https://api.coinbase.com/oauth/token",
            params={
                "grant_type": "refresh_token",
                "client_id": client_id,
                "client_secret": client_secret,
                "refresh_token": refresh_token,
            },
        )

    except Exception as e:
        logging.error(e)
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps("Internal server error"),
        }


