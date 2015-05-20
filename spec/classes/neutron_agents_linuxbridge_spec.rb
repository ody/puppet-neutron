require 'spec_helper'

describe 'neutron::agents::linuxbridge' do

  let :pre_condition do
    "class { 'neutron': rabbit_password => 'passw0rd' }\n" +
    "class { 'neutron::plugins::linuxbridge': }"
  end

  let :params do
    { :physical_interface_mappings => 'physnet:eth0',
      :firewall_driver             => 'neutron.agent.linux.iptables_firewall.IptablesFirewallDriver',
      :package_ensure              => 'present',
      :enable                      => true
    }
  end

  let :default_facts do
    { :operatingsystem           => 'default',
      :operatingsystemrelease    => 'default'
    }
  end

  shared_examples_for 'neutron linuxbridge agent' do

    it { is_expected.to contain_class('neutron::params') }

    it 'configures neutron linuxbridge agent service' do
      is_expected.to contain_service('neutron-plugin-linuxbridge-service').with(
        :ensure  => 'running',
        :name    => platform_params[:linuxbridge_agent_service],
        :enable  => params[:enable]
      )
    end

    context 'with manage_service as false' do
      before :each do
        params.merge!(:manage_service => false)
      end
      it 'should not start/stop service' do
        is_expected.to contain_service('neutron-plugin-linuxbridge-service').without_ensure
      end
    end

    it 'configures linuxbridge_conf.ini' do
      is_expected.to contain_neutron_plugin_linuxbridge('LINUX_BRIDGE/physical_interface_mappings').with(
        :value => params[:physical_interface_mappings]
      )
      is_expected.to contain_neutron_plugin_linuxbridge('SECURITYGROUP/firewall_driver').with(
        :value => params[:firewall_driver]
      )
    end
  end


  context 'on Debian platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'Debian' })
    end

    let :platform_params do
      { :linuxbridge_agent_package => 'neutron-plugin-linuxbridge-agent',
        :linuxbridge_agent_service => 'neutron-plugin-linuxbridge-agent' }
    end

    it_configures 'neutron linuxbridge agent'

    it 'installs neutron linuxbridge agent package' do
      is_expected.to contain_package('neutron-plugin-linuxbridge-agent').with(
        :ensure => params[:package_ensure],
        :name   => platform_params[:linuxbridge_agent_package],
        :tag    => 'openstack'
      )
    end
  end

  context 'on RedHat platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'RedHat' })
    end

    let :platform_params do
      { :linuxbridge_server_package => 'openstack-neutron-linuxbridge',
        :linuxbridge_agent_service => 'neutron-linuxbridge-agent' }
    end

    it_configures 'neutron linuxbridge agent'

    it 'installs neutron linuxbridge package' do
      is_expected.to contain_package('neutron-plugin-linuxbridge').with(
        :ensure => params[:package_ensure],
        :name   => platform_params[:linuxbridge_server_package],
        :tag    => 'openstack'
      )
    end
  end
end
