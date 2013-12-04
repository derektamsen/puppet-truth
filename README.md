# puppet-truth

## Overview
The puppet-truth module provides roles and tags for pre-hiera puppet (0.25.4). This is probably overly complicated and now can be easily replaced with Hiera or LDAP external facts. I wrote it as a bandaid for a larger issue but it still functions well with no editing of the main libraries.

## Requirements

- Ruby 1.8.6 installed on both the clients and server. (puppet-truth is rather old and may not work on 1.9)
- Facter installed on all clients.
- Puppet installed an running on both the master and clients.

## Installation
- `pluginsync=true` needs to be set on the clients and master in `/etc/puppet/puppet.conf`.
- In `/etc/puppet/fileserver.conf` define a private file path to store client's truth files. _You will want to update the `allow` directive for your internal ip ranges._

```
[truth_private]
    path /etc/puppet/modules/truth/files/private/%d/%h
    allow 192.168.0.0/24
```
- Include the `truth` folder from this repo inside your `/etc/puppet/modules` directory.
- In `nodes.pp` define either a default include or a regex pattern for hosts to `include truth`.
- Under `truth/files/private` create a folder named after the domain your systems are under. If for example my hosts were server1.google.com and server2.google.com, I would create the folders `truth/files/private/google.com/server1` and `truth/files/private/google.com/server2`.

_Note: If your puppetmaster is not accessible via 'https://puppet:8140' you will need to update `truth/lib/facter/load_truth_tags.rb:69`_

## Defining Roles
To define a role you would edit `truth/manifests/init.pp`. Essentially, you would call the function `truth_tag()` to check if the host has a tag defined on it.

- The following example would print "I am a loadbalancer" on all servers with the loadbalancer role.

```
if truth_tag('role', 'loadbalancer') {
    notice("I am a loadbalancer")
}
```

## Assigning Roles to hosts
To define a role to a host simple create a `truth_tags.yml` file in the private file server under the "truth" module.

- Ensure, a folder is created for the domain your hosts are registered in. The folder will need to be created under `truth/files/private/example.com`
- Next, create a folder for your hosts under `truth/files/private/example.com`. The folder name is just the host's name and not its FQDN.
- Now edit the truth tag file for the host that needs to be changed. The file is called `truth_tags.yml` which is located under `truth/files/private/example.com/hostname/`.
- `truth_tags.yml` uses a yaml format. You should be able to see some examples in `truth/files/private/example.com/server1/truth_tags.yml` and `truth/files/private/example_truth_tags.yml`. You should at a minimum have the following:

```
---
role:
    - somerolename
```
_For the most part the file is free form and is essentially parsed into factor as values._

## How does a client get tags?
- On a client puppet run facter is first called. Facter calls the library `load_truth_tags.rb`. The script first checks to see if `/etc/truth_tags.yml` exists already.
    - If `truth_tags.yml` exists it md5 sums the file. Then it calls the puppet https api and asks for the server's private truth_tag file md5 sum. It then compares the sum of the file on disk and the one on the server. If it is the same it uses the one on disk. If not it downloads the file from the puppetmaster.
    - If the file does not exist on the client it downloads the file from the puppetmaster.
- Facter then loads in `/etc/truth_tags.yml` as facts. These are then sent to the puppetmaster and used to populate variables.
- The "truth::init" manifest then calls the `truth_tag.rb` function on the server to set true or false in if statements. The if statements then can include other puppet modules based on facts.

## Credit
I would like to thank @jordansissel for the inspiration to make the modification to his excellent [truth::enforcer](https://github.com/jordansissel/puppet-examples/tree/master/nodeless-puppet/ "truth::enforcer") module. I added a few features that allows the tags to work with a puppetmaster distribution. I also added the ability for facter to dynamically check and add facts from the `truth_tags.yml` file instead of setting them on each host.
