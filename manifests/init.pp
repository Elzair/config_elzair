class config_elzair (
  $user = $config_elzair::params::user,
  $group = $config_elzair::params::group,
  $home_dir = $config_elzair::params::home_dir,
  $vagrant_dir = $config_elzair::params::root_dir,
  $operatingsystem = $config_elzair::params::operatingsystem,
  $distro = $config_elzair::params::operatingsystem
) inherits config_elzair::params 
{
  $path = [
    "/opt/local/bin",
    "/usr/local/sbin",
    "/usr/local/bin",
    "/usr/sbin",
    "/usr/bin",
    "/sbin",
    "/bin",
  ]

  package { "curl":
    ensure => present,
  }
 
  package { "zsh":
    ensure => present,
  }

  file { "root .ssh":
    ensure => directory,
    path   => "/root/.ssh",
    owner  => "root",
    group  => "root",
    mode   => "0600",
  }
  
  file { "$user .ssh":
    ensure => directory,
    path   => "$home_dir/.ssh",
    owner  => "root",
    group  => "root",
    mode   => "0600",
  }

  file { "root .ssh/id_rsa":
    ensure  => file,
    path    => "/root/.ssh/id_rsa",
    source  => "$vagrant_dir/config/ssh/id_rsa",
    owner   => "root",
    group   => "root",
    mode    => "0600",
    require => File["root .ssh"],
  }

  file { "root .ssh/id_rsa.pub":
    ensure => file,
    path   => "/root/.ssh/id_rsa.pub",
    source => "$vagrant_dir/config/ssh/id_rsa.pub",
    owner  => "root",
    group  => "root",
    mode   => "0600",
    require => File["root .ssh"],
  }

  file { "$user .ssh/id_rsa":
    ensure => file,
    path   => "$home_dir/.ssh/id_rsa",
    source => "$vagrant_dir/config/ssh/id_rsa",
    owner  => $user,
    group  => $user,
    mode   => "0600",
    require => File["$user .ssh"],
  }

  file { "$user .ssh/id_rsa.pub":
    ensure => file,
    path   => "$home_dir/.ssh/id_rsa.pub",
    source => "$vagrant_dir/config/ssh/id_rsa.pub",
    owner  => $user,
    group  => $user,
    mode   => "0600",
    require => File["$user .ssh"],
  }

  file { "~/.ssh/config":
    ensure => file,
    path   => "$home_dir/.ssh/config",
    source => "puppet:///modules/config_elzair/ssh-config",
    owner  => $user,
    group  => $group,
    mode   => "0600",
    require => File["$user .ssh"],
  }

  file { "~/misc":
    ensure => directory,
    path   => "$home_dir/misc",
    owner  => $user,
    group  => $group,
    mode   => "0755",
  }

  exec { "clone oh-my-zsh":
    command   => "git clone https://github.com/robbyrussell/oh-my-zsh.git $home_dir/.oh-my-zsh",
    path      => $path,
    logoutput => true,
    require   => [ Class["config_build"], Package["curl"], Package["zsh"], File["~/misc"] ],
  }

  exec { "install elzair-zsh-theme":
    command   => "curl -L https://raw.github.com/Elzair/elzair-zsh-theme/master/elzair.zsh-theme -o $home_dir/.oh-my-zsh/themes/elzair.zsh-theme",
    path      => $path,
    logoutput => true,
    require   => Exec["clone oh-my-zsh"],
  }

  $zshrc_src = $operatingsystem ? {
    osx     => "puppet:///modules/config_elzair/osx.zshrc",
    default => "puppet:///modules/config_elzair/linux.zshrc",
  }

  file { "~/.zshrc":
    ensure  => file,
    path    => "$home_dir/.zshrc",
    source  => $zshrc_src,
    owner   => $user,
    group   => $group,
    mode    => "0644",
    require => Exec["install elzair-zsh-theme"],
  }

  exec { "change user shell to zsh":
    command   => "chsh -s $(which zsh) $user"
    path      => $path,
    logoutput => true,
    require   => File["~/.zshrc"],
  }

  $gvim = $distro ? {
    /(?i-mx:ubuntu|debian|mint)/ => "vim-gtk",
    /(?i-mx:centos|redhat)/      => "vim-enhanced",
    arch                         => "gvim",
    osx                          => "mvim",
    default                      => undef,
  }

  if ($gvim) {
    package { "gvim":
      name   => $gvim,
      ensure => present,
    }

    file { "~/.vim":
      ensure  => directory,
      path    => "$home_dir/.vim",
      owner   => $user,
      group   => $group,
      mode    => "0644",
    }

    file { "~/.vim/bundle":
      ensure  => directory,
      path    => "$home_dir/.vim/bundle",
      owner   => $user,
      group   => $group,
      mode    => "0644",
      require => File["~/.vim"],
    }

    exec { "configure gvim":
      command   => "git clone ssh://git@github.com/Elzair/my-vimrc.git $home_dir/.vim/my-vimrc && chown -R $user\:$group $home_dir/.vim/my-vimrc && cp $home_dir/.vim/my-vimrc/vimrc $home_dir/.vimrc && cp $home_dir/.vim/my-vimrc/gvimrc $home_dir/.gvimrc",
      path      => $path,
      logoutput => true,
      require   => [ Class["config_build"], File["~/.vim"] ],
    }

    exec { "install vundle":
      command   => "git clone https://github.com/gmarik/vundle.git $home_dir/.vim/bundle/vundle",
      path      => $path,
      logoutput => true,
      require   => [ Class["config_build"], File["~/.vim/bundle"] ],
    }

    exec { "install vim bundles":
      command   => "vim +BundleInstall +qall 2&> /dev/null",
      path      => $path,
      logoutput => true,
      require   => [ Package["gvim"], Exec["configure gvim"], Exec["install vundle"], File["$user .ssh/id_rsa"], File["$user .ssh/id_rsa.pub"] ],
    }
  }

  $inconsolata = $distro ? {
    /(?i-mx:ubuntu|debian|mint)/ => "ttf-inconsolata",
    /(?i-mx:centos|redhat)/      => "inconsolata-fonts",
    default                      => undef,
  }

  if ($inconsolata) {
    package { "inconsolata":
      name   => $inconsolata,
      ensure => present,
    }

    exec { "regenerate font cache":
      command   => "fc-cache -fv",
      path      => $path,
      logoutput => true,
      require   => Package["inconsolata"],
    }
  }
}
