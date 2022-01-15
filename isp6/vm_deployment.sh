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

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "curl -O https://releases.hashicorp.com/vagrant/2.2.8/vagrant_2.2.8_x86_64.deb && sudo apt install -y ./vagrant_2.2.8_x86_64.deb --allow-downgrades"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo apt-get update && sudo apt-get install -y python3-pip"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo python3 -m pip install netsim-tools"
ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "netlab install ubuntu ansible libvirt -y -q"

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim 'sudo apt install apt-transport-https ca-certificates -y && sudo apt install -y curl software-properties-common && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" && sudo apt update -y && sudo apt-cache policy docker-ce && sudo apt install -y docker-ce && sleep 10 && bash -c "$(curl -sL https://get-clab.srlinux.dev)"'

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo usermod -aG libvirt ubuntu && sudo adduser ubuntu libvirt-qemu && sudo adduser ubuntu kvm && sudo adduser ubuntu libvirt-dnsmasq && sudo sed -i 's/0770/0777/' /etc/libvirt/libvirtd.conf && echo 0 | sudo tee /sys/module/kvm/parameters/halt_poll_ns && echo 'security_driver = none' | sudo tee /etc/libvirt/qemu.conf && sudo adduser ubuntu docker"

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "ansible-galaxy collection install nokia.grpc && pip install google-cloud && pip install google-cloud-vision"

ssh -o "StrictHostKeyChecking=no" ubuntu@netsim "sudo reboot"
