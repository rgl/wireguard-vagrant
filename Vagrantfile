require 'ipaddr'

# to make sure the nodes are created in order, we
# have to force a --no-parallel execution.
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

NODE_FIRST_IP_ADDRESS = '192.168.53.100'
NODE_FIRST_VPN_IP_ADDRESS = '10.2.0.100'
NODES = [
  :ubuntu,
  :ubuntu,
]

def define_node(config, type, index)
  name = "node#{index}"
  fqdn = "#{name}.example.test"
  ip_address = IPAddr.new((IPAddr.new NODE_FIRST_IP_ADDRESS).to_i + index, Socket::AF_INET).to_s
  vpn_ip_address = IPAddr.new((IPAddr.new NODE_FIRST_VPN_IP_ADDRESS).to_i + index, Socket::AF_INET).to_s
  case type
  when :ubuntu
    define_ubuntu_node(config, name, fqdn, ip_address, vpn_ip_address)
  else
    raise "unknown node type #{type}"
  end
end

def define_ubuntu_node(config, name, fqdn, ip_address, vpn_ip_address)
  config.vm.define name do |config|
    config.vm.box = 'ubuntu-20.04-amd64'
    config.vm.provider 'libvirt' do |lv, config|
      lv.cpus = 2
      lv.cpu_mode = 'host-passthrough'
      lv.memory = 512
      lv.nested = true
      lv.keymap = 'pt'
      config.vm.synced_folder '.', '/vagrant', type: 'nfs', nfs_version: '4.2', nfs_udp: false
    end
    config.vm.hostname = fqdn
    config.vm.network :private_network, ip: ip_address, libvirt__forward_mode: 'none', libvirt__dhcp_enabled: false
    config.vm.provision 'shell', path: 'provision-base.sh'
    config.vm.provision 'shell', path: 'provision-wireguard.sh', args: [ip_address, vpn_ip_address]
    config.trigger.before :destroy do |trigger|
      trigger.ruby do |env, machine|
        FileUtils.rm_f("tmp/wg-peer-#{name}.conf")
      end
    end
    # update all the machines wireguard configuration with all the other peers.
    config.trigger.after :up do |trigger|
      trigger.ruby do |env, machine|
        # see https://github.com/hashicorp/vagrant/blob/v2.3.0/lib/vagrant/plugin/v2/trigger.rb
        # see https://github.com/hashicorp/vagrant/blob/v2.3.0/lib/vagrant/environment.rb
        # see https://github.com/hashicorp/vagrant/blob/v2.3.0/lib/vagrant/machine.rb
        # see https://github.com/hashicorp/vagrant/blob/v2.3.0/lib/vagrant/machine_state.rb
        # see https://github.com/hashicorp/vagrant/blob/v2.3.0/lib/vagrant/plugin/v2/communicator.rb
        env.active_machines.each do |machine_name, machine_provider|
          m = env.machine(machine_name, machine_provider)
          if m.state.id == :running
            m.ui.info('Updating WireGuard peers...')
            m.communicate.sudo('/vagrant/wg-update-peers.sh') do |type, data|
              m.ui.info(data.chomp)
            end
          end
        end
      end
    end
  end
end

Vagrant.configure(2) do |config|
  NODES.each_with_index do |type, index|
    define_node(config, type, index)
  end
end
