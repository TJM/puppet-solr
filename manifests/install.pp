# == Class: solr::install
#
# Full description of class solr here.
#
# === Parameters
#
#
# === Variables
#
#
# === Examples
#
#  class { 'solr':
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Copyright
#
# GPL-3.0+
#
class solr::install {
  
  anchor{'solr::install::begin':}
  # install requirements
  ensure_packages($solr::params::required_packages)

  ## create a solr user
  user {$solr::jetty_user:
    ensure     => present,
    home       => $solr::solr_home,
    managehome => false,
    shell      => '/bin/bash',
    require    => [ Package[$solr::params::required_packages],
                    Anchor['solr::install::begin']],
  }
  
  # download and unpackage solr
  archive { 'solr':
    ensure           => present,
    url              => "${solr::url}/${solr::version}/solr-\
${solr::version}.tgz ",
    target           => '/opt',
    follow_redirects => true,
    extension        => 'tgz',
    checksum         => false,
    timeout          => $solr::timeout,
    require          => User[$solr::jetty_user],
  }

  # copy directory
  # & delete collection 1
  exec {'copy solr':
    command     => "/bin/cp -r ${solr::solr_home_src}/example \
${solr::solr_home}",
    refreshonly => true,
    subscribe   => Archive['solr'],
  }
  
  # change permissions
  exec {'change permissions':
    command     => "/bin/chown ${solr::jetty_user}:${solr::jetty_user} -R\
 ${solr::solr_home}",
    refreshonly => true,
    subscribe   => Exec['copy solr'],
  }

  file {"${solr::solr_home}/example":
    ensure  => directory,
    owner   => $solr::jetty_user,
    group   => $solr::jetty_user,
    require => Exec['change permissions'],
  }
  
  # move collection1 to example directory
  exec {'move collection1':
    command => "/bin/mv ${solr::solr_home}/solr/collection1\
 ${solr::solr_home_example_dir}",
    creates => $solr::solr_home_example_dir,
    require => File ["${solr::solr_home}/example"],
  }

  anchor{'solr::install::end':
    require => Exec['move collection1'],
  }
}