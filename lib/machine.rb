require 'rest-client'
require 'nokogiri'

class Abiquo::Machine < Abiquo::Rack
	attr_accessor :xml
	attr_accessor :url
	attr_accessor :datastores
	attr_accessor :rack
	attr_accessor :virtualmachines
	attr_accessor :id
	attr_accessor :description
	attr_accessor :initiatorIQN
	attr_accessor :ip
	attr_accessor :ipService
	attr_accessor :ipmiPassword
	attr_accessor :name
	attr_accessor :port
	attr_accessor :state
	attr_accessor :type
	attr_accessor :cpu
	attr_accessor :cpuUsed
	attr_accessor :ram
	attr_accessor :ramUsed

	def initialize(machinexml)
		m = Nokogiri::XML.parse(machinexml)
		@xml = machinexml
		@url = m.xpath('//link[@rel="edit"]').attribute('href').to_str
		@datastores = m.xpath('//link[@rel="datastores"]').attribute('href').to_str
		@rack = m.xpath('//link[@rel="rack"]').attribute('href').to_str
		@virtualmachines  = m.xpath('//link[@rel="virtualmachines"]').attribute('href').to_str
		@id = m.at('id').to_str
		@description = m.at('description').to_str
		@initiatorIQN = m.at('initiatorIQN').to_str
		@ip = m.at('ip').to_str
		@ipService = m.at('ipService').to_str
		@ipmiPassword = m.at('ipmiPassword').to_str
		@name = m.at('name').to_str
		@port = m.at('port').to_str
		@state = m.at('state').to_str
		@type = m.at('type').to_str
		@cpu = m.at('cpu').to_str
		@cpuUsed = m.at('cpuUsed').to_str
		@ram = m.at('ram').to_str
		@ramUsed = m.at('ramUsed').to_str
	end


end


=begin
<machine>
  <link rel="rack" type="application/vnd.abiquo.rack+xml" href="http://10.60.13.4:80/api/admin/datacenters/1/racks/4"/>
  <link rel="edit" type="application/vnd.abiquo.machine+xml" href="http://10.60.13.4:80/api/admin/datacenters/1/racks/4/machines/27"/>
  <link rel="datastores" type="application/vnd.abiquo.datastores+xml" href="http://10.60.13.4:80/api/admin/datacenters/1/racks/4/machines/27/datastores"/>
  <link rel="virtualmachines" type="application/vnd.abiquo.virtualmachines+xml" href="http://10.60.13.4:80/api/admin/datacenters/1/racks/4/machines/27/virtualmachines"/>
  <link rel="checkstate" type="application/vnd.abiquo.machinestate+xml" href="http://10.60.13.4:80/api/admin/datacenters/1/racks/4/machines/27/action/checkstate"/>
  <link rel="reenableafterha" type="application/vnd.abiquo.machine+xml" href="http://10.60.13.4:80/api/admin/datacenters/1/racks/4/machines/27/action/reenableafterha"/>
  <link rel="checkipmi" href="http://10.60.13.4:80/api/admin/datacenters/1/racks/4/machines/27/action/checkipmi"/>
  <link rel="checkipmistate" type="application/vnd.abiquo.machineipmistate+xml" href="http://10.60.13.4:80/api/admin/datacenters/1/racks/4/machines/27/action/checkipmistate"/>
  <link rel="refreshnics" type="application/vnd.abiquo.machine+xml" href="http://10.60.13.4:80/api/admin/datacenters/1/racks/4/machines/27/action/nics/refresh"/>

  <networkInterfaces>
    <networkinterface>
      <link rel="networkservicetype" type="application/vnd.abiquo.networkservicetype+xml" href="http://10.60.13.4:80/api/admin/datacenters/1/networkservicetypes/1"/>
      <mac>00:15:c5:ff:1b:8a</mac>
      <name>vSwitch0</name>
    </networkinterface>
    <networkinterface>
      <mac>00:15:c5:ff:1b:8c</mac>
      <name>vSwitch1</name>
    </networkinterface>
  </networkInterfaces>
=end
