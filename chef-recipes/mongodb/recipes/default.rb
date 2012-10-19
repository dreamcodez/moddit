ver = "2.2.0" 
src = "mongodb-src-r#{ver}"
tarball = "#{src}.tar.gz"

unless File.file? '/usr/local/bin/mongo'
  package 'build-essential'
  package 'scons'

  bash "installing mongodb #{ver}" do
    cwd '/tmp'
    code <<-EOH
      set -e

      wget http://downloads.mongodb.org/src/#{tarball}
      tar -xvzf #{tarball}
      cd #{src}
      scons .
      scons install
    EOH
  end
end

