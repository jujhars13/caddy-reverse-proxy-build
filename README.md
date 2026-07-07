# Caddy build with Coraza WAF

Builds and publishes Caddy + [Coraza WAF](github.com/corazawaf/coraza-caddy) 

## To build container

```bash
# increment the version number
npm version {major,minor,patch}

# now docker commit your commit

or use

./commit.sh
```

## Using

```Caddyfile
{
	http_port 80
	https_port 443
	order coraza_waf first
	log {
		output stdout
		format console
		level debug
		include "http.handlers.waf"
	}
    
}

beszel.home.lan:443 192.168.10.23:443 {
	#tls internal
	tls /certs/home.lan.wildcard-fullchain.pem /certs/cert-key.pem

	coraza_waf {
		load_owasp_crs
		directives `
		Include @coraza.conf-recommended
		Include /ruleset/1_crs_setup.conf
		Include @owasp_crs/*.conf
		SecDefaultAction "phase:3,log,auditlog,pass"
		SecDefaultAction "phase:4,log,auditlog,pass"
		SecDefaultAction "phase:5,log,auditlog,pass"
		SecRuleEngine On
		SecDebugLog /tmp/coraza_debug.log
		SecDebugLogLevel 9
		SecRule REQUEST_URI "@streq /admin" "id:101,phase:1,t:lowercase,deny,status:403"
		SecRule REQUEST_BODY "@rx maliciouspayload" "id:102,phase:2,t:lowercase,deny,status:403"
		SecRule RESPONSE_STATUS "@rx 406" "id:103,phase:3,t:lowercase,deny,status:403"
		SecResponseBodyAccess On
		SecResponseBodyMimeType application/json
		SecRule RESPONSE_BODY "@contains responsebodycode" "id:104,phase:4,t:lowercase,deny,status:403"
		SecAuditEngine On
		SecAuditLog /tmp/corza_audit.log
		SecAuditLogFormat json
		`
	}

	reverse_proxy beszel:8090
	handle {
		encode gzip
		header Strict-Transport-Security max-age1536000;
		header Access-Control-Allow-Origin "*"
		header Access-Control-Allow-Methods "OPTIONS,HEAD,GET,POST,PUT,PATCH,DELETE"
	}
}

```

## Sources

- https://medium.com/@jptosso/oss-waf-stack-using-coraza-caddy-and-elastic-3a715dcbf2f2
