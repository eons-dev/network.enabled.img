#!/bin/bash

# Calculated vars
# thisDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
thisDir="$(pwd)"

# Default vars
ip="0.0.0.0"
host=$host
network="tinc"
port="655"
cidr="/24"
netmask="255.255.255.0" # TODO: determine netmask automatically from cidr.
mode="switch"

usage()
{
    echo "usage: ${BASH_SOURCE[0]} ip [host] [network] [cidr netmask] [mode] [auto]"
    echo "If you would like your hosts files automatically populated,\
 please place existing host files in ${thisDir}/network/hosts/"
    echo ""
    echo "Generates config files for a tinc network. Will install tinc if it does not exist but will not start it on this machine."
    echo ""
    echo "   Arguments: "
    echo "      ip: the ip for this host; REQUIRED"
    echo "      host: the fqdn for this host; OPTIONAL, default = ${host}"
    echo "      network: the name of your tinc network;\
 OPTIONAL, default = ${network}"
    echo "      cidr: network cidr; OPTIONAL, default = ${cidr}"
    echo "      netmask: MUST CORRELTATE WITH CIDR;\
 OPTIONAL default = ${netmask}"
    echo "      mode: tinc mode. See https://www.tinc-vpn.org/documentation-1.1/Main-configuration-variables.html"
    echo "      auto: anything extra (e.g. 'y')\
 will cause this script to proceed without prompting."
    echo ""
    echo "   Dependencies: apt"
    echo "      Everything else will be installed"
    echo ""
    echo "   Example: ./tinc-setup.sh 10.0.0.1 example.com foo /16 255.255.0.0"
    echo "      this will use the ./foo/hosts/ folder."
    echo ""
    exit 1
}

# Prints error message and usage, then exits
# ARGUMENTS: error_message
error()
{
    echo "ERROR: $1"
    echo ""
    usage
}

#TODO: the following need type checking.

if [ $1 == "-h" ]; then
    usage
fi

if [ -z $1 ]; then
    error "Please specify an ip"
else
    ip=$1
fi

if [ ! -z $2 ]; then
    host=$2
fi

if [ ! -z $3 ]; then
    network=$3
fi

if [ ! -z $4 ]; then
    if [ ! -z $5 ]; then
        cidr=$4
        netmask=$5
    else
        error "Please specify both the netmask and cidr.\
 Yes this is dumb. We'll fix it in a future release."
    fi
fi

if [ ! -z $6 ]; then
    mode=$6
fi

# Extrapolated variables
device=$network
ipCidr="${ip}${cidr}"
# hosts=$(ls $thisDir/$network/hosts/)

echo "We're all set! Here's what we got:"
echo "    host = ${host}"
echo "    ip = ${ip}"
echo "    network = ${network}"
echo "    port = ${port}"
echo "    cidr = ${cidr}"
echo "    netmask = ${netmask}"
echo "    device = ${device}"
echo "    ipCidr = ${ipCidr}"
echo "    mode = ${mode}"
echo ""
if [ -z $7 ]; then
    echo "Once we start, everything will be automated."
    read -p "Continue? [y/n] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

echo "Let's go!"

echo "Making sure tinc is installed"
if ! command -v tinc &> /dev/null; then
    echo "tinc could not be found. Installing..."
    apt install -y\
 build-essential\
 libncurses5-dev\
 libreadline-dev\
 liblzo2-dev\
 libz-dev\
 libssl-dev texinfo
    
    if [ ! -d tinc-1.1pre17 ]; then
        wget https://www.tinc-vpn.org/packages/tinc-1.1pre17.tar.gz
        tar xzf tinc-1.1pre17.tar.gz
    fi
    cd tinc-1.1pre17/
    ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var
    make
    make install
    tincd --version
    if ! command -v tinc &> /dev/null; then
        echo "Install failed."
        exit
    fi
fi


echo "Removing any conflicting files"
rm -rfv /etc/tinc/${network}

# Then create directory
mkdir -p /etc/tinc/${network}/hosts

echo "Creating tinc.conf"
cat << EOF >> /etc/tinc/${network}/tinc.conf
Name = ${host}
AddressFamily = ipv4
Interface = ${device}
Mode = ${mode}
Port = ${port}
AutoConnect = yes

EOF
#NOTE: that last empty line is important.

echo "Creating host file for $host"
#echo "Address =\
# `dig TXT +short o-o.myaddr.l.google.com @ns1.google.com |\
# awk -F'"' '{ print $2}'`" >> /etc/tinc/$network/hosts/$host
cat << EOF > /etc/tinc/${network}/hosts/${host}
Address = ${host}
Subnet = ${ip}/32
Port = ${port}
EOF
echo "Generating keys"

# 4 returns to accept key defaults.
tinc -n $network generate-keys 4096 << END




END

echo "Creating tinc-up"
cat << EOF > /etc/tinc/${network}/tinc-up
#!/bin/sh
ip link set dev \$INTERFACE up
ip addr add ${ipCidr} dev \$INTERFACE
EOF

echo "Creating tinc-down"
cat << EOF > /etc/tinc/${network}/tinc-down
#!/bin/sh
ip link set dev \$INTERFACE down
EOF

chmod 755 /etc/tinc/${network}/tinc-*

echo "done."
