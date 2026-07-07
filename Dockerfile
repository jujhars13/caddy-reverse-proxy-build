FROM caddy:builder AS caddy-builder

# RUN xcaddy build \
#     --with github.com/corazawaf/coraza-caddy/v2 \
#     --with github.com/caddy-dns/cloudflare
RUN xcaddy build \
    --with github.com/corazawaf/coraza-caddy/v2

RUN mkdir -p /ruleset

# get ruleset from here: https://github.com/corazawaf/coraza/
RUN wget https://raw.githubusercontent.com/corazawaf/coraza/refs/tags/v3.7.0/coraza.conf-recommended -o /ruleset/coraza.conf && \
    git clone https://github.com/coreruleset/coreruleset /ruleset/coreruleset

FROM caddy:alpine

LABEL maintainer="jujhar@jujhar.com"

RUN mkdir -p /ruleset

COPY --from=caddy-builder /usr/bin/caddy /usr/bin/caddy
COPY --from=caddy-builder /ruleset/coreruleset/crs-setup.conf.example /ruleset/1_crs_setup.conf

# in order to add your own certs
RUN apk add nss-tools

# Expose the HTTP port that Caddy will listen on.
#   - this does not expose the port on the host, for that use the `docker run -p` command.
EXPOSE 8080
