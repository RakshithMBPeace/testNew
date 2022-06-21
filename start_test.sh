#!/bin/bash

projectName="$1"
suiteName="$2"
container_name="$3"
report_folder="$4"
azure_storage_account="$5"
azure_storage_key="$6"
slack_webhook_url="$7"
expiry_date=`date -d "30 days" '+%Y-%m-%dT%H:%MZ'`

echo "Cleaning up old reports...\n"
rm -rf allure-report
rm -rf allure-results

echo "Running tests...\n"
./greadlew clean test -Dcucumber.filter.tags=$suiteName

# get the result
echo "Generating allure report...\n"
./allure/allure-2.12.1/bin/allure generate allure-results --clean -o allure-report

time_stamp=`date +"-%Y-%m-%d-%T"`

# get the result
echo "Generating allure report...\n"
./allure/allure-2.12.1/bin/allure generate allure-results --clean -o allure-report

echo "Setting azure environment variables..\n"
export AZURE_STORAGE_ACCOUNT=$azure_storage_account
export AZURE_STORAGE_KEY=$azure_storage_key

echo "Uploading the file...\n"
ls -l ./
az storage blob upload-batch --source allure-report -d $container_name/$report_folder/allure-report${time_stamp}-${suiteName}-${projectName}

echo "Generating shared access url...\n"
report_url=$(az storage blob generate-sas --account-key $azure_storage_key --account-name $azure_storage_account --container-name $container_name --expiry $expiry_date --name $report_folder/allure-report${time_stamp}-${appName}-${groupName}/index.html --permissions r --full-uri)

echo "Report URL:" $report_url

echo "Determining current environment..."

if echo $azure_storage_account | grep -q "dev"; then
env="DEV"
elif echo $azure_storage_account | grep -q "stg"; then
env="STAGE"
elif echo $azure_storage_account | grep -q "preprod"; then
env="PREPROD"
elif echo $azure_storage_account | grep -q "prod"; then
env="PROD"
else
echo "Unable to determine environment..."
env="novalue"
fi

echo "Current environment:" $env

echo "Sending Slack message...\n"
curl -X POST -H 'Content-type: application/json' -d '{"username": "'${env}'", API test report URL:'$(echo $report_url | sed s/\"//g)'"}' $slack_webhook_url

echo "Running clean up step...\n"

unset DB_USER_NAME
unset DB_PASSWORD
unset NIFI_AZURE_STORAGE_ACCOUNT
unset NIFI_AZURE_STORAGE_KEY
unset REPORTS_AZURE_STORAGE_ACCOUNT
unset REPORTS_AZURE_STORAGE_KEY
unset AZURE_STORAGE_ACCOUNT
unset AZURE_STORAGE_KEY
unset SNOWFLAKE_PRIVATE_KEY
unset SNOWFLAKE_USER

echo "Exiting..."





