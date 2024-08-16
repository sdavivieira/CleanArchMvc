# Acesse https://aka.ms/customizecontainer para saber como personalizar seu contêiner de depuração e como o Visual Studio usa este Dockerfile para criar suas imagens para uma depuração mais rápida.

# Esta fase é usada durante a execução no VS no modo rápido (Padrão para a configuração de Depuração)
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
USER app
WORKDIR /app
EXPOSE 7143


# Esta fase é usada para compilar o projeto de serviço
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["CleanArchMvc.API/CleanArchMvc.API.csproj", "CleanArchMvc.API/"]
COPY ["CleanArchMvc.Infra.IoC/CleanArchMvc.Infra.IoC.csproj", "CleanArchMvc.Infra.IoC/"]
COPY ["CleanArchMvc.Application/CleanArchMvc.Application.csproj", "CleanArchMvc.Application/"]
COPY ["CleanArchMvc.Domain/CleanArchMvc.Domain.csproj", "CleanArchMvc.Domain/"]
COPY ["CleanArchMvc.Infra.Data/CleanArchMvc.Infra.Data.csproj", "CleanArchMvc.Infra.Data/"]
RUN dotnet restore "./CleanArchMvc.API/CleanArchMvc.API.csproj"
COPY . .
WORKDIR "/src/CleanArchMvc.API"
RUN dotnet build "./CleanArchMvc.API.csproj" -c $BUILD_CONFIGURATION -o /app/build

# Esta fase é usada para publicar o projeto de serviço a ser copiado para a fase final
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./CleanArchMvc.API.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# Esta fase é usada na produção ou quando executada no VS no modo normal (padrão quando não está usando a configuração de Depuração)
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "CleanArchMvc.API.dll"]