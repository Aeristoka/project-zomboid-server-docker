###########################################################
# Dockerfile that builds a Project Zomboid Gameserver
###########################################################
FROM cm2network/steamcmd:root

LABEL maintainer="daniel.carrasco@electrosoftcloud.com"

ENV STEAMAPPID=380870
ENV STEAMAPP=pz
ENV STEAMAPPDIR="${HOMEDIR}/${STEAMAPP}-dedicated"
# Fix for a new installation problem in the Steamcmd client
ENV HOME="${HOMEDIR}"

# Receive the value from docker-compose as an ARG
ARG STEAMAPPBRANCH="public"
# Promote the ARG value to an ENV for runtime
ENV STEAMAPPBRANCH=$STEAMAPPBRANCH

# Install required packages and generate locales for other languages in the PZ Server
RUN apt-get update \
  && apt-get install -y --no-install-recommends --no-install-suggests dos2unix \
  && sed -i 's/^# *\(es_ES.UTF-8\)/\1/' /etc/locale.gen \
  && locale-gen \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Download the Project Zomboid dedicated server app using the steamcmd app
# Set the entry point file permissions
RUN set -x \
  && mkdir -p "${STEAMAPPDIR}" \
  && chown -R "${USER}:${USER}" "${STEAMAPPDIR}" \
  && bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "${STEAMAPPDIR}" \
  +login anonymous \
  +app_update "${STEAMAPPID}" -beta "${STEAMAPPBRANCH}" validate \
  +quit

# Copy and set permissions for entry point and search folder scripts
COPY --chown=${USER}:${USER} scripts/entry.sh scripts/search_folder.sh /server/scripts/
RUN chmod 550 /server/scripts/entry.sh /server/scripts/search_folder.sh

# Create required folders to keep their permissions on mount
RUN mkdir -p "${HOMEDIR}/Zomboid"

WORKDIR ${HOMEDIR}
# Expose ports
EXPOSE 16261-16262/udp \
  27015/tcp

ENTRYPOINT ["/server/scripts/entry.sh"]