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

ARG authurl

ARG keyurl

ARG spring_config_url

ARG spring_config_label

ARG version

ENV app_version=${version}
# environment variable to pass artifactory url, at docker runtime
ENV artifactory_url_env=${artifactory_url}

ENV auth_url_env=${authurl}

ENV key_url_env=${keyurl}

ENV spring_config_label_env=${spring_config_label}

ENV spring_config_url_env=${spring_config_url}

# install packages and create user
RUN apt-get -y update \
&& apt-get install -y unzip zip curl git npm python vim \
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

ADD get-cert.sh get-cert.sh

RUN chmod +x get-cert.sh

RUN cd /home/${container_user} && mkdir -p mosip-file-server/.well-known/mosipvc && mkdir -p mosip-file-server/files/mobileapp

ENV base_path_mosipvc=/home/${container_user}/mosip-file-server/.well-known/mosipvc

ENV base_path_apk=/home/${container_user}/mosip-file-server/files/mobileapp

RUN chown -R ${container_user}:${container_user} /home/${container_user}


# select container user for all tasks
USER ${container_user_uid}:${container_user_gid}

EXPOSE 8080

ENTRYPOINT ["./get-cert.sh"]

CMD ["/bin/bash","-c","echo 'starting nginx'; nginx ; sleep infinity"]
