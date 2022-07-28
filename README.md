# Tinc Image
This image adds mesh-vpn capabilities to [eons/img_base](https://github.com/eons-dev/img_base).

## Usage
To use this image, you must do 2 things:
1. mount a valid tinc directory to /etc/tinc/
2. add a `launch` directive specifying the vpn name

### Tinc Directory

A valid tinc directory should contain a "nets.boot" file which can contain the names of tinc networks or may be empty (the nets.boot file is not used by our launch system).

each tinc network (and there may be multiple) should have its own folder with the following contents:
```
/etc/tinc/
├─ nets.boot
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

#### Network Directory

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

### Launch Directive

To start tinc, use a command like: `tinc start -n network_n -D`, where "network_n" is the name of your network.
If you would like debugging info, you can add `-d 3`, etc.
See the docs for more info: https://www.tinc-vpn.org/documentation/Runtime-options.html

#### With EBBS

If using EBBS, simply add a `launch` entry for each network. This would look like:
```json
"launch":
{
    "network_n" : "tinc start -n network_n -D"
}
```

#### Without EBBS

This image builds off of [eons/img_base](https://github.com/eons-dev/img_base), which creates a launch.d directory. All the EBBS Docker Builder does is create a script in that directory, which you can do too!

Create a file named "network_n" (obviously, substitute network_n for the name of your network) and add the contents: `tinc start -n network_n -D`. That's it!
