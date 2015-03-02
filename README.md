coreos_dev
==========

To use this repository, you must deploy your CoreOS instance using the provided
`user-data` file. Once this is done, you should be able to deploy the systemd
services in the `services` directory.

An example of getting this working with [coreos-vagrant][coreos-vagrant], can be
found below.


coreos-vagrant example
----------------------

First clone [coreos-vagrant][coreos-vagrant], and configure it to start 3
nodes by editing the line that says `#$num_instances=1` to say
`$num_instances=3`. Make sure you remove the `#` comment symbol.

```
git clone git@github.com:coreos/coreos-vagrant.git
cd coreos-vagrant
cp config.rb.sample config.rb
vi config.rb
```

Then copy the user-data file from this directory into your `coreos-vagrant`
directory.

```
cp /path/to/coreos_dev/user-data /path/to/coreos-vagrant/user-data
```

Then start the cluster:

```
vagrant up
```

This will take a minute, because you'll be bootstrapping 3 clusters which
all have a few resources they need to pull down from the internet. Once
`fleetctl list-machines` shows all 3 machines, things should be ready.



Starting services with Fleet
----------------------------

Starting services with Fleet is easy. Simply look for the service you want to
start in the `services` directory, and run `fleetctl start services/<some.service>`

Example:

```
fleetctl start elasticsearch@1.service
fleetctl start kibana@1.service
```

### Notes:

An important thing to note right now is that elasticsearch discovery is done
using etcd, and is prone to race conditions. It's best to start the elasticsearch
services one at a time, waiting for one to finish before starting the next.
Additionally, right now the particular elasticsearch service running isnt
tied to the same node, which can cause serious issues with a large, but works
fine for development. This is on my list of things to fix.


[coreos-vagrant]: https://github.com/coreos/coreos-vagrant
