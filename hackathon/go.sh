#!/usr/bin/env bash
mvn clean package
docker build . -t dvnhack2018acr.azurecr.io/safe
docker push dvnhack2018acr.azurecr.io/safe