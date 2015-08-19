
include Hooky::Memcached

# Setup
converged_boxfile = converge( Hooky::Memcached::BOXFILE_DEFAULTS, payload[:boxfile] ) 

# Import service (and start)
directory '/etc/service/cache' do
  recursive true
end

directory '/etc/service/cache/log' do
  recursive true
end

template '/etc/service/cache/log/run' do
  mode 0755
  source 'log-run.erb'
  variables ({ svc: "cache" })
end

mem_exec = "/data/bin/memcached \
-m #{payload[:member][:schema][:meta][:ram].to_i / 1024 / 1024} \
-c #{boxfile[:memcached_max_connections]} \
-f #{boxfile[:memcached_chunk_size_growth_factor]} \
-n #{boxfile[:memcached_minimum_allocated_space]} \
-R #{boxfile[:memcached_maximum_requests_per_event]} \
-b #{boxfile[:memcached_max_backlog]} \
-B #{boxfile[:memcached_binding_protocol]} \
   #{boxfile[:memcached_return_error_on_memory_exhausted] ? '-M' : ''} \
   #{boxfile[:memcached_disable_cas] ? '-C' : ''}"

template '/etc/service/cache/run' do
  mode 0755
  variables ({ exec: mem_exec })
end

# Configure narc
template '/opt/gonano/etc/narc.conf' do
  variables ({ uid: payload[:uid], app: "nanobox", logtap: payload[:logtap_uri] })
end

directory '/etc/service/narc'

file '/etc/service/narc/run' do
  mode 0755
  content <<-EOF
#!/bin/sh -e
export PATH="/opt/local/sbin:/opt/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/gonano/sbin:/opt/gonano/bin"

exec /opt/gonano/bin/narcd /opt/gonano/etc/narc.conf
  EOF
end
