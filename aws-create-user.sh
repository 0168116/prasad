#!/bin/bash

while getopts ":u:s:c:p:e:" opt; do
  case ${opt} in
    u) USERNAME="$OPTARG"
    ;;
    s) SECRET="$OPTARG"
    ;;
    c) EMAIL="$OPTARG"
    ;;
    p) PROFILE="$OPTARG"
    ;;
    e) ENVIRONMENT="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

echo "Environment: $ENVIRONMENT"
echo "Username: $USERNAME"
echo "Email: $EMAIL"
echo "Profile: $PROFILE"

description=$(aws cloudformation describe-stacks \
                            --profile $PROFILE \
                            --stack-name a204121-ecpmetaapi-ecpmeta-$ENVIRONMENT)
HOST_URI=$(echo $description |
        grep -Eo "\"OutputValue\":\s(.*)" | grep -Eo '"(https:[^ ]*?)\"' | sed 's/"//g')
COGNITO_CLIENT_ID=$(aws cloudformation describe-stacks --region us-east-1 --stack-name  a204121-ecpmetaapi-ecpmeta-$ENVIRONMENT \
                --query 'Stacks[0].Outputs[?OutputKey==`CognitoPoolClient`].OutputValue' --profile ${PROFILE} --output text)
COGNITO_POOL=$(echo $(aws cloudformation describe-stacks --region us-east-1 --stack-name  a204121-ecpmetaapi-ecpmeta-$ENVIRONMENT \
                --query 'Stacks[0].Outputs[?OutputKey==`PoolProviderName`].OutputValue' --profile ${PROFILE} --output text) | grep -Eo '/([a-z|A-Z|0-9|_|\-]*)' | sed 's|/||g')
JSON="[{\"Name\":\"given_name\",\"Value\":\"$USERNAME\"},{\"Name\":\"family_name\",\"Value\":\"$USERNAME\"},{\"Name\":\"email\",\"Value\":\"$EMAIL\"}]"
echo $JSON

echo "Client ID: $COGNITO_CLIENT_ID"
echo "POOL: $COGNITO_POOL"

echo "aws cognito-idp sign-up  --client-id ${COGNITO_CLIENT_ID} --username $USERNAME --password $SECRET --region us-east-1 --user-attributes $JSON"

aws cognito-idp sign-up \
    --client-id ${COGNITO_CLIENT_ID} \
    --username $USERNAME \
    --password $SECRET \
    --region us-east-1 \
    --user-attributes $JSON

aws cognito-idp admin-confirm-sign-up \
        --user-pool-id ${COGNITO_POOL} \
        --username $USERNAME \
        --profile $PROFILE
