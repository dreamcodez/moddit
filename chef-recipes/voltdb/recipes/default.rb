ver = '2.8.3.1'
src = "voltdb-#{ver}"
tarball = "LINUX-#{src}.tar.gz"

unless File.file? '/usr/local/voltdb-2.8.3.1/bin/voltdb'
  package 'openjdk-7-jdk'
  package 'ant'

  bash "installing voltdb #{ver}" do
    cwd 'tmp'
    code <<-EOH
      set -e

      wget http://community.voltdb.com/sites/default/files/archive/2.8.3.1/#{tarball}
      cd /usr/local
      tar -xvzf /tmp/#{tarball}
    EOH
  end
end

erl_client_ver = '1.3.01-alpha'
unless File.file? '/usr/local/voltdb-client-erlang/erlvolt.beam'
  bash "installing voltdb erlang client #{erl_client_ver}" do
    cwd 'tmp'
    code <<-EOH
      wget http://community.voltdb.com/sites/default/files/archive/1.3.01/voltdb-client-erlang-1.3.01-alpha.tar.gz
      cd /usr/local
      tar -xvzf /tmp/voltdb-client-erlang-1.3.01-alpha.tar.gz
      ln -s voltdb-client-erlang-1.3.01-alpha voltdb-client-erlang
      cd voltdb-client-erlang
      erlc erlvolt.erl
    EOH
  end
end

