$baseDir = "$PSScriptRoot"

ipmo $baseDir\libs\calico\calico.psm1

## Cluster configuration:

# KUBE_NETWORK should be set to a regular expression that matches the HNS network(s) used for pods.
# The default, "Calico.*", is correct for Calico CNI. 
$env:KUBE_NETWORK = "Calico.*"

# Set to match your Kubernetes service CIDR.
$env:K8S_SERVICE_CIDR = "10.96.0.0/12"
$env:DNS_NAME_SERVERS = "10.96.0.10"
$env:DNS_SEARCH = "svc.cluster.local"
# Set this to one of the following values:
# - "vxlan" for Calico VXLAN networking
# - "windows-bgp" for Calico BGP networking using the Windows BGP router.
# - "none" to disable the Calico CNI plugin (so that you can use another plugin).


# Hardcoded bc this is supposed to be the single source of truth...
$env:CALICO_NETWORKING_BACKEND="vxlan"
$env:CALICO_DATASTORE_TYPE = "kubernetes"

$env:KUBECONFIG = "C:/etc/kubernetes/kubelet.conf"
$env:CNI_BIN_DIR = "C:/opt/cni/bin"
$env:CNI_CONF_DIR = "C:/etc/cni/net.d"


## Datastore configuration:

# Set this to "kubernetes" to use the kubernetes datastore, or "etcdv3" for etcd.

if (-not (Test-Path $env:KUBECONFIG)) { 
    Write-Output "config.ps1 ~ Didn't find a KUBECONFIG env var... exiting."
    exit 1
}


Write-Output "kubeconfig for calico will be ~ $env:KUBECONFIG ... DATE ===> "
Get-Date
# For the "etcdv3" datastore only: set ETCD_ENDPOINTS, format: "http://<host>:<port>,..."
$env:ETCD_ENDPOINTS = "<your etcd endpoints>"
# For etcd over TLS, set these lines to point to your keys/certs:
$env:ETCD_KEY_FILE = "<your etcd key>"
$env:ETCD_CERT_FILE = "<your etcd cert>"
$env:ETCD_CA_CERT_FILE = "<your etcd ca cert>"


## CNI configuration, only used for the "vxlan" networking backends.

# Place to install the CNI plugin to.  Should match kubelet's --cni-bin-dir.

Write-Output "2.1 Checking CNI_BIN_DIR variable [ $env:CNI_BIN_DIR ] "

if (-not (Test-Path env:CNI_BIN_DIR)) { 
    Write-Output "GUESSING CNI_BIN_DIR  "

    if (Get-IsContainerdRunning)
    {
        $env:CNI_BIN_DIR = Get-ContainerdCniBinDir
    } else {
        $env:CNI_BIN_DIR = "c:\k\cni" 
    }
}

Write-Output "2.2 Checking CNI_CONF_DIR variable [ $env:CNI_CONF_DIR ] "

if (-not (Test-Path env:CNI_CONF_DIR)) { 
    
    Write-Output "GUESSING CNI_CONF_DIR  "

    if (Get-IsContainerdRunning)
    {
        $env:CNI_CONF_DIR = Get-ContainerdCniConfDir
    } else {
        $env:CNI_CONF_DIR = "c:\k\cni\config" 
    }
}

Write-Output "3.1 *final* CNI_BIN_DIR -> $env:CNI_BIN_DIR"
Write-Output "3.2 *final* CNI_CONF_DIR -> $env:CNI_CONF_DIR"

$env:CNI_CONF_FILENAME = "10-calico.conf"
# IPAM type to use with Calico's CNI plugin.  One of "calico-ipam" or "host-local".
$env:CNI_IPAM_TYPE = "calico-ipam"

## VXLAN-specific configuration.

# The VXLAN VNI / VSID.  Must match the VXLANVNI felix configuration parameter used
# for Linux nodes.
$env:VXLAN_VNI = "4096"
# Prefix used when generating MAC addresses for virtual NICs.
$env:VXLAN_MAC_PREFIX = "0E-2A"
# Network Adapter used on VXLAN, leave blank for primary NIC.
$env:VXLAN_ADAPTER = (Get-NetIPAddress -IPAddress '10.20.30.11').InterfaceAlias


## Node configuration.

# The NODENAME variable should be set to match the Kubernetes Node name of this host.
# The default uses this node's hostname (which is the same as kubelet).
#
# Note: on AWS, kubelet is often configured to use the internal domain name of the host rather than
# the simple hostname, for example "ip-172-16-101-135.us-west-2.compute.internal".
$env:NODENAME = $(hostname).ToLower()
# Similarly, CALICO_K8S_NODE_REF should be set to the Kubernetes Node name.  When using etcd,
# the Calico kube-controllers pod will clean up Calico node objects if the corresponding Kubernetes Node is
# cleaned up.
$env:CALICO_K8S_NODE_REF = $env:NODENAME

# The time out to wait for a valid IP of an interface to be assigned before initialising Calico
# after a reboot.
$env:STARTUP_VALID_IP_TIMEOUT = 90

# The IP of the node; the default will auto-detect a usable IP in most cases.
$env:IP = "autodetect"

## Logging.

$env:CALICO_LOG_DIR = "$PSScriptRoot\logs"

# Felix logs to screen at info level by default.  Uncomment this line to override the log
# level.  Alternatively, (if this is commented out) the log level can be controlled via
# the FelixConfiguration resource in the datastore.
# $env:FELIX_LOGSEVERITYSCREEN = "info"
# Disable logging to file by default since the service wrapper will redirect our log to file.
$env:FELIX_LOGSEVERITYFILE = "none"
# Disable syslog logging, which is not supported on Windows.
$env:FELIX_LOGSEVERITYSYS = "none"
# confd logs to screen at info level by default.  Uncomment this line to override the log
# level.
#$env:BGP_LOGSEVERITYSCREEN = "debug"

# for calico node....
$env:KUBECONFIG = "C:/etc/kubernetes/kubelet.conf"
