#! /bin/bash

# check if setting file exists.
if ! [ -e ".env" ]; then
    echo -e "\e[31m[ERROR] .env doesn't exist.\e[0m"
    exit
fi

# read settings.
source .env

# check if setting is valid.
valid=true

if [ -z ${AWS_ECR_ADDRESS} ]; then
    echo -e "\e[31m[ERROR] AWS_ECR_ADDRESS is empty.\e[0m"
    valid=false
fi
if [ -z ${AWS_REGION} ]; then
    echo -e "\e[31m[ERROR] AWS_REGION is empty.\e[0m"
    valid=false
fi
if [ -z ${IMAGE_NAME} ]; then
    echo -e "\e[31m[ERROR] IMAGE_NAME is empty.\e[0m"
    valid=false
fi
if [ -z ${VERSION_TAG} ]; then
    echo -e "\e[31m[ERROR] VERSION_TAG is empty.\e[0m"
    valid=false
fi

if ! ${valid}; then
    exit
fi

# build image.
image_id=${AWS_ECR_ADDRESS}/${IMAGE_NAME}:${VERSION_TAG}
docker build . -t ${image_id} --target prod
if ! [[ $? == 0 ]] ; then
    echo -e "\e[31m[ERROR] docker build failed.\e[0m"
    exit
fi

# log in AWS ECR.
aws ecr get-login-password --region ${AWS_REGION} \
    | docker login --username AWS --password-stdin ${image_id} \
    > /dev/null
if ! [[ $? == 0 ]] ; then
    echo -e "\e[31m[ERROR] AWS ECR Login failed.\e[0m"
    exit
fi

# check if repository exists.
aws ecr describe-images --repository-name=${IMAGE_NAME} \
                        --region ${AWS_REGION} \
                        > /dev/null
if ! [[ $? == 0 ]] ; then
    echo -e "\e[31m[ERROR] ${IMAGE_NAME} repository doesn't exist.\e[0m"
    echo -e "\e[31m        please create new repository as described below.\e[0m"
    echo -e "\e[31m        > aws ecr create-repository --repository-name ${IMAGE_NAME} --region ${AWS_REGION}\e[0m"
    exit
fi

# check if tag already exists.
aws ecr describe-images --repository-name=${IMAGE_NAME} \
                        --image-ids=imageTag=${VERSION_TAG} \
                        --region ${AWS_REGION} \
                        > /dev/null
if [[ $? == 0 ]] ; then
    echo -e "\e[31m[ERROR] ${IMAGE_NAME}:${VERSION_TAG} already exists.\e[0m"
    exit
fi

# push image.
docker push ${image_id}
if ! [[ $? == 0 ]] ; then
    echo -e "\e[31m[ERROR] docker push failed.\e[0m"
    exit
fi
