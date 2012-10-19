ver = 'R15B02'
src = "otp_src_#{ver}"
tarball = "#{src}.tar.gz"

unless File.file? '/usr/local/bin/erl'
  package 'build-essential'

  bash "installing erlang #{ver}" do
    cwd '/tmp'
    code <<-EOH
      set -e

      wget http://www.erlang.org/download/#{tarball}
      tar -xvzf #{tarball}
      cd #{src}
      ./configure
      make
      make install
    EOH
  end
end

