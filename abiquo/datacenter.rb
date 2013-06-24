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
		@id = d.at('/datacenter/id').to_str
		@location = d.at('/datacenter/location').to_str
		@name = d.at('/datacenter/name').to_str
		@uuid = d.at('/datacenter/uuid').to_str
	end

	def self.get_by_id(id)
		url = "http://#{@@server}/api/admin/datacenters"
		dcsxml = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute
		d = Nokogiri::XML.parse(dcsxml).xpath('//datacenters/datacenter')
		d.each do |dc|
			if dc.at('id').to_str == id.to_s 
				return Abiquo::Datacenter.new(dc.to_xml)
			end
		end
	end

	def self.get_by_uuid(uuid)
		url = "http://#{@@server}/api/admin/datacenters"
		dcsxml = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute
		d = Nokogiri::XML.parse(dcsxml).xpath('//datacenters/datacenter')
		d.each do |dc|
			if dc.at('uuid').to_str == uuid.to_s 
				return Abiquo::Datacenter.new(dc.to_xml)
			end
		end
	end

	def self.get_by_name(name)
		url = "http://#{@@server}/api/admin/datacenters"
		dcsxml = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute
		d = Nokogiri::XML.parse(dcsxml).xpath('//datacenters/datacenter')
		d.each do |dc|
			if dc.at('name').to_str == name.to_s 
				return Abiquo::Datacenter.new(dc.to_xml)
			end
		end
	end

	def delete()
		req = RestClient::Request.new(:method => :delete, :url => @url, :user => @@username, :password => @@password)
		response = req.execute
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

	def get_rack_by_name(name)
		racksxml = RestClient::Request.new(:method => :get, :url => @racks, :user => @@username, :password => @@password).execute
		r = Nokogiri::XML.parse(racksxml).xpath('//racks/rack')
		r.each do |rack|
			if rack.at('name').to_str == name.to_s
				return Abiquo::Rack.new(rack.to_xml)
			end
		end
		return nil
	end

	def create_standard_rack(name, desc, ha, vlanmin, vlanmax, vlanavoid)
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
			resour = RestClient::Resource.new(@racks, :user => @@username, :password => @@password)
			resp = resour.post entity, :content_type => content
			return Abiquo::Rack.new(resp)
		rescue RestClient::Conflict
			$log.info "Requested rack already exists."
			return Abiquo::Rack.get_by_name(@racks, name)
		end
	end
end
