# base image
FROM nginx

ARG SOURCE
ARG COMMIT_HASH
ARG COMMIT_ID
ARG BUILD_TIME
LABEL source=${SOURCE}
LABEL commit_hash=${COMMIT_HASH}
LABEL commit_id=${COMMIT_ID}
LABEL build_time=${BUILD_TIME}

# can be passed during Docker build as build time environment for github branch to pickup configuration from.
ARG container_user=mosip

# can be passed during Docker build as build time environment for github branch to pickup configuration from.
ARG container_user_group=mosip

# can be passed during Docker build as build time environment for github branch to pickup configuration from.
ARG container_user_uid=1001

# can be passed during Docker build as build time environment for github branch to pickup configuration from.
ARG container_user_gid=1001

# can be passed during Docker build as build time environment for artifactory URL

ARG AUTHMANAGER_URL

ARG KEYMANAGER_URL

ARG IDA_INTERNAL_URL

ARG KEYCLOAK_CLIENT_ID

ARG KEYCLOAK_CLIENT_PASSWORD

ARG AUTH_APP_ID

ARG spring_config_url

ARG spring_config_label

ARG active_profile_env

ARG version

ENV app_version=${version}
# environment variable to pass artifactory url, at docker runtime
ENV artifactory_url_env=${artifactory_url}

ENV AUTHMANAGER_URL=${AUTHMANAGER_URL}

ENV KEYMANAGER_URL=${KEYMANAGER_URL}

ENV IDA_INTERNAL_URL=${IDA_INTERNAL_URL}

ENV KEYCLOAK_CLIENT_ID=${CLIENT_ID}

ENV KEYCLOAK_CLIENT_PASSWORD=${KEYCLOAK_CLIENT_PASSWORD}

ENV AUTH_APP_ID=${AUTH_APP_ID}

ENV spring_config_label_env=${spring_config_label}

ENV spring_config_url_env=${spring_config_url}

ENV active_profile_env=${active_profile_env}

ENV PIP_BREAK_SYSTEM_PACKAGES=1

# install packages and create user
RUN apt-get -y update \
&& apt-get install -y unzip zip curl git wget jq npm python3 python3-pip vim \
&& pip3 install 'cryptography==3.4.8' 'jwcrypto==1.4.2' \
&& groupadd -g ${container_user_gid} ${container_user_group} \
&& useradd -u ${container_user_uid} -g ${container_user_group} -s /bin/sh -m ${container_user} \
&& mkdir -p /var/run/nginx /var/tmp/nginx \
&& chown -R ${container_user}:${container_user} /usr/share/nginx /var/run/nginx /var/tmp/nginx

# set working directory for the user
WORKDIR /home/${container_user}

ADD ./nginx.conf /etc/nginx/nginx.conf

ADD ./default.conf /etc/nginx/conf.d/

ADD ./download.conf /etc/nginx/include/download.conf

#ADD ./*.apk /home/${container_user}/mobileapp/resident-app.apk

ADD *.sh ./

ADD *.py ./

RUN chmod +x *.sh *.py

ENV base_path_mosipvc=/home/${container_user}/mosip-file-server/.well-known/mosipvc/

ENV base_path_inji_model=/home/${container_user}/mosip-file-server/files/inji/

ENV base_path_mosip_certs=/home/${container_user}/mosip-file-server/mosip-certs/

RUN cd /home/${container_user} && mkdir -p ${base_path_mosipvc} ${base_path_inji_model} ${base_path_mosip_certs}

ADD ./inji-model ${base_path_inji_model}

RUN chown -R ${container_user}:${container_user} /home/${container_user}

# select container user for all tasks
USER ${container_user_uid}:${container_user_gid}

EXPOSE 8080

ENTRYPOINT ["./entrypoint.sh"]
