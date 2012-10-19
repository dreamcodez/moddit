ver = '1.94'
src = "yaws-#{ver}"
tarball = "#{src}.tar.gz"

# soft depends on erlang (built manually)
unless File.file? '/usr/local/bin/yaws'
  package 'build-essential'
  package 'libpam0g-dev'
  package 'zip'

  bash "installing yaws #{ver}" do
    cwd '/tmp'
    code <<-EOH
      set -e

      wget http://yaws.hyber.org/download/#{tarball}
      tar -xvzf #{tarball}
      cd #{src}
      ./configure
      make
      make install
      cd applications/yapp
      make
      make install
 
      mkdir -p /nowhere
      mkdir -p /applications/yapp/ebin
    EOH
  end
  
  cookbook_file '/usr/local/etc/yaws/yaws.conf' do
    source 'yaws.conf'
    mode '0644'
  end 
end

