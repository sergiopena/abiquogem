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
require './abiquo.rb'
require 'logger'
require 'rest-client'
require 'xmlsimple'
require 'pp'
require 'uri'

#
# Configuration options
#########################################################
#AbiServer = '192.168.1.156'
AbiServer = 'http://10.60.13.21/api' # 2.4
#AbiServer = 'http://192.168.2.211/api' #2 .6
AbiUser = 'admin'
AbiPass = 'xabiquo'
IdDatacenter = 1

$log = Logger.new(STDOUT)
#$log.level = Logger::INFO
$log.level = Logger::DEBUG


# 
# Creates the conection to Abiquo api
abq = Abiquo.new(AbiServer,AbiUser,AbiPass)

# List datacenters
begin
	dcs = Abiquo::Datacenter.list_all
	dcs.each do |dc|
		$log.info "Found DC : #{dc.name} (id : #{dc.datacenterid})"
	end
rescue => e
	$log.info "Error listing datacenters."
	$log.debug "Exception occurred : #{e.message}"
	exit 1
end

# Test create Datacenter
uri = URI(AbiServer)
begin
	dct = Abiquo::Datacenter.create("Cassiopea", "Abiquo", "Support rulez!", :all => "#{uri.host}:80")
	$log.info "Datacenter '#{dct.name}' created with id '#{dct.datacenterid}' and uuid '#{dct.uuid}'"
rescue => e
	$log.info "Error creating datacenters."
	$log.debug "Exception occurred : #{e.message}"
end

# Test rename datacenter
dct.name = "Adromeda"
#begin
	dct = dct.update
	$log.info "Datacenter Id #{dct.datacenterid} renombrado a #{dct.name}"
#rescue Exception => e
	$log.info "Datacenter #{dct.name} (id : #{dct.datacenterid}) cannot be updated. Check Abiquo logs."
	$log.debug "Exception occurred : #{e.message}"
	exit 1
#end

# Test update remote service
begin
	dct.update_remote_service('VIRTUAL_SYSTEM_MONITOR', 'http://10.10.10.10:80/vsm')
	$log.info "Datacenter Id #{dct.datacenterid} changed VSM uri"
rescue Exception => e
	$log.info "Datacenter #{dct.name} (id : #{dct.datacenterid}) cannot be updated. Check Abiquo logs."
	$log.debug "Exception occurred : #{e.message}"
end

# Test create Rack
#begin
#	racktest = Abiquo::Rack.create_standard(dct, "RackTest", "A test", false, 2, 4096, "")
#	$log.info "Rack #{racktest.name} created with id #{racktest.rackid}"
#rescue => e
#	$log.info "Could not create rack in DC #{dct.name}"
#	$log.debug "#{e.message}"
#	exit 1
#end

# Test add PM
#idr = 19
#rname = "RackTest"
#racktest = Abiquo::Rack.get_by_id(idr)
#if not racktest.nil? then 
#	$log.info "racktest by id is : ID #{racktest.rackid} and name #{racktest.name}"
#else
#	$log.info "Rack with id #{idr} not found."
#end
#racktest = Abiquo::Rack.get_by_name(rname)
#if not racktest.nil? then 
#	$log.info "racktest by name is : ID #{racktest.rackid} and name #{racktest.name}"
#else
#	$log.info "Rack with name #{rname} not found."
#end
#
#begin
#	m = Abiquo::Machine.add_machine(racktest, :ip => '192.168.2.51', :type => "VMX_04", :user => 'root', :password => 'temporal', :name => 'PROVA-API', :datastore => "/", :vswitch => "eth0")
#	$log.info "Added physicalmachine #{m.name} (#{m.ip} #{m.type}) to rack #{racktest.name}"
#rescue => e
#	$log.info "Could not add machine to rack #{racktest.name}"
#	$log.debug "#{e.message}"
#	exit 1
#end

# Test edit rack
#begin
#	racktest = Abiquo::Rack.get_by_id(18)
#	$log.info "Rack ID #{racktest.rackid} with name #{racktest.name} retrieved."
#
#	racktest.name = "Nuevo Rack"
#	racktest.vlansIdAvoided = "78,89,100-150"
#	racktest = racktest.update_standard()
#	$log.info "Rack ID #{racktest.rackid} with name #{racktest.name} updated."
#rescue => e
#	$log.info "Could not edit rack"
#	$log.debug "#{e.message}"
#	exit 1
#end

# Delete Rack Test
#racktest.delete

# Delete Datacenter test
begin
	dct.delete
	$log.info "Datacenter #{dct.name} (id : #{dct.datacenterid}) has been deleted."
rescue Exception => e
	$log.info "Datacenter #{dct.name} (id : #{dct.datacenterid}) cannot be removed. Check Abiquo logs."
	$log.debug "Exception occurred : #{e.message}"
end

#dc = Abiquo::Datacenter.get_by_name("BCN")
#rack = dc.get_rack_by_name("RACK mock")
#m = rack.add_physicalmachine(:ip => '192.168.2.56', :user => 'root', :password => 'temporal', :name => 'PROVA-API', :datastore => "datastore1", :vswitch => "vSwitch1")

# Test add storage device
#begin
#	dct = Abiquo::Datacenter.get_by_name("Cassiopea")
#	if not dct.nil? then
#		stdev = Abiquo::StorageDev.create(dct, :name => 'Test - Script',:technology => 'LVM',:mgmt => '10.60.13.31:8180',:iscsi => '10.60.13.31:3260')
#		#stdev = Abiquo::StorageDev.create(dct, :name => 'NetApp QA',:technology => 'NETAPP',:mgmt => '10.60.11.7:80',:iscsi => '10.60.11.7:3260',:username => 'root',:password => 'temporal')
#		$log.info "Storage device #{stdev.name} (#{stdev.managementip}) added successfully."
#		pool = stdev.add_pool(:pool => 'VolGroup00',:tier => "Default Tier 1")
#		#pool = stdev.add_pool(:pool => 'aggr1',:tier => "Default Tier 2") 
#		if pool.nil? then
#			$log.info "Storage pool could not be added."
#		else
#			$log.info "Storage pool #{pool[:name]} added to device #{stdev.name} (#{stdev.managementip})."
#		end
#	else
#		$log.info "DC not found."
#	end
#rescue => e
#	$log.info "Could not add pool."
#	puts e.inspect
#end
