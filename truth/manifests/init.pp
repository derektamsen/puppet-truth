class truth inherits truth::init_bootstrap {
    
    # Now conditionally include things based on properties and facts
    # This is done by calling the function:
    #      truth_tag("namespace", "predicate, "value")
    # If you are testing true or false values you can leave off the last
    # position in the array and we will take care of things automatically
    # you can also do fun things like the opposite of an opposite if you like.
    #        (but please don't!)

    if truth_tag('role', 'loadbalancer') {
        #include logrotate
        notice("I am a loadbalancer")
    } 
    else {
        notice("I am NOT a loadbalancer")
    }

    if truth_tag('role', 'db') {
        #include logrotate
        notice("I am a database")
    }
    else {
        notice("I am NOT a database")
    }

    ## Practical hadoop example --
    # You can even have logic here to reject configurations you 
    # say are invalid.
    if truth_tag('role', 'hadoop-worker') and truth_tag('role', 'hadoop-master') {
        fail("Cannot be both hadoop-worker and hadoop-master. \$server_tags is '$server_tags'")
    }

    # All non-hadoop machines should get a special config that makes them able to
    # send jobs to the hadoop cluster.
    if !truth_tag('role', 'hadoop-worker') and !truth_tag('role', 'hadoop-master') {
        notice("I am a hadoop client by force")
    }

    if truth_tag('role', 'hadoop-worker') {
        notice("I am a hadoop-worker")
    }
    else {
        notice("I am not a hadoop-worker")
    }

    if truth_tag('role', 'hadoop-master') {
        notice("I am a hadoop-master")
    }
    else {
        notice("I am not a hadoop-master")
    }

    # Location awareness
    if truth_tag('loc', 'city', 'sf') {
        notice("system is located in San Francisco, CA")	
    }
    else {
        notice("We are lost!!")
    }

    # Anti-classes example to remove roles
    # if !truth_tag("role", "frontend") and !truth_tag("role", "monitor") {
    #     include apache::remove
    # }
    #
    # WHEN we have something like this under modules/apache/manifests/remove.pp:
    #
    # This is the 'anticlass' for apache
    # class apache::remove {
    #   package {
    #     "apache2": ensure => absent;
    #   }
    # 
    #   file {
    #     # Remove any leftover config files.
    #     "/etc/apache2":
    #       ensure => absent,
    #       force => true;
    # 
    #     # Remove any leftover apache logs.
    #     "/var/log/apache2":
    #       ensure => absent,
    #       force => true;
    #   }
    # }


}
