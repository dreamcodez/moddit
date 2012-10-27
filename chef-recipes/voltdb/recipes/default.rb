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

