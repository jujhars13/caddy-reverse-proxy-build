FROM caddy:builder AS caddy-builder

# Pin WAF versions: unpinned builds pulled CRS `main`, whose crs-setup.conf.example
# started defining SecDefaultAction for phases 3-5, which Coraza >=3.8 rejects as a
# duplicate when the Caddyfile also defines them -> caddy failed to start.
# Keep CRS_VERSION in step with the coraza-coreruleset version embedded in coraza-caddy
# (check with: docker run --rm <image> caddy build-info | grep coreruleset)
# so /ruleset/1_crs_setup.conf matches the @owasp_crs/*.conf rules it configures.
ARG CORAZA_CADDY_VERSION=v2.6.2
ARG CRS_VERSION=v4.25.0

# RUN xcaddy build \
#     --with github.com/corazawaf/coraza-caddy/v2 \
#     --with github.com/caddy-dns/cloudflare
RUN xcaddy build \
    --with github.com/corazawaf/coraza-caddy/v2@${CORAZA_CADDY_VERSION}

# coraza.conf-recommended is embedded in coraza-caddy (Caddyfile uses @coraza.conf-recommended),
# so only the CRS setup file needs fetching
RUN git clone --depth 1 --branch ${CRS_VERSION} https://github.com/coreruleset/coreruleset /ruleset/coreruleset

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
