#!/bin/bash

echo 'Cleaning up old build artifacts'
./gradlew clean
rm -rf fbn-web/dist
rm -rf infrastructure/import/ExcelProcessor/bin/RELEASE/netcore* infrastructure/import/ExcelProcessor/out

echo 'Building Angular app - with /web base href'
cd fbn-web
npm install
MSYS2_ARG_CONV_EXCL="--base-href=" ng build --base-href="/web/" --prod

echo 'Copy Angular resources'
cd ..
mkdir -p build/resources/main/static
cp -r fbn-web/dist/fbn-web/* build/resources/main/static

echo 'Building Spring Boot app'
BUILD_NUMBER=$(date +%y%m%d%H%M%S)
./gradlew -PsetVersion=1.$BUILD_NUMBER clean build -x test

echo 'Building Export/Import tool'
cd infrastructure/import/ExcelProcessor
dotnet publish /p:AssemblyVersion=1.2 -c Release -o out
# dotnet run ExcelProcessor (only for verification testing)
# need to package infrastructure/import/ExcelProcessor/bin/RELEASE/netcore*/* folder for deployment
cd ../../../
cp -r infrastructure/import/ExcelProcessor/out build/import-tool
