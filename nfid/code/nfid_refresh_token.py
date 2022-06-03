import json
import logging
import os
import requests
import boto3
import jwt
import uuid
import hashlib

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.client("dynamodb")


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
        salt = os.environ.get("ID_SECRET")

        token = json.loads(event["body"])["token"]

        decoded_token = jwt.decode(token, jwt_secret, algorithms="HS256")

        print(decoded_token)

        # verify valid token here

        id = decoded_token["id"]

        user_details = dynamodb.get_item(TableName=table_name, Key={"id": {"S": id}})
        refresh_token = user_details.get("Item", {}).get("refresh_token", "")

        auth_response = requests.post(
            "https://api.coinbase.com/oauth/token",
            params={
                "grant_type": "refresh_token",
                "client_id": client_id,
                "client_secret": client_secret,
                "refresh_token": refresh_token,
                "redirect_uri": redirect_uri,
            },
        )

        auth_json = auth_response.json()

        access_token = auth_json["access_token"]
        refresh_token = auth_json["refresh_token"]
        created_at = auth_json["created_at"]
        expires_in = auth_json["expires_in"]

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

        hashed_uid = hashlib.sha512((name + email + salt).encode("utf-8")).hexdigest()

        encoded_jwt = jwt.encode(
            {
                "id": hashed_uid,
                "name": name,
                "email": email,
                "access_token": access_token,
                "created_at": created_at,
                "expires_in": expires_in,
            },
            jwt_secret,
            algorithm="HS256",
        )

        user_put = dynamodb.put_item(
            TableName=table_name,
            Item={
                "id": {"S": hashed_uid},
                "cid": {"S": uid},
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
