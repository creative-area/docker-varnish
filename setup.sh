#!/bin/bash
set -e

# VCL config Based on:
# https://github.com/mattiasgeniar/varnish-4.0-configuration-templates/blob/master/default.vcl

# Get the Environment variables and save them in the variable envs
envs=$(printenv)

# Remove the default.vcl file
echo 'vcl 4.0;
import std;
import directors;
' > /etc/varnish/default.vcl

######################################
# BACKENDS
######################################

# Loop through all of our variables
for env in $envs
do
  # separate the name of the variable from the value
  IFS== read name value <<< "$env"

  # if the variable has PORT_80_TCP_ADDR it means this is a
  # variable created by a node container linked to the varnish
  # container
  if [[ $name == *PORT_80_TCP_ADDR* ]]; then

# Create a backend for each node container found in the variables
cat >> /etc/varnish/default.vcl << EOF
backend ${name} {
  .host = "${value}";
  .port = "80";
  .max_connections = 300;
  .first_byte_timeout = 300s;
  .connect_timeout = 5s;
  .between_bytes_timeout = 2s;
}
EOF

  fi
done

######################################
# ACL_PURGE
######################################
cat >> /etc/varnish/default.vcl << EOF
acl purge {
  "localhost";
  "127.0.0.1";
  "::1";
}
EOF

######################################
# VCL_INIT
######################################
cat >> /etc/varnish/default.vcl << EOF
sub vcl_init {
  new vdir = directors.round_robin();
EOF

# Loop again to add each backend created
for env in $envs
do
  IFS== read name value <<< "$env"
  if [[ $name == *PORT_80_TCP_ADDR* ]]; then

# Create each backend in the load balancer
cat >> /etc/varnish/default.vcl << EOF
  vdir.add_backend(${name});
EOF

  fi
done

cat >> /etc/varnish/default.vcl << EOF
}
EOF

#####################################
# VCL_RECV
#####################################
cat >> /etc/varnish/default.vcl << EOF
sub vcl_recv {
  set req.backend_hint = vdir.backend();
  if (req.restarts == 0) {
    if (req.http.X-Forwarded-For) {
      set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
    } else {
      set req.http.X-Forwarded-For = client.ip;
    }
  }
  set req.http.Host = regsub(req.http.Host, ":[0-9]+", "");
  set req.url = std.querysort(req.url);
  if (req.method == "PURGE") {
    if (!client.ip ~ purge) {
      return (synth(405, "This IP is not allowed to send PURGE requests."));
    }
    return (purge);
  }
  if (req.method != "GET" &&
      req.method != "HEAD" &&
      req.method != "PUT" &&
      req.method != "POST" &&
      req.method != "TRACE" &&
      req.method != "OPTIONS" &&
      req.method != "PATCH" &&
      req.method != "DELETE") {
    return (pipe);
  }
  if (req.method != "GET" && req.method != "HEAD") {
    return (pass);
  }
  if (req.url ~ "\#") {
    set req.url = regsub(req.url, "\#.*$", "");
  }
  if (req.url ~ "\?$") {
    set req.url = regsub(req.url, "\?$", "");
  }
  set req.http.Cookie = regsuball(req.http.Cookie, "has_js=[^;]+(; )?", "");
  set req.http.Cookie = regsuball(req.http.Cookie, "__utm.=[^;]+(; )?", "");
  set req.http.Cookie = regsuball(req.http.Cookie, "_ga=[^;]+(; )?", "");
  set req.http.Cookie = regsuball(req.http.Cookie, "utmctr=[^;]+(; )?", "");
  set req.http.Cookie = regsuball(req.http.Cookie, "utmcmd.=[^;]+(; )?", "");
  set req.http.Cookie = regsuball(req.http.Cookie, "utmccn.=[^;]+(; )?", "");
  set req.http.Cookie = regsuball(req.http.Cookie, "__gads=[^;]+(; )?", "");
  set req.http.Cookie = regsuball(req.http.Cookie, "__qc.=[^;]+(; )?", "");
  set req.http.Cookie = regsuball(req.http.Cookie, "__atuv.=[^;]+(; )?", "");
  set req.http.Cookie = regsuball(req.http.Cookie, "^;\s*", "");
  if (req.http.cookie ~ "^\s*$") {
    unset req.http.cookie;
  }
  if (req.http.Cache-Control ~ "(?i)no-cache") {
    if (! (req.http.Via || req.http.User-Agent ~ "(?i)bot" || req.http.X-Purge)) {
      return(purge);
    }
  }
  if (req.url ~ "^[^?]*\.(mp[34]|rar|tar|tgz|gz|wav|zip|bz2|xz|7z|avi|mov|ogm|mpe?g|mk[av])(\?.*)?$") {
    unset req.http.Cookie;
    return (hash);
  }
  if (req.url ~ "^[^?]*\.(bmp|bz2|css|doc|eot|flv|gif|gz|ico|jpeg|jpg|js|less|pdf|png|rtf|swf|txt|woff|xml)(\?.*)?$") {
    unset req.http.Cookie;
    return (hash);
  }
  set req.http.Surrogate-Capability = "key=ESI/1.0";
  if (req.http.Authorization) {
    return (pass);
  }
  return (hash);
}
EOF

