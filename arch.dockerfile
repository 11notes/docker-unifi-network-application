# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_VERSION=0

# :: FOREIGN IMAGES
  FROM 11notes/util AS util
  FROM 11notes/distroless:localhealth AS distroless-localhealth


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: SOURCE
  FROM alpine AS source
  ARG APP_VERSION

  RUN set -ex; \
    apk --update --no-cache add \
      jq \
      curl \
      wget \
      unzip; \
    wget -q --show-progress --progress=bar:force -O /tmp/unifi.zip $(curl -s "https://fw-update.ubnt.com/api/firmware?filter=eq~~product~~unifi-controller&filter=eq~~platform~~unix&filter=eq~~channel~~release&sort=-version" \ | jq -r "._embedded.firmware[] | select(.version | test(\"v${APP_VERSION}\")) | ._links.data.href"); \
    mkdir -p /distroless/usr/lib; \
    unzip -qq /tmp/unifi.zip -d /distroless/usr/lib; \
    mv /distroless/usr/lib/UniFi /distroless/usr/lib/unifi;

# :: UNIFI NETWORK APPLICATION
  FROM 11notes/debian:13 AS build
  COPY --from=util / /
  COPY --from=source /distroless/ /
  ARG APP_ROOT
  USER root

  RUN set -ex; \
    eleven apt install \
      openjdk-25-jre-headless \
      jsvc \
      logrotate;

  RUN set -ex; \
    mkdir -p ${APP_ROOT}/var/sites/default; \
    rm -rf /var/lib/unifi; ln -sf ${APP_ROOT}/var /var/lib/unifi; \
    rm -rf /var/log/unifi; ln -sf ${APP_ROOT}/log /var/log/unifi; \
    rm -rf /usr/lib/unifi/logs; ln -sf ${APP_ROOT}/log /usr/lib/unifi/logs; \
    rm -rf /var/run/unifi; ln -sf ${APP_ROOT}/run /var/run/unifi;

  RUN set -ex; \
    mkdir -p /usr/lib/unifi/data; \
    keytool -genkey -keyalg RSA -alias unifi -keystore /usr/lib/unifi/data/keystore -storepass aircontrolenterprise -keypass aircontrolenterprise -validity 3650 -keysize 4096 -dname "cn=unifi" -ext san=dns:unifi;

  RUN set -ex; \
    eleven cleanup;


# :: FILE SYSTEM
  FROM alpine AS file-system
  COPY ./rootfs/ /distroless
  ARG APP_ROOT

  RUN set -ex; \
    mkdir -p /distroless${APP_ROOT}/var; \
    mkdir -p /distroless${APP_ROOT}/log; \
    mkdir -p /distroless${APP_ROOT}/run; \
    chmod +x -R /distroless/usr/local/bin;


# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
# :: HEADER
  FROM scratch

  # :: default arguments
    ARG TARGETPLATFORM \
        TARGETOS \
        TARGETARCH \
        TARGETVARIANT \
        APP_IMAGE \
        APP_NAME \
        APP_VERSION \
        APP_ROOT \
        APP_UID \
        APP_GID \
        APP_NO_CACHE

  # :: default environment
    ENV APP_IMAGE=${APP_IMAGE} \
        APP_NAME=${APP_NAME} \
        APP_VERSION=${APP_VERSION} \
        APP_ROOT=${APP_ROOT}

  # :: multi-stage
    COPY --from=distroless-localhealth / /
    COPY --from=build / /
    COPY --from=file-system /distroless/ /

# :: PERSISTENT DATA
  VOLUME ["${APP_ROOT}/var"]

# :: MONITORING
  HEALTHCHECK --interval=5s --timeout=2s --start-period=5s \
    CMD ["/usr/local/bin/localhealth", "https://127.0.0.1:8443/", "-I"]

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]