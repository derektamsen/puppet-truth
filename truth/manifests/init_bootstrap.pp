class truth::init_bootstrap {
	
	file { "/etc/truth_tags.yml":
        ensure => present,
        mode => 600,
        owner => "root",
        group => "root",
        source => "puppet:///truth_private/truth_tags.yml"
    }

}