import json
import logging
import requests
import os
import boto3
import jwt

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

    dynamodb = boto3.client("dynamodb")

    try:
        client_id = os.environ.get("CLIENT_ID")
        client_secret = os.environ.get("CLIENT_SECRET")
        redirect_uri = os.environ.get("REDIRECT_URI")
        jwt_secret = os.environ.get("JWT_SECRET")

        code = json.loads(event["body"])["code"]

        auth_response = requests.post(
            "https://api.coinbase.com/oauth/token",
            params={
                "grant_type": "authorization_code",
                "code": code,
                "client_id": client_id,
                "client_secret": client_secret,
                "redirect_uri": redirect_uri,
            },
        )

        if auth_response.status_code != 200:
            logging.error(auth_response.reason)
            return {
                "statusCode": 401,
                "headers": headers,
                "body": json.dumps("Authorization failed"),
            }

        auth_json = auth_response.json()
        access_token = auth_json["access_token"]
        refresh_token = auth_json["refresh_token"]
        created_at = auth_json["created_at"]
        expires_in = auth_json["expires_in"]

        logging.info(access_token)

        user_response = requests.get(
            url="https://api.coinbase.com/v2/user",
            headers={"Authorization": "Bearer " + access_token},
        )

        if user_response.status_code != 200:
            logging.error(user_response.reason)
            return {
                "statusCode": 500,
                "headers": headers,
                "body": json.dumps("Failed to retrieve use information"),
            }

        user_json = user_response.json()

        user_data = user_json["data"]

        uid = user_data.get("id", "")
        name = user_data.get("name", "")
        email = user_data.get("name", "")
        
        encoded_jwt = jwt.encode(
            {
                'name': name,
                'email': email,
                'access_token': access_token,
                'refresh_token': refresh_token,
                'created_at': created_at,
                'expires_in': expires_in,
            }, 
            jwt_secret, 
            algorithm='HS256'
        )

        user_details = dynamodb.get_item(TableName="users", Key={"id": {"S": uid}})
        if user_details.get("Item", "") == "":
            user_put = dynamodb.put_item(
                TableName="users",
                Item={
                    "id": {"S": uid},
                    "email": {"S": email},
                    "refresh_token": {"S": auth_json["refresh_token"]},
                },
            )
            if user_put.get("ResponseMetadata", {}).get("HTTPStatusCode", "") != 200:
                return {
                    "statusCode": 500,
                    "headers": headers,
                    "body": json.dumps("User creation failed"),
                }
            logging.info(user_put)

    except Exception as e:
        logging.error(e)
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps("Internal server error"),
        }

    return {
        "statusCode": 200,
        "headers": headers,
        "body": json.dumps({"token": encoded_jwt}),
    }
