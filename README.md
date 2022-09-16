# Network Enabled Image
This image adds networking capabilities to [eons/img_base](https://github.com/eons-dev/img_base).

So far, this image only includes `tinc` as the network provider.
[Tinc](https://www.tinc-vpn.org/) provides mesh-vpn that is fast, secure, and reliable.

## Limitations

### Requires Privileges

Networking with Docker is not trivial. Do not expect to be able to run this image on your infrastructure without modification. We use [img_host](https://github.com/infrastructure-tech/img_host) to run this and our other images which require kernel modules and "hardware access".


### Limited Ports

This image exposes ONLY port 655. If you would like to use a different port or multiple ports, you must fork this and add your `EXPOSE` directives.

## Networks

### Tinc

#### Usage
To use `tinc`, you must do 1 thing: mount a valid tinc directory to /etc/tinc/

##### Tinc Directory

**TL;DR:** In the /util/ folder, you will find a mktinc.sh script which will create a tinc directory for you.  
NOTE: you can also use [the similar server deployment script](https://github.com/eons-dev/server_deploy/blob/main/install/mktinc.sh) on any machines you wish to connect to a tinc host using this image.

Each tinc network (and there may be multiple) should have its own folder with the following contents:
```
/etc/tinc/
├─ nets.boot (optional)
├─ network_1/
│  ├─ ed25519_key.priv
│  ├─ rsa_key.priv
│  ├─ tinc-up
│  ├─ tinc-down
│  ├─ tinc.conf
│  ├─ hosts
│  │  ├─ host_1
│  │  ├─ host_2
│  │  ├─ ...
│  │  ├─ host_n
├─ network_2/
│  ├─ ed25519_key.priv
│  ├─ rsa_key.priv
│  ├─ tinc-up
│  ├─ tinc-down
│  ├─ tinc.conf
│  ├─ hosts
│  │  ├─ host_1
│  │  ├─ host_2
│  │  ├─ ...
│  │  ├─ host_n
├─ ...
├─ network_n
```

NOTE: the tinc directory may contain a "nets.boot" file which can contain the names of tinc networks or may be empty. The nets.boot file is not used by our launch system.

**SEE LIMITATIONS (above) REGARDING MULTIPLE NETWORKS**

##### Network Directory

Each network should have its own directory where the name of the directory (above: "network_n") is the name of the network (e.g. "network_n" gets renamed to "eons").

Inside each network directory, there should be 2 private keys for the current node. These keys are not to be shared.

The tinc-* scripts should be as follows but can be modified however you'd like:

**tinc-up**:
```shell
#!/bin/sh
ip link set dev $INTERFACE up
ip addr add IP_ADDRESS/SUBNET dev $INTERFACE
```

IMPORTANT: CHANGE ONLY `IP_ADDRESS/SUBNET`!  
do not change `$INTERFACE`

**tinc-down**:
```shell
#!/bin/sh
ip link set dev $INTERFACE down
```

tinc-down requires no configuration.

The tinc.conf file is where the majority of configuration is done.
It will generally look something like:
```shell
Name = HOSTNAME
AddressFamily = ipv4
Interface = network_n
Mode = switch
Port = 655
AutoConnect = yes
ConnectTo = host_1
ConnectTo = host_2
ConnectTo = ...
ConnectTo = host_n
```

Make sure to change `HOSTNAME`, `network_n`, the `host_`s and any other values you need.

For more on tinc configuration, see the docs: https://www.tinc-vpn.org/documentation/tinc.conf.5

##### Hosts Directory

Each host you'd like to `ConnectTo` and the current node must have a file in the hosts directory.
These files are named the same as the hostname of the target machine and have contents like:
```shell
Address = IP_ADDRESS
Subnet = IP_ADDRESS/SUBNET
Port = 655
-----BEGIN RSA PUBLIC KEY-----
...
-----END RSA PUBLIC KEY-----
Ed25519PublicKey = ...
```

These files should be automatically generated when installing tinc but can be manually created as long as the public keys match the private keys of the node.

For a full list of host configuration variables, see the docs: https://www.tinc-vpn.org/documentation/Host-configuration-variables.html

