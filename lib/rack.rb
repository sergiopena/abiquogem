require 'rest-client'
require 'nokogiri'

class Abiquo::Rack < Abiquo
	attr_accessor :xml
	attr_accessor :url
	attr_accessor :datacenter
	attr_accessor :machines
	attr_accessor :rackid
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
  		@rackid = r.at('/rack/id').to_str
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

  	def self.list_all()
  		racks = Array.new
		dcurl = "#{@@admin_api}/datacenters"
  		dcxml = RestClient::Request.new(:method => :get, :url => dcurl, :user => @@username, :password => @@password, :headers => { 'accept' => 'application/vnd.abiquo.datacenters+xml'}).execute
  		Nokogiri::XML.parse(rackxml).xpath('//datacenters/datacenter').each do |dc|
  			racksurl = dc.xpath('./link[@rel="racks"]').attribute('href').to_str
			rackxml = RestClient::Request.new(:method => :get, :url => racksurl, :user => @@username, :password => @@password).execute
  			Nokogiri::XML.parse(rackxml).xpath('//racks/rack').each do |rack|
				racks << Abiquo::Rack.new(rack.to_xml)
			end
		end
		return racks
  	end

  	def self.get_by_name(rack_name)
  		dcurl = "#{@@admin_api}/datacenters"
  		dcxml = RestClient::Request.new(:method => :get, :url => dcurl, :user => @@username, :password => @@password, :headers => { 'accept' => 'application/vnd.abiquo.datacenters+xml'}).execute
  		Nokogiri::XML.parse(dcxml).xpath('//datacenters/datacenter').each do |dc|
  			racksurl = dc.xpath('./link[@rel="racks"]').attribute('href').to_str
			rackxml = RestClient::Request.new(:method => :get, :url => racksurl, :user => @@username, :password => @@password).execute
  			Nokogiri::XML.parse(rackxml).xpath('//racks/rack').each do |rack|
				if rack.at('name').to_str == rack_name
					return Abiquo::Rack.new(rack.to_xml)
				end
			end
		end
		return nil
  	end

  	def self.get_by_id(id)
		dcurl = "#{@@admin_api}/datacenters"
  		dcxml = RestClient::Request.new(:method => :get, :url => dcurl, :user => @@username, :password => @@password, :headers => { 'accept' => 'application/vnd.abiquo.datacenters+xml'}).execute
  		Nokogiri::XML.parse(dcxml).xpath('//datacenters/datacenter').each do |dc|
  			racksurl = dc.xpath('./link[@rel="racks"]').attribute('href').to_str
			rackxml = RestClient::Request.new(:method => :get, :url => racksurl, :user => @@username, :password => @@password).execute
  			Nokogiri::XML.parse(rackxml).xpath('/racks/rack').each do |rack|
				if rack.at('id').to_str == id.to_s
					return Abiquo::Rack.new(rack.to_xml)
				end
			end
		end
		return nil
	end

	def self.create_standard(dc, name, desc, ha, vlanmin, vlanmax, vlanavoid)
		content = "application/vnd.abiquo.rack+xml;"
		builder = Builder::XmlMarkup.new
		entity = builder.rack do |rack|
			rack.name(name)
			rack.shortDescription(desc)
			rack.haEnabled(ha)
			rack.nsrq(10)
			rack.vlanIdMax(vlanmax)
			rack.vlanIdMin(vlanmin)
		end
		
		begin 
			content = 'application/vnd.abiquo.rack+xml'
			resour = RestClient::Resource.new(dc.racks, :user => @@username, :password => @@password)
			resp = resour.post entity, :content_type => content
			return Abiquo::Rack.new(resp)
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

	def update_standard()
		content = "application/vnd.abiquo.rack+xml;"
		builder = Builder::XmlMarkup.new
		entity = builder.rack do |rack|
			rack.name(@name)
			rack.shortDescription(@desc)
			rack.haEnabled(@ha)
			rack.nsrq(@msrq)
			rack.vlanIdMax(@vlanmax)
			rack.vlanIdMin(@vlanmin)
			@vlansIdAvoided.nil? ? rack.vlansIdAvoided(@vlansIdAvoided) : rack.vlansIdAvoided()
			rack.link('rel' => 'edit', 'href' => @url, 'type' => content)
		end
		$log.info "ENT : #{entity.inspect}"
		begin 
			content = 'application/vnd.abiquo.rack+xml'
			resour = RestClient::Resource.new(@url, :user => @@username, :password => @@password)
			resp = resour.put entity, :content_type => content
			return Abiquo::Rack.new(resp)
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

	def get_machines()
		machinesxml = RestClient::Request.new(:method => :get, :url => @machines, :user => @@username, :password => @@password).execute
		gotMachines = Array.new()
		Nokogiri::XML.parse(machinesxml).xpath('//machines/machine').each do |machine|
			gotMachines << Abiquo::Machine.new(machine.to_xml)
		end
		return gotMachines
	end

	def delete()
		req = RestClient::Request.new(:method => :delete, :url => @url, :user => @@username, :password => @@password)
		response = req.execute
	end

	def get_datacenter()
		dcxml = RestClient::Request.new(:method => :get, :url => @datacenter, :user => @@username, :password => @@password, :headers => {'accept'=>'application/vnd.abiquo.datacenters+xml'}).execute
		return Abiquo::Machine.new(Nokogiri::XML.parse(dcxml).xpath('//datacenters/datacenter').to_xml)
	end
end
