#!/usr/bin/ruby
#
# Author: Sergio Pena
#
#
# Script to create demo enterprise on Abiquo 2.3
#
# * Prerequisites
# - A datacenter with kinton id configured on this file must exist on Abiquo
# - A public IP network must be created on Abiquo.
#
# * Funtions
# - It will create an enterprise with
# -- User "enterprisename_user"
# -- Enterprise admin "enteprisename_admin"
# -- One defaultVDC
# -- It will purchase one public IP to the default VDC
# -- Persist enterprise name, public IP consumed and creation date into sqlite database
#
# - When called to purge old enteprise
# -- It will delete all enterprise orlder than especified parameter
#
# 

require 'rubygems'
require 'abiquo.rb'
require 'logger'
require 'rest-client'
require 'xmlsimple'
require 'pp'

#
# Configuration options
#########################################################
#AbiServer = '192.168.1.156'
AbiServer = '10.60.13.4'
AbiUser = 'admin'
AbiPass = 'xabiquo'
IdDatacenter = 1

$log = Logger.new(STDOUT)
#$log.level = Logger::INFO
$log.level = Logger::DEBUG


# 
# Creates the conection to Abiquo api
abq = Abiquo.new(AbiServer,AbiUser,AbiPass)

vm = Abiquo::VirtualMachine.get_vm_by_name("ABQ_b9c10151-e5e7-48e3-9a66-76cccbaafa81")
$log.info "VM retrived: "
$log.info "#{vm.inspect}"

dct = abq.create_datacenter("prueba", "prueba", "prueba", :all => '10.60.10.10:80')
$log.info "Received DC id: #{dct}"
dctest = Abiquo::Datacenter.new(abq.get_dc_by_id(dct))
racktest = dctest.create_standard_rack("racktest", "racktest", false, 400, 500, "402, 415, 450-460")

vdcs = abq.list_virtualdatacenters
vdc = Abiquo::VirtualDatacenter.new(abq.get_vdc_by_id(vdcs[0]))
vapps = vdc.list_vappliances
vapp = Abiquo::VirtualAppliance.new(vdc.get_vapp_by_id(vapps[0]))
vms = vapp.list_virtualmachines
vm = vapp.get_vm_by_id(vms[0])
vmxml = XmlSimple.xml_out(vm, 'RootName' => 'virtualmachine')

# Output: array with datacenters id
dcs = abq.list_datacenters
$log.info "Received datacenters #{dcs}"

# Create object datacenter with first item from list
dc = Abiquo::Datacenter.new(abq.get_dc_by_id(dcs[0]))

links = abq._getlinks dc.dc,'racks'
$log.info "Racks links #{links}"

racks = dc.list_racks

rack = Abiquo::Rack.new(dc.get_rack_by_id(racks[0]))

machines = rack.list_machines


machine = rack.get_machine_by_id(machines[0])

PP.pp machine
