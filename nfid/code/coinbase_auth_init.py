import os
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):

    logging.info(event)

    try:

        # --- PARAMS ---
        baseUrl = 'https://coinbase.com'
        authorizePath = '/oauth/authorize'
        coinbase_client_id = os.environ.get("COINBASE_CLIENT_ID")
        state = os.urandom(20).hex()
        scope = 'wallet:addresses:read,wallet:user:read,wallet:withdrawals:read,wallet:user:email'
        '''
        response_type=code
        client_id=${client_id}
        redirect_uri=${redirect_uri}  // OPTIONAL
        state=${state}
        scope=${scope}
        
        authorizationUrl = "{}{}?response_type=code&client_id={}&redirect_uri={}&state={}&scope={}".format(baseUrl,authorizePath,client_id,redirect_uri,state,scope)

        '''
        authorizationUrl = "{}{}?response_type=code&client_id={}&state={}&scope={}".format(
            baseUrl,        # URI base
            authorizePath,  # URI extension
            coinbase_client_id,      # Coinbase Client ID
            state,          # Random string
            scope           # Request scope for reading user information
        )
    except Exception as e:
        logging.error(e)
        return {"statusCode": 500, "body": json.dumps("Internal server error")}


    return {
        'statusCode': 302,
        'headers': {
            'Location': authorizationUrl
        },
        'body': json.dumps('Initiate Coinbase OAuth login.')
    }
