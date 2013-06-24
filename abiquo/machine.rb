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
		@id = m.at('/machine/id').to_str
		@description = m.at('/machine/description').to_str
		@initiatorIQN = m.at('/machine/initiatorIQN').to_str
		@ip = m.at('/machine/ip').to_str
		@ipService = m.at('/machine/ipService').to_str
		@ipmiPassword = m.at('/machine/ipmiPassword').to_str
		@name = m.at('/machine/name').to_str
		@port = m.at('/machine/port').to_str
		@state = m.at('/machine/state').to_str
		@type = m.at('/machine/type').to_str
		@cpu = m.at('/machine/cpu').to_str
		@cpuUsed = m.at('/machine/cpuUsed').to_str
		@ram = m.at('/machine/ram').to_str
		@ramUsed = m.at('/machine/ramUsed').to_str
	end

	def self.get_by_id(id)
		url = "http://#{@@server}/api/admin/datacenters"
		dcxml = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute
		Nokogiri::XML.parse(dcxml).xpath('//link[@rel="racks"]').each do |dc|
			racksurl = dc.attribute('href').to_str
			rackxml = RestClient::Request.new(:method => :get, :url => racksurl, :user => @@username, :password => @@password).execute
			Nokogiri::XML.parse(rackxml).xpath('//link[@rel="machines"]').each do |rack|
				machinesurl = rack.attribute('href').to_str
				machinesxml = RestClient::Request.new(:method => :get, :url => machinesurl, :user => @@username, :password => @@password).execute
				Nokogiri::XML.parse(machinesxml).xpath('/machines/machine').each do |machine|
					if machine.at('/machine/id').to_str == id.to_str
						return Abiquo::Machine.new(machine.to_xml)
					end
				end
			end
		end
	end

	def self.get_by_name(name)
		url = "http://#{@@server}/api/admin/datacenters"
		dcxml = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute
		Nokogiri::XML.parse(dcxml).xpath('//link[@rel="racks"]').each do |dc|
			racksurl = dc.attribute('href').to_str
			rackxml = RestClient::Request.new(:method => :get, :url => racksurl, :user => @@username, :password => @@password).execute
			Nokogiri::XML.parse(rackxml).xpath('//link[@rel="machines"]').each do |rack|
				machinesurl = rack.attribute('href').to_str
				machinesxml = RestClient::Request.new(:method => :get, :url => machinesurl, :user => @@username, :password => @@password).execute
				Nokogiri::XML.parse(machinesxml).xpath('/machines/machine').each do |machine|
					if machine.at('/machine/name').to_str == name.to_str
						return Abiquo::Machine.new(machine.to_xml)
					end
				end
			end
		end
	end

	def self.get_by_ip(ipAddress)
		url = "http://#{@@server}/api/admin/datacenters"
		dcxml = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute
		Nokogiri::XML.parse(dcxml).xpath('//link[@rel="racks"]').each do |dc|
			racksurl = dc.attribute('href').to_str
			rackxml = RestClient::Request.new(:method => :get, :url => racksurl, :user => @@username, :password => @@password).execute
			Nokogiri::XML.parse(rackxml).xpath('//link[@rel="machines"]').each do |rack|
				machinesurl = rack.attribute('href').to_str
				machinesxml = RestClient::Request.new(:method => :get, :url => machinesurl, :user => @@username, :password => @@password).execute
				Nokogiri::XML.parse(machinesxml).xpath('/machines/machine').each do |machine|
					if machine.at('./ip').to_str == ipAddress.to_str
						return Abiquo::Machine.new(machine.to_xml)
					end
				end
			end
		end
	end

	def delete()
		req = RestClient::Request.new(:method => :delete, :url => @url, :user => @@username, :password => @@password)
		response = req.execute
	end

	def update(infoHash)
		machine = Nokogiri::XML.parse(@xml)

		infoHash.keys.each do |attrName|
			machine.xpath("/machine/#{attrName}").first.content = infoHash[attrName]
		end

		begin 
			content = 'application/vnd.abiquo.machine+xml'
			resour = RestClient::Resource.new("#{@url}", :user => @@username, :password => @@password)
			resp = resour.put "#{machine.xpath('/machine').to_xml}", :content_type => content
			return Abiquo::Machine.new(resp)
		rescue RestClient::Conflict
			return nil
		rescue RestClient::Forbidden
			return nil
		end
	end

	def checkstate()
		# TODO?
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
