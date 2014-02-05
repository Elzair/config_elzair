class config_elzair (
  $user = $config_elzair::params::user,
  $group = $config_elzair::params::group,
  $home_dir = $config_elzair::params::home_dir, 
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

  package { "git":
    ensure => present,
  }

  package { "curl":
    ensure => present,
  }
 
  package { "zsh":
    ensure => present,
  }

  file { "~/misc":
    ensure => directory,
    path   => "$home_dir/misc",
    owner  => $user,
    group  => $group,
    mode   => "0755",
  }

  exec { "install oh-my-zsh":
    command   => "curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh",
    path      => $path,
    logoutput => true,
    require   => [ Package["curl"], Package["zsh"], File["~/misc"] ],
  }

  exec { "install elzair-zsh-theme":
    command   => "curl -L https://raw.github.com/Elzair/elzair-zsh-theme/master/elzair.zsh-theme -o $home_dir/.oh-my-zsh/themes/elzair.zsh-theme",
    path      => $path,
    logoutput => true,
    require   => Exec["install oh-my-zsh"],
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

  $gvim = $distro ? {
    /(?i)(ubuntu|debian|mint) => "vim-gtk",
    /(?i)(centos|redhat)      => "vim-enhanced",
    arch                      => "gvim",
    osx                       => "mvim",
    default                   => undef,
  }

  if ($gvim) {
    package { "gvim":
      name   => $gvim,
      ensure => present,
    }

    file { "~/.vim":
      ensure  => directory,
      path    => "home_dir/.vim",
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
      command   => "git clone https://github.com/Elzair/my-vimrc.git $home_dir/.vim/my-vimrc && cp $home_dir/.vim/my-vimrc/vimrc $home_dir/.vimrc && cp $home_dir/.vim/my-vimrc/gvimrc $home_dir/.gvimrc",
      path      => $path,
      logoutput => true,
      require   => [ Package["git"], File["~/.vim"] ],
    }

    exec { "install vundle":
      command   => "git clone https://github.com/gmarik/vundle.git $home_dir/.vim/bundle/vundle",
      path      => $path,
      logoutput => true,
      require   => [ Package["git"], File["~/.vim/bundle"] ],
    }

    exec { "install vim bundles":
      command   => "vim +BundleInstall +qall",
      path      => $path,
      logoutput => true,
      require   => [ Package["gvim"], Exec["configure gvim"], Exec["install vundle"] ],
    }

  }

  $inconsolata = $distro ? {
    /(?i)(ubuntu|debian|mint) => "ttf-inconsolata",
    /(?i)(centos|redhat)      => "inconsolata-fonts",
    default                   => undef,
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
