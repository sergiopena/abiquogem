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
AbiServer = '10.60.13.18'
AbiUser = 'admin'
AbiPass = 'xabiquo'
IdDatacenter = 1

$log = Logger.new(STDOUT)
#$log.level = Logger::INFO
$log.level = Logger::DEBUG

# 
# Creates the conection to Abiquo api
abq = Abiquo.new(AbiServer,AbiUser,AbiPass)

# Test create Datacenter
#dct = abq.create_datacenter("prueba", "prueba", "prueba", :all => '10.60.10.10:80')
#$log.info "Datacenter '#{dct.name}' created with id '#{dct.id}' and uuid '#{dct.uuid}'"

# Test create Rack
#racktest = dct.create_standard_rack("RackTest", "A test", false, 2, 4096, "")
#$log.info "Rack #{racktest.name} created with id #{racktest.id}"

# Test add PM
#m = racktest.add_physicalmachine(:ip => '192.168.2.56', :user => 'root', :pass => 'temporal')
#$log.info "Added physicalmachine #{m.name} (#{m.ip} #{m.type}) to rack #{racktest.name}"

# Delete Rack Test
#racktest.delete

# Delete Datacenter test
#dct.delete

dc = Abiquo::Datacenter.get_by_name("dc")
if not dc.nil? then
	puts "Datacenter not found."
	exit 0
end
rack = dc.get_rack_by_name("RACK mock")
m = rack.add_physicalmachine(:ip => '192.168.2.56', :user => 'root', :password => 'temporal', :name => 'PROVA-API', :datastore => "datastore1", :vswitch => "vSwitch1")
