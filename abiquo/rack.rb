require 'rest-client'
require 'nokogiri'

class Abiquo::Rack < Abiquo::Datacenter
	attr_accessor :xml
	attr_accessor :url
	attr_accessor :datacenter
	attr_accessor :machines
	attr_accessor :id
	attr_accessor :haEnabled
	attr_accessor :longDescription
	attr_accessor :name
	attr_accessor :nrsq
	attr_accessor :shortDescription
	attr_accessor :vlanIdMin
	attr_accessor :vlanIdMax
	attr_accessor :vlansIdAvoided
	attr_accessor :vlanPerVdcReserved

  	def initialize(rackxml)
  		r = Nokogiri::XML.parse(rackxml)
  		@xml = rackxml
  		@url = r.xpath('//link[@rel="edit"]').attribute('href').to_str
  		@datacenter = r.xpath('//link[@rel="datacenter"]').attribute('href').to_str
  		@machines = r.xpath('//link[@rel="machines"]').attribute('href').to_str
  		@id = r.at('/rack/id').to_str
		@haEnabled = r.at('/rack/haEnabled').to_str
		r.at('/rack/longDescription').nil? ? @longDescription = "" : @longDescription = r.at('/rack/longDescription').to_str
		@name = r.at('/rack/name').to_str
		@nrsq = r.at('/rack/nrsq').to_str
		@shortDescription = r.at('/rack/shortDescription').to_str
		@vlanIdMin = r.at('/rack/vlanIdMin').to_str
		@vlanIdMax = r.at('/rack/vlanIdMax').to_str
		r.at('/rack/vlansIdAvoided').nil? ? @vlansIdAvoided = "" : @vlansIdAvoided = r.at('/rack/vlansIdAvoided').to_str
		@vlanPerVdcReserved = r.at('/rack/vlanPerVdcReserved').to_str
  	end

  	def self.get_by_name(racks_url, rack_name)
  		rackxml = RestClient::Request.new(:method => :get, :url => racks_url, :user => @@username, :password => @@password).execute
		Nokogiri::XML.parse(rackxml).xpath('//racks/rack').each do |rack|
			if rack.at('name').to_str == rack_name
				return Abiquo::Rack.new(rack.to_xml)
			end
		end
  	end

	def get_machines()
		machinesxml = RestClient::Request.new(:method => :get, :url => @machines, :user => @@username, :password => @@password).execute
		gotMachines = Array.new()
		Nokogiri::XML.parse(machinesxml).xpath('//machines/machine').each do |machine|
			gotMachines << Abiquo::Machine.new(machine.to_xml)
		end

		return gotMachines
	end

	def get_machine_by_id(id)
		url = "#{@machines}/#{id}"
		machinexml = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute

		return Abiquo::Machine.new(machinexml)
	end

	def delete()
		req = RestClient::Request.new(:method => :delete, :url => @url, :user => @@username, :password => @@password)
		response = req.execute
	end

	def add_physicalmachine(node_hash)
		url = "#{datacenter}/action/hypervisor?ip=#{node_hash[:ip]}"
		htype = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute
		discurl = "#{datacenter}/action/discoversingle?hypervisor=#{htype}&ip=#{node_hash[:ip]}&user=#{node_hash[:user]}&password=#{node_hash[:password]}"

		machinexml = RestClient::Request.new(:method => :get, :url => discurl, :user => @@username, :password => @@password).execute
		machine = Nokogiri::XML.parse(machinexml)

		mnode = machine.xpath("/machine").first
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
					t = Nokogiri::XML::Node.new('link', machine)
					t.set_attribute('rel', 'networkservicetype')
					t.set_attribute('type', 'application/vnd.abiquo.networkservicetype+xml')
					t.set_attribute('href', "#{datacenter}/networkservicetypes/1")
					vs.add_child(t)
				end
			else
				att = machine.xpath("/machine/#{attrName}").first
				if not att.nil?
					att.content = node_hash[attrName]
				end
			end
		end	

		# Let's see if ther is no ds enabled, to enable one of them
		if machine.xpath("/machine/datastores/datastore/enabled[text()='true']").length == 0
			machine.xpath('/machine/datastores/datastore/enabled').first.content = 'true'
		end
		# same with nics
		if machine.xpath("/machine/networkInterfaces/networkinterface/link[@rel='networkservicetype']").length == 0
			t = Nokogiri::XML::Node.new('link', ent)
			t.set_attribute('rel', 'networkservicetype')
			t.set_attribute('type', 'application/vnd.abiquo.networkservicetype+xml')
			t.set_attribute('href', "#{datacenter}/networkservicetypes/1")
			machine.xpath('/machine/networkInterfaces/networkinterface').first.add_child(t)
		end
		begin 
			content = 'application/vnd.abiquo.machine+xml'
			resour = RestClient::Resource.new("#{@url}/machines", :user => @@username, :password => @@password)
			resp = resour.post "#{machine.xpath('/machine').to_xml}", :content_type => content
			return Abiquo::Machine.new(resp)
		rescue RestClient::Conflict
			$log.info "Requested Machine already exists."
			return nil
		end
	end
end

