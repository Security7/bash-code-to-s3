#!/bin/bash

#     _____  ______  _______  _______  _____  _   _   _____   _____
#    / ____||  ____||__   __||__   __||_   _|| \ | | / ____| / ____|
#   | (___  | |__      | |      | |     | |  |  \| || |  __ | (___
#    \___ \ |  __|     | |      | |     | |  | . ` || | |_ | \___ \
#    ____) || |____    | |      | |    _| |_ | |\  || |__| | ____) |
#   |_____/ |______|   |_|      |_|   |_____||_| \_| \_____||_____/
#

#
#   For the Mac we need to add the path where to find the AWS CLI
#
PATH="~/Library/Python/3.6/bin:$PATH"

#
#   Save the first parameter as a path to the folder with the lambdas
#
DIR=$1

#
#   Save the name of the bucket where to upload the zip files
#
BUCKET=$2

#
#   Check for the presence of the directory to the lambdas
#
if [ -z "${DIR}" ]
then
    echo "We are missing the Folder with the Lambdas"
    exit -1
fi

#
#   Check for the presence of the Bucket name where to upload the zipped code
#
if [ -z "${BUCKET}" ]
then
    echo "We are missing the S3 Bucket"
    exit -1
fi

#
#   Get working dir
#
LOCAL=$(pwd)

#
#   create an array with all the filer/dir inside ~/myDir
#
FOLDERS=($DIR*)

#    ______  _    _  _   _   _____  _______  _____  ____   _   _   _____
#   |  ____|| |  | || \ | | / ____||__   __||_   _|/ __ \ | \ | | / ____|
#   | |__   | |  | ||  \| || |        | |     | | | |  | ||  \| || (___
#   |  __|  | |  | || . ` || |        | |     | | | |  | || . ` | \___ \
#   | |     | |__| || |\  || |____    | |    _| |_| |__| || |\  | ____) |
#   |_|      \____/ |_| \_| \_____|   |_|   |_____|\____/ |_| \_||_____/
#

#
#   This function will delete the create zip file after successful upload
#
clean()
{
    ARCHIVE_NAME=$(basename $1)

    rm $ARCHIVE_NAME.zip
}

#
#   This function will use the AWS CLI to upload the zip file to S3
#
upload_to_s3()
{
    ARCHIVE_NAME=$(basename $1)

    aws s3 cp $ARCHIVE_NAME.zip s3://$BUCKET/$ARCHIVE_NAME.zip
}

#
#   This function will zip the content of a Lambda function
#
#       IMPORTANT
#
#           The created archive can't have the Lambda root folder
#
zip_it()
{
    ARCHIVE_NAME=$(basename $1)

    pushd $1 > /dev/null
    zip -r -q $LOCAL/$ARCHIVE_NAME .
    popd > /dev/null
}

#
#   This function will install all the NPM dependecies for each Lambda
#
#
#   This function will install all the NPM dependecies for each Lambda
#
npm_install()
{
    ARCHIVE_NAME=$(basename $1)

    #
    #   Saves the current working directory in memory so we can be returned
    #   to it later
    #
    pushd $1 > /dev/null

    #
    #   Check if there is a npm config file
    #
    if [ -e package.json ]; then

        #
        #   Install all the NodeJS modules while supressing the output to reduce
        #   noise
        #
        npm install 2>/dev/null

    fi

    #
    #   Check if a node modules exists
    #
    if [ -d node_modules ]; then

        #
        #   For whatever reason after the npm install command some files that
        #   get pulled have a date way back in the past: like 1985.
        #
        #   The following command will touch any file created in the past to
        #   let the system update the data of those files
        #
        find ./node_modules -mtime +10950 -exec touch {} \;

    fi

    #
    #   Returns to the path at the top of the directory stack
    #
    popd > /dev/null
}

#    __  __              _____   _   _
#   |  \/  |     /\     |_   _| | \ | |
#   | \  / |    /  \      | |   |  \| |
#   | |\/| |   / /\ \     | |   | . ` |
#   | |  | |  / ____ \   _| |_  | |\  |
#   |_|  |_| /_/    \_\ |_____| |_| \_|
#

#
#   1.  First we need to create the S3 Bucket
#
aws s3api create-bucket --bucket $BUCKET --region us-east-2 > /dev/null

#
#   2.  Iterate through the array of folders
#
for ((i=0; i < ${#FOLDERS[@]}; i++));
do
    #
    #   Install all the dependecies
    #
    npm_install "${FOLDERS[$i]}"

    #
    #   Zip the folder of the Lambda
    #
    zip_it "${FOLDERS[$i]}"

    #
    #   Upload it to S3
    #
    upload_to_s3 "${FOLDERS[$i]}"

    #
    #   Delete the file after all is done
    #
    clean "${FOLDERS[$i]}"
done