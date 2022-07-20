FROM mcr.microsoft.com/vscode/devcontainers/ruby:3.1

COPY --from=docker:dind /usr/local/bin/docker /usr/local/bin/

RUN wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | sudo apt-key add - \
    && echo "deb https://packages.cloudfoundry.org/debian stable main" | sudo tee /etc/apt/sources.list.d/cloudfoundry-cli.list \
    && apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install postgresql-client postgresql-client-common mariadb-client cf7-cli -y \
    && apt-get install -o Dpkg::Options::="--force-overwrite" cf8-cli -y \
    && gem install cf-uaac \
    && wget $(curl -s https://api.github.com/repos/cloudfoundry/credhub-cli/releases/latest | \
    jq -r '.assets[] | select(.name|match("credhub-linux.*")) | .browser_download_url') -O credhub.tar.gz \
    && tar -xzf credhub.tar.gz && rm -f credhub.tar.gz && mv credhub /usr/bin \
    && wget $(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | \
    jq -r '.assets[] | select(.name|match("linux_amd64$")) | .browser_download_url') -O /usr/bin/yq \
    && chmod +x /usr/bin/yq