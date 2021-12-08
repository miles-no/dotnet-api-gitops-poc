FROM mcr.microsoft.com/dotnet/sdk:5.0 as build

WORKDIR /src/Dotnet.Api

COPY Dotnet.Api/Dotnet.Api .
RUN dotnet restore -r linux-musl-x64 "Dotnet.Api.csproj"

RUN dotnet publish ./Dotnet.Api.csproj \
    -c Release \
    -o /app/publish \
    -r linux-musl-x64 \
    --no-restore \
    --self-contained true \
    /p:PublishTrimmed=true \
    /p:TrimMode=Link \
    /p:PublishSingleFile=true 

FROM mcr.microsoft.com/dotnet/runtime-deps:5.0-alpine AS publish

# Run as non-root
RUN adduser --disabled-password \
    --home /app \
    --gecos '' dotnetuser && chown -R dotnetuser /app

# Upgrade musl in case of any vulnerabilities
RUN apk upgrade musl

# Required for Time Zone database lookups
RUN apk add --no-cache tzdata

USER dotnetuser
WORKDIR /app

# Copy files and folders
EXPOSE 5000
ENV ASPNETCORE_URLS=http://+:5000
COPY --chown=dotnetuser --from=build /app/publish .

ENTRYPOINT "./Dotnet.Api"