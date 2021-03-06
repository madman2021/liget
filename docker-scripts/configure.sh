#!/bin/bash -e

config_json=/app/appsettings.json
runtime_config=/app/LiGet.runtimeconfig.json

if [ "${LIGET_SKIP_APPCONFIG_GEN}" == "true" ]; then
  echo "LIGET_SKIP_APPCONFIG_GEN is set. Will not generate $config_json"
else
  cat $config_json | jq --arg cfg ${LIGET_API_KEY_HASH} '. | .ApiKeyHash = $cfg' | sponge $config_json
  # .Database
  cat $config_json | jq --arg cfg ${LIGET_EF_RUN_MIGRATIONS} '. | .Database.RunMigrations = ($cfg == "true")' | sponge $config_json
  cat $config_json | jq --arg cfg ${LIGET_DB_TYPE} '. | .Database.Type = $cfg' | sponge $config_json
  cat $config_json | jq --arg cfg "${LIGET_DB_CONNECTION_STRING}" '. | .Database.ConnectionString = $cfg' | sponge $config_json
  if [ "${LIGET_STORAGE_BACKEND}" == "simple2" ]; then
    cat $config_json | jq '.| .Storage .Type = "FileSystem"' | sponge $config_json
    cat $config_json | jq --arg cfg ${LIGET_SIMPLE2_ROOT_PATH} '. | .Storage.Path = $cfg' | sponge $config_json
  fi
  # .Search
  cat $config_json | jq --arg cfg ${LIGET_SEARCH_PROVIDER} '. | .Search.Type = $cfg' | sponge $config_json

  # .Cache
  cat $config_json | jq --arg cfg ${LIGET_CACHE_ENABLED} '. | .Cache.Enabled = ($cfg == "true")' | sponge $config_json
  cat $config_json | jq --arg cfg ${LIGET_CACHE_PROXY_SOURCE_INDEX} '. | .Cache.UpstreamIndex = $cfg' | sponge $config_json
  if [ "${LIGET_NUPKG_CACHE_BACKEND}" == "simple2" ]; then
    cat $config_json | jq --arg cfg ${LIGET_NUPKG_CACHE_SIMPLE2_ROOT_PATH} '. | .Cache.PackagesPath = $cfg' | sponge $config_json
  fi

  cat $config_json | jq --arg cfg ${LIGET_BAGET_COMPAT_ENABLED} '. | .BaGetCompat.Enabled = ($cfg == "true")' | sponge $config_json

  if [ "${LIGET_LOG_BACKEND}" == "console" ]; then
    cat $config_json | jq --arg cfg ${LIGET_LOG_LEVEL} '. | .Logging.Console.LogLevel.Default = $cfg' | sponge $config_json
  elif [ "${LIGET_LOG_BACKEND}" == "gelf" ]; then
    if [ -z "${LIGET_LOG_GELF_HOST}" ]; then
      echo "LIGET_LOG_GELF_HOST must be specified when logging backend is gelf"
      exit 1
    fi
    cat $config_json | jq --arg cfg ${LIGET_LOG_LEVEL} '. | .Logging.GELF.LogLevel.Default = $cfg' | sponge $config_json
    cat $config_json | jq --arg cfg ${LIGET_LOG_GELF_HOST} '. | .Graylog.Host = $cfg' | sponge $config_json
    cat $config_json | jq --arg cfg ${LIGET_LOG_GELF_SOURCE} '. | .Graylog.LogSource = $cfg' | sponge $config_json
    cat $config_json | jq --arg cfg ${LIGET_LOG_GELF_PORT} '. | .Graylog.Port = ($cfg | tonumber)' | sponge $config_json
    if [ -n "${LIGET_LOG_GELF_ENVIRONMENT}" ]; then
      cat $config_json | jq --arg cfg ${LIGET_LOG_GELF_ENVIRONMENT} '. | .Graylog.AdditionalFields.environment = $cfg' | sponge $config_json
    fi
  else
    echo "Unknown logging backend: ${LIGET_LOG_BACKEND}"
  fi

  echo "LiGet configuration generated:"
  cat $config_json
fi

if [ "${LIGET_SKIP_RUNTIMECONFIG_GEN}" == "true" ]; then
  echo "LIGET_SKIP_RUNTIMECONFIG_GEN is set. Will not generate $runtime_config"
else
  cat $runtime_config | jq --arg cfg ${LIGET_GC_CONCURRENT} '. | .configProperties."System.GC.Concurrent" = ($cfg == "true")' | sponge $runtime_config
  cat $runtime_config | jq --arg cfg ${LIGET_GC_SERVER} '. | .configProperties."System.GC.Server" = ($cfg == "true")' | sponge $runtime_config
  cat $runtime_config | jq --arg cfg ${LIGET_THREAD_POOL_MIN} '. | .configProperties."System.Threading.ThreadPool.MinThreads" = ($cfg | tonumber)' | sponge $runtime_config
  cat $runtime_config | jq --arg cfg ${LIGET_THREAD_POOL_MAX} '. | .configProperties."System.Threading.ThreadPool.MaxThreads" = ($cfg | tonumber)' | sponge $runtime_config

  echo "LiGet runtime configuration generated:"
  cat $runtime_config
fi
