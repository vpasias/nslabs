#!/bin/bash
#

cat > /mnt/extra/management.xml <<EOF
<network>
  <name>management</name>
  <forward mode='nat'/>
  <bridge name='virbr255' stp='on' delay='0'/>
  <mac address='52:54:00:8a:8b:cd'/>
  <ip address='192.168.255.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.255.2' end='192.168.255.254'/>
      <host mac='52:54:00:8a:8b:c1' name='netsim' ip='192.168.255.100'/>
    </dhcp>
  </ip>
</network>
EOF

virsh net-define /mnt/extra/management.xml && virsh net-autostart management && virsh net-start management && virsh net-list --all

./kvm-install-vm create -c 48 -m 200704 -d 800 -t ubuntu2004 -f host-passthrough -k /root/.ssh/id_rsa.pub -l /mnt/extra/virt/images -L /mnt/extra/virt/vms -b virbr255 -T US/Eastern -M 52:54:00:8a:8b:c1 netsim

virsh list --all && brctl show && virsh net-list --all

sleep 90

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "uname -a && sudo ip a"

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim 'echo "root:gprm8350" | sudo chpasswd'
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim 'echo "ubuntu:kyax7344" | sudo chpasswd' 
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config" 
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo systemctl restart sshd"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo rm -rf /root/.ssh/authorized_keys"

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "cat << EOF | sudo tee /etc/modprobe.d/qemu-system-x86.conf
options kvm_intel nested=1
EOF"

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "cat << EOF | sudo tee /etc/sysctl.conf
net.ipv4.ip_forward=1
net.ipv4.conf.all.forwarding=1
net.ipv6.conf.all.forwarding=1
net.mpls.conf.lo.input=1
net.mpls.conf.ens3.input=1
net.mpls.platform_labels=100000
net.ipv4.tcp_l3mdev_accept=1
net.ipv4.udp_l3mdev_accept=1
EOF"

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "cat << EOF | sudo tee /etc/sysctl.d/60-lxd-production.conf
fs.inotify.max_queued_events=1048576
fs.inotify.max_user_instances=1048576
fs.inotify.max_user_watches=1048576
vm.max_map_count=262144
kernel.dmesg_restrict=1
net.ipv4.neigh.default.gc_thresh3=8192
net.ipv6.neigh.default.gc_thresh3=8192
net.core.bpf_jit_limit=3000000000
kernel.keys.maxkeys=2000
kernel.keys.maxbytes=2000000
EOF"

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "cat << EOF | sudo tee /etc/modules-load.d/modules.conf
mpls_router
mpls_gso
mpls_iptunnel
EOF"

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo apt update -y && sudo apt install vim git wget net-tools locate -y"

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo apt update && sudo apt upgrade -y"

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo DEBIAN_FRONTEND=noninteractive apt-get install linux-generic-hwe-20.04 --install-recommends -y"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo apt autoremove -y && sudo apt --fix-broken install -y"

#ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "curl -O https://releases.hashicorp.com/vagrant/2.2.8/vagrant_2.2.8_x86_64.deb && sudo apt install -y ./vagrant_2.2.8_x86_64.deb --allow-downgrades"

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo apt update && sudo apt -y install apt-transport-https ca-certificates curl software-properties-common"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim 'sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"'
#ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo apt update -y && sudo apt install vagrant -y"

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo apt install software-properties-common -y && sudo add-apt-repository ppa:deadsnakes/ppa -y && sudo apt update -y"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo apt install python3.9 python3.9-dev python3.9-distutils -y"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo apt install python3.8 python3.8-dev -y"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo apt-get update && sudo apt-get install -y python3-pip"
#ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo python3.9 -m pip install netsim-tools"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo python3.8 -m pip install netsim-tools"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "netlab install ubuntu ansible libvirt -y -q"

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim 'sudo apt install apt-transport-https ca-certificates -y && sudo apt install -y curl software-properties-common && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" && sudo apt update -y && sudo apt-cache policy docker-ce && sudo apt install -y docker-ce && sleep 10 && bash -c "$(curl -sL https://get-clab.srlinux.dev)"'

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo usermod -aG libvirt ubuntu && sudo adduser ubuntu libvirt-qemu && sudo adduser ubuntu kvm && sudo adduser ubuntu libvirt-dnsmasq && sudo adduser ubuntu docker && echo 0 | sudo tee /sys/module/kvm/parameters/halt_poll_ns"
#ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo sed -i 's/0770/0777/' /etc/libvirt/libvirtd.conf && echo 'security_driver = none' | sudo tee /etc/libvirt/qemu.conf"

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "ansible-galaxy collection install nokia.grpc && sudo python3.9 -m pip install google-cloud && sudo python3.9 -m pip install google-cloud-vision"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "ansible-galaxy collection install nokia.grpc && sudo python3.8 -m pip install google-cloud && sudo python3.8 -m pip install google-cloud-vision"

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "vagrant box add vpasias/verouter && vagrant box add vpasias/cirouter && vagrant box add vpasias/routeros"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "mv /home/ubuntu/.vagrant.d/boxes/vpasias-VAGRANTSLASH-verouter/ /home/ubuntu/.vagrant.d/boxes/arista-VAGRANTSLASH-veos/"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "mv /home/ubuntu/.vagrant.d/boxes/vpasias-VAGRANTSLASH-cirouter/ /home/ubuntu/.vagrant.d/boxes/cisco-VAGRANTSLASH-iosv/"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "mv /home/ubuntu/.vagrant.d/boxes/vpasias-VAGRANTSLASH-routeros/ /home/ubuntu/.vagrant.d/boxes/mikrotik-VAGRANTSLASH-chr/"

#ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo sed -i 's/no ip domain-lookup/no ip domain lookup/' /usr/local/lib/python3.9/dist-packages/netsim/ansible/templates/initial/ios.j2"
#ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo sed -i '1i service routing protocols model ribd' /usr/local/lib/python3.9/dist-packages/netsim/ansible/templates/initial/eos.j2"
#ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo sed -i '2i !' /usr/local/lib/python3.9/dist-packages/netsim/ansible/templates/initial/eos.j2"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo sed -i 's/no ip domain-lookup/no ip domain lookup/' /usr/local/lib/python3.8/dist-packages/netsim/ansible/templates/initial/ios.j2"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo sed -i '1i service routing protocols model ribd' /usr/local/lib/python3.8/dist-packages/netsim/ansible/templates/initial/eos.j2"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo sed -i '2i !' /usr/local/lib/python3.8/dist-packages/netsim/ansible/templates/initial/eos.j2"

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo reboot"

sleep 60

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo ip a"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "uname -a"

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "mkdir -p /home/ubuntu/tmp"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "cat << EOF | tee /home/ubuntu/tmp/vagrant-libvirt.xml
<network>
  <name>vagrant-libvirt</name>
  <uuid>7ed704dd-3901-452c-91d0-58ad75901b1d</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr1' stp='on' delay='0'/>
  <mac address='52:54:00:d8:3f:0d'/>
  <ip address='192.168.121.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.121.2' end='192.168.121.99'/>
      <host mac='08:4F:A9:00:00:01' ip='192.168.121.101'/>
      <host mac='08:4F:A9:00:00:02' ip='192.168.121.102'/>
      <host mac='08:4F:A9:00:00:03' ip='192.168.121.103'/>
      <host mac='08:4F:A9:00:00:04' ip='192.168.121.104'/>
      <host mac='08:4F:A9:00:00:05' ip='192.168.121.105'/>
      <host mac='08:4F:A9:00:00:06' ip='192.168.121.106'/>
      <host mac='08:4F:A9:00:00:07' ip='192.168.121.107'/>
      <host mac='08:4F:A9:00:00:08' ip='192.168.121.108'/>
      <host mac='08:4F:A9:00:00:09' ip='192.168.121.109'/>
      <host mac='08:4F:A9:00:00:0A' ip='192.168.121.110'/>
      <host mac='08:4F:A9:00:00:0B' ip='192.168.121.111'/>
      <host mac='08:4F:A9:00:00:0C' ip='192.168.121.112'/>
      <host mac='08:4F:A9:00:00:0D' ip='192.168.121.113'/>
      <host mac='08:4F:A9:00:00:0E' ip='192.168.121.114'/>
      <host mac='08:4F:A9:00:00:0F' ip='192.168.121.115'/>
      <host mac='08:4F:A9:00:00:10' ip='192.168.121.116'/>
      <host mac='08:4F:A9:00:00:11' ip='192.168.121.117'/>
      <host mac='08:4F:A9:00:00:12' ip='192.168.121.118'/>
      <host mac='08:4F:A9:00:00:13' ip='192.168.121.119'/>
      <host mac='08:4F:A9:00:00:14' ip='192.168.121.120'/>
      <host mac='08:4F:A9:00:00:15' ip='192.168.121.121'/>
      <host mac='08:4F:A9:00:00:16' ip='192.168.121.122'/>
      <host mac='08:4F:A9:00:00:17' ip='192.168.121.123'/>
      <host mac='08:4F:A9:00:00:18' ip='192.168.121.124'/>
      <host mac='08:4F:A9:00:00:19' ip='192.168.121.125'/>
      <host mac='08:4F:A9:00:00:1A' ip='192.168.121.126'/>
      <host mac='08:4F:A9:00:00:1B' ip='192.168.121.127'/>
      <host mac='08:4F:A9:00:00:1C' ip='192.168.121.128'/>
      <host mac='08:4F:A9:00:00:1D' ip='192.168.121.129'/>
      <host mac='08:4F:A9:00:00:1E' ip='192.168.121.130'/>
      <host mac='08:4F:A9:00:00:1F' ip='192.168.121.131'/>
      <host mac='08:4F:A9:00:00:20' ip='192.168.121.132'/>
      <host mac='08:4F:A9:00:00:21' ip='192.168.121.133'/>
      <host mac='08:4F:A9:00:00:22' ip='192.168.121.134'/>
      <host mac='08:4F:A9:00:00:23' ip='192.168.121.135'/>
      <host mac='08:4F:A9:00:00:24' ip='192.168.121.136'/>
      <host mac='08:4F:A9:00:00:25' ip='192.168.121.137'/>
      <host mac='08:4F:A9:00:00:26' ip='192.168.121.138'/>
      <host mac='08:4F:A9:00:00:27' ip='192.168.121.139'/>
      <host mac='08:4F:A9:00:00:28' ip='192.168.121.140'/>
      <host mac='08:4F:A9:00:00:29' ip='192.168.121.141'/>
      <host mac='08:4F:A9:00:00:2A' ip='192.168.121.142'/>
      <host mac='08:4F:A9:00:00:2B' ip='192.168.121.143'/>
      <host mac='08:4F:A9:00:00:2C' ip='192.168.121.144'/>
      <host mac='08:4F:A9:00:00:2D' ip='192.168.121.145'/>
      <host mac='08:4F:A9:00:00:2E' ip='192.168.121.146'/>
      <host mac='08:4F:A9:00:00:2F' ip='192.168.121.147'/>
      <host mac='08:4F:A9:00:00:30' ip='192.168.121.148'/>
      <host mac='08:4F:A9:00:00:31' ip='192.168.121.149'/>
      <host mac='08:4F:A9:00:00:32' ip='192.168.121.150'/>
      <host mac='08:4F:A9:00:00:33' ip='192.168.121.151'/>
      <host mac='08:4F:A9:00:00:34' ip='192.168.121.152'/>
      <host mac='08:4F:A9:00:00:35' ip='192.168.121.153'/>
      <host mac='08:4F:A9:00:00:36' ip='192.168.121.154'/>
      <host mac='08:4F:A9:00:00:37' ip='192.168.121.155'/>
      <host mac='08:4F:A9:00:00:38' ip='192.168.121.156'/>
      <host mac='08:4F:A9:00:00:39' ip='192.168.121.157'/>
      <host mac='08:4F:A9:00:00:3A' ip='192.168.121.158'/>
      <host mac='08:4F:A9:00:00:3B' ip='192.168.121.159'/>
      <host mac='08:4F:A9:00:00:3C' ip='192.168.121.160'/>
      <host mac='08:4F:A9:00:00:3D' ip='192.168.121.161'/>
      <host mac='08:4F:A9:00:00:3E' ip='192.168.121.162'/>
      <host mac='08:4F:A9:00:00:3F' ip='192.168.121.163'/>
      <host mac='08:4F:A9:00:00:40' ip='192.168.121.164'/>
      <host mac='08:4F:A9:00:00:41' ip='192.168.121.165'/>
      <host mac='08:4F:A9:00:00:42' ip='192.168.121.166'/>
      <host mac='08:4F:A9:00:00:43' ip='192.168.121.167'/>
      <host mac='08:4F:A9:00:00:44' ip='192.168.121.168'/>
      <host mac='08:4F:A9:00:00:45' ip='192.168.121.169'/>
      <host mac='08:4F:A9:00:00:46' ip='192.168.121.170'/>
      <host mac='08:4F:A9:00:00:47' ip='192.168.121.171'/>
      <host mac='08:4F:A9:00:00:48' ip='192.168.121.172'/>
      <host mac='08:4F:A9:00:00:49' ip='192.168.121.173'/>
      <host mac='08:4F:A9:00:00:4A' ip='192.168.121.174'/>
      <host mac='08:4F:A9:00:00:4B' ip='192.168.121.175'/>
      <host mac='08:4F:A9:00:00:4C' ip='192.168.121.176'/>
      <host mac='08:4F:A9:00:00:4D' ip='192.168.121.177'/>
      <host mac='08:4F:A9:00:00:4E' ip='192.168.121.178'/>
      <host mac='08:4F:A9:00:00:4F' ip='192.168.121.179'/>
      <host mac='08:4F:A9:00:00:50' ip='192.168.121.180'/>      
      <host mac='52:54:00:7A:00:01' ip='192.168.121.200'/>
      <host mac='52:54:00:05:00:01' ip='192.168.121.201'/>
    </dhcp>
  </ip>
</network>
EOF"

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "virsh net-undefine vagrant-libvirt && virsh net-define /home/ubuntu/tmp/vagrant-libvirt.xml && virsh net-start vagrant-libvirt && virsh net-autostart vagrant-libvirt && virsh net-list && brctl show"