######################################
# VCL_PIPE
######################################
cat >> /etc/varnish/default.vcl << EOF
sub vcl_pipe {
  return (pipe);
}
EOF

######################################
# VCL_PASS
######################################
cat >> /etc/varnish/default.vcl << EOF
sub vcl_pass {
  #return (pass);
}
EOF

######################################
# VCL_HASH
######################################
cat >> /etc/varnish/default.vcl << EOF
sub vcl_hash {
  hash_data(req.url);
  if (req.http.host) {
    hash_data(req.http.host);
  } else {
    hash_data(server.ip);
  }
  if (req.http.Cookie) {
    hash_data(req.http.Cookie);
  }
}
EOF

######################################
# VCL_HIT
######################################
cat >> /etc/varnish/default.vcl << EOF
sub vcl_hit {
  if (obj.ttl >= 0s) {
    return (deliver);
  }
  if (std.healthy(req.backend_hint)) {
    if (obj.ttl + 10s > 0s) {
      return (deliver);
    } else {
      return(fetch);
    }
  } else {
    if (obj.ttl + obj.grace > 0s) {
      return (deliver);
    } else {
      return (fetch);
    }
  }
  return (fetch);
}
EOF

######################################
# VCL_MISS
######################################
cat >> /etc/varnish/default.vcl << EOF
sub vcl_miss {
  return (fetch);
}
EOF

######################################
# VCL_BACKEND_RESPONSE
######################################
cat >> /etc/varnish/default.vcl << EOF
sub vcl_backend_response {
  if (beresp.http.Surrogate-Control ~ "ESI/1.0") {
    unset beresp.http.Surrogate-Control;
    set beresp.do_esi = true;
  }
  if (bereq.url ~ "^[^?]*\.(bmp|bz2|css|doc|eot|flv|gif|gz|ico|jpeg|jpg|js|less|mp[34]|pdf|png|rar|rtf|swf|tar|tgz|txt|wav|woff|xml|zip)(\?.*)?$") {
    unset beresp.http.set-cookie;
  }
  if (bereq.url ~ "^[^?]*\.(jpeg|jpg|gif|png|mp[34]|rar|tar|tgz|gz|wav|zip|bz2|xz|7z|avi|mov|ogm|mpe?g|mk[av])(\?.*)?$") {
    unset beresp.http.set-cookie;
    set beresp.do_stream = true;
    set beresp.do_gzip = false;
  }
  if (beresp.status == 301 || beresp.status == 302) {
    set beresp.http.Location = regsub(beresp.http.Location, ":[0-9]+", "");
  }
  if (beresp.status == 404) {
    set beresp.ttl = 15s;
    set beresp.uncacheable = true;
  }
  if (beresp.ttl <= 0s || beresp.http.Set-Cookie || beresp.http.Vary == "*") {
    set beresp.ttl = 120s;
    set beresp.uncacheable = true;
    return (deliver);
  }
  set beresp.grace = 6h;
  return (deliver);
}
EOF

######################################
# VCL_DELIVER
######################################
cat >> /etc/varnish/default.vcl << EOF
sub vcl_deliver {
  if (obj.hits > 0) {
    set resp.http.X-Cache = "HIT";
  } else {
    set resp.http.X-Cache = "MISS";
  }
  set resp.http.X-Cache-Hits = obj.hits;
  unset resp.http.X-Powered-By;
  unset resp.http.Server;
  unset resp.http.X-Drupal-Cache;
  unset resp.http.X-Varnish;
  unset resp.http.Via;
  unset resp.http.Link;
  unset resp.http.X-Generator;
  return (deliver);
}
EOF

######################################
# VCL_PURGE
######################################
cat >> /etc/varnish/default.vcl << EOF
sub vcl_purge {
  if (req.method != "PURGE") {
    set req.http.X-Purge = "Yes";
    return(restart);
  }
}
EOF

######################################
# VCL_SYNTH
######################################
cat >> /etc/varnish/default.vcl << EOF
sub vcl_synth {
  if (resp.status == 720) {
    set resp.http.Location = resp.reason;
    set resp.status = 301;
    return (deliver);
  } elseif (resp.status == 721) {
    set resp.http.Location = resp.reason;
    set resp.status = 302;
    return (deliver);
  }

  return (deliver);
}
EOF

######################################
# VCL_FINI
######################################
cat >> /etc/varnish/default.vcl << EOF
sub vcl_fini {
  return (ok);
}
EOF
