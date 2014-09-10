environment     "production"
threads         16, 32
pidfile         "/var/run/app/web_server.pid"
state_path      "/var/run/app/web_server.state"
bind            "unix:///var/run/app/web_server.sock"

# Add a worker per CPU core
workers         %x{grep -c processor /proc/cpuinfo}.strip

activate_control_app "unix:///var/run/app/web_control.sock"
