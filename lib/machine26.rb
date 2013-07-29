require 'rest-client'
require 'nokogiri'

class Abiquo::Machine < Abiquo
	attr_accessor :xml
	attr_accessor :url
	attr_accessor :datastores
	attr_accessor :rack
	attr_accessor :checkstate
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
		@checkstate = m.xpath('//link[@rel="checkstate"]').attribute('href').to_str
		@machineid = m.at('/machine/id').to_str
		@description = m.at('/machine/description').to_str
		@initiatorIQN = m.at('/machine/initiatorIQN').to_str
		@ip = m.at('/machine/ip').to_str
		@ipService = m.at('/machine/ipService').to_str
		@ipmiPassword = m.at('/machine/ipmiPassword').to_str
		@name = m.at('/machine/name').to_str
		@port = m.at('/machine/port').nil? ? 0 : m.at('/machine/port').to_str
		@state = m.at('/machine/state').to_str
		@type = m.at('/machine/type').to_str
		@cpu = m.at('/machine/cpu').to_str
		@cpuUsed = m.at('/machine/cpuUsed').to_str
		@ram = m.at('/machine/ram').to_str
		@ramUsed = m.at('/machine/ramUsed').to_str
	end

	def self.get_by_id(id)
		url = "#{@@admin_api}/datacenters"
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
		url = "#{@@admin_api}/datacenters"
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
		url = "#{@@admin_api}/datacenters"
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

	def self.add_machine(rack, node_hash)
		#url = "#{rack.datacenter}/action/hypervisor?ip=#{node_hash[:ip]}"
		#htype = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute
		discurl = "#{rack.datacenter}/action/discover?hypervisor=#{node_hash[:type]}&ip=#{node_hash[:ip]}&user=#{node_hash[:user]}&password=#{node_hash[:password]}"

		nstroot = "#{rack.datacenter}/networkservicetypes"
		nstxml = RestClient::Request.new(:method => :get, :url => nstroot, :user => @@username, :password => @@password).execute
		nsts = Nokogiri::XML.parse(nstxml).xpath('//networkservicestypes/networkservicetype')
		nstelement = nil
		nsts.each do |nst|
			if nst.at('defaultNST').to_str == "true" then
				nstelement = nst.xpath('./link[@rel="edit"]').first
			end
		end
		nstelement.set_attribute("rel", "networkservicetype")

		machinexml = RestClient::Request.new(:method => :get, :url => discurl, :user => @@username, :password => @@password).execute
		machine = Nokogiri::XML.parse(machinexml)

		mnode = machine.xpath("/machines/machine").first
		mnode.add_child(Nokogiri::XML::Node.new('password', machine))
		mnode.add_child(Nokogiri::XML::Node.new('user', machine))
		mnode.add_child(Nokogiri::XML::Node.new('ipService', machine))
		mnode.add_child(Nokogiri::XML::Node.new('ipmiIP', machine))
		mnode.add_child(Nokogiri::XML::Node.new('ipmiPassword', machine))
		mnode.add_child(Nokogiri::XML::Node.new('ipmiPort', machine))
		mnode.add_child(Nokogiri::XML::Node.new('ipmiUser', machine))
		mnode.add_child(Nokogiri::XML::Node.new('description', machine))
		
		node_hash.keys.each do |attrName|
			case attrName.to_s
			when "datastore"
				ds = machine.xpath("/machine/datastores/datastore[name='#{node_hash[attrName]}']/enabled").first 
				if not ds.nil?
					ds.content = 'true'
				end
			when "vswitch"
				vs = machine.xpath("/machine/networkInterfaces/networkinterface[name='#{node_hash[attrName]}']").first
				if not vs.nil?
					vs.add_child(nstelement)
				end
			else
				att = machine.xpath("/machine/#{attrName}").first
				if not att.nil?
					att.content = node_hash[attrName]
				end
			end
		end	
		# Let's see if ther is no ds enabled, to enable one of them
		if machine.xpath("/machines/machine/datastores/datastore/enabled[text()='true']").length == 0
			machine.xpath('/machines/machine/datastores/datastore/enabled').first.content = 'true'
		end
		# same with nics
		if machine.xpath("/machines/networkInterfaces/networkinterface/link[@rel='networkservicetype']").length == 0
			machine.xpath('/machines/machine/networkInterfaces/networkinterface').first.add_child(nstelement)
		end
		begin 
			content = 'application/vnd.abiquo.machine+xml'
			resour = RestClient::Resource.new("#{rack.url}/machines", :user => @@username, :password => @@password)
			resp = resour.post "#{machine.xpath('/machines/machine').to_xml}", :content_type => content
			return Abiquo::Machine.new(resp)
		rescue => e
			errormsg = Nokogiri::XML.parse(e.response).xpath('//errors/error') unless e.response.nil?
			if not errormsg.nil? then
				errormsg.each do |error|
					raise "Abiquo error code #{error.at('code').to_str} - #{error.at('message').to_str}"
				end
			else
				raise e.message
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
		rescue => e
			errormsg = Nokogiri::XML.parse(e.response).xpath('//errors/error')
			if not errormsg.nil? then
				errormsg.each do |error|
					raise "Abiquo error code #{error.at('code').to_str} - #{error.at('message').to_str}"
				end
			else
				raise e.message
			end
		end
	end

	def checkstate()
		req = RestClient::Request.new(:method => :get, :url => @checkstate, :user => @@username, :password => @@password)
		response = req.execute
	end

	def get_rack()
		req = RestClient::Request.new(:method => :get, :url => @rack, :user => @@username, :password => @@password)
		response = req.execute
		return Abiquo::Rack.new(response)
	end
end
