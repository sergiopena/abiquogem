require 'rest-client'
require 'nokogiri'

class Abiquo::Datacenter < Abiquo
	attr_accessor :xml
	attr_accessor :url
	attr_accessor :id
	attr_accessor :location
	attr_accessor :name
	attr_accessor :uuid
	attr_accessor :storagedevs
	attr_accessor :racks
	attr_accessor :rs

	def initialize(dcxml)
		d = Nokogiri::XML.parse(dcxml)
		@xml = dcxml
		@url = d.xpath('//link[@rel="edit"]').attribute('href').to_str
		@storagedevs = d.xpath('//link[@rel="devices"]').attribute('href').to_str
		@racks = d.xpath('//link[@rel="racks"]').attribute('href').to_str
		@rs = d.xpath('//link[@rel="remoteservices"]').attribute('href').to_str
		@id = d.at('id').to_str
		@location = d.at('id').to_str
		@name = d.at('id').to_str
		@uuid = d.at('id').to_str
	end

	def self.list()
		url = "http://#{@@server}/api/admin/datacenters"
		dcsxml = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute
		p dcsxml
		d = Nokogiri::XML.parse(dcsxml).xpath('//datacenters/datacenter')
		p d
		dcs = []
		d.each do |dc|
			dcs << Abiquo::Datacenter.new(dc.to_xml) 
		end	
		return dcs
	end

	def self.get_by_id(id)
	# Return Datacenter object feching it by Id
		url = "http://#{@@username}:#{@@password}@#{@@server}/api/admin/datacenters"
		dcsxml = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute
		d = Nokogiri::XML.parse(dcsxml).xpath('//datacenters/datacenter')
		d.each do |dc|
			if dc.at('id').to_str == id.to_s 
				return Abiquo::Datacenter.new(dc.to_xml)
			end
		end
	end

	def get_racks()
		retracks = Array.new()
		racksxml = RestClient::Request.new(:method => :get, :url => @racks, :user => @@username, :password => @@password).execute
		r = Nokogiri::XML.parse(racksxml).xpath('//racks/rack')
		r.each do |rack|
			retracks << Abiquo::Rack.new(rack)
		end

		return retracks
	end

	def get_rack_by_id(id)
		racksxml = RestClient::Request.new(:method => :get, :url => @racks, :user => @@username, :password => @@password).execute
		r = Nokogiri::XML.parse(racksxml).xpath('//racks/rack')
		r.each do |rack|
			if rack.at('id').to_str == id.to_s
				return Abiquo::Rack.new(rack)
			end
		end
		return nil
	end

	def create_standard_rack(name, desc, ha, vlanmin, vlanmax, vlanavoid)
		url = "http://#{@@username}:#{@@password}@#{@@server}/api/admin/datacenters/#{@id}/racks"
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
		
		$log.debug "#{entity}"

		begin 
			response = RestClient.post url, entity, :content_type => content

			if response.code == 201 # Resource created ok
				xml = XmlSimple.xml_in(response)
				$log.debug xml
				$log.info "Rack created OK with id #{xml['id']}"
				return xml['id']
			end
		rescue RestClient::Conflict
			$log.info "Requested rack already exists."
			return nil
		end
	end
end
