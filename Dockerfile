FROM debian:13.2

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install packages available through apt
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    bash-completion=1:2.16.0-7 \
    wget=1.25.0-2 \
    git=1:2.47.3-0+deb13u1 \
    python3=3.13.5-1 \
    python3-dev=3.13.5-1 \
    python3-pip=25.1.1+dfsg-1 \
    python3-venv=3.13.5-1 \
    lsb-release=12.1-1 \
    locales=2.41-12 \
    openvpn=2.6.14-1+deb13u1 \
    openresolv=3.13.2-3 \
    iproute2=6.15.0-1 \
    chromium=143.0.7499.40-1~deb13u1 \
    gnupg=2.4.7-21 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install pipx
RUN python3 -m pip install --no-cache-dir --break-system-packages pipx==1.8.0 && python3 -m pipx ensurepath

# Updating ENV to use pipx
ENV PATH="/root/.local/bin:$PATH"

# Install Hadolint
RUN wget -q -nv https://github.com/hadolint/hadolint/releases/download/v2.14.0/hadolint-linux-x86_64 && \
    wget -q -nv https://github.com/hadolint/hadolint/releases/download/v2.14.0/hadolint-linux-x86_64.sha256 && \
    sha256sum --check --quiet --status --strict hadolint-linux-x86_64.sha256 && \
    mv hadolint-linux-x86_64 /usr/local/bin/hadolint && \
    chmod +x /usr/local/bin/hadolint && \
    rm hadolint-linux-x86_64.sha256

# Install Terraform and openstack as root user
RUN wget -q -nv -O - https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y terraform=1.14.1-1 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install terraform auto-completions
RUN terraform -install-autocomplete

# Install OCI-cli
RUN wget -q -nv -O install.sh https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh && \
    chmod +x install.sh && \
    ./install.sh --accept-all-defaults && \
    rm -f install.sh

# Install pre-commit
RUN pipx install pre-commit==4.5.0

# Install ansible
# Install ansible auto-completions, ansible tools and openstack client
RUN pipx install --include-deps ansible==13.0.0 && \
    pipx inject --include-apps ansible argcomplete ansible-dev-tools ansible-creator && activate-global-python-argcomplete

# Install ansible-lint
RUN pipx install --include-deps ansible-lint==25.12.0

# Prepare lang environment for ansible
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
