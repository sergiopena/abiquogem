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

	@@resource_url = "/datacenters"
	@@accept_header = "application/vnd.abiquo.datacenters+xml"

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

	def self.list_all()
		url = "#{@@admin_api}#{@@resource_url}"
		dcsxml = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password, :headers => { 'accept' => @@accept_header}).execute
		d = Nokogiri::XML.parse(dcsxml).xpath('//datacenters/datacenter')
		dcs = Array.new
		d.each do |dc|
			dcs << Abiquo::Datacenter.new(dc.to_xml)
		end
		return dcs
	end

	def self.get_by_id(id)
		url = "#{@@admin_api}#{@@resource_url}/#{id}"
		dcsxml = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute
		d = Nokogiri::XML.parse(dcsxml).xpath('/datacenter')
		return Abiquo::Datacenter.new(d.to_xml)
	end

	def self.get_by_uuid(uuid)
		url = "#{@@admin_api}#{@@resource_url}"
		dcsxml = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute
		d = Nokogiri::XML.parse(dcsxml).xpath('//datacenters/datacenter')
		d.each do |dc|
			if dc.at('uuid').to_str == uuid.to_s 
				return Abiquo::Datacenter.new(dc.to_xml)
			end
		end
	end

	def self.get_by_name(name)
		url = "#{@@admin_api}#{@@resource_url}"
		dcsxml = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute
		d = Nokogiri::XML.parse(dcsxml).xpath('//datacenters/datacenter')
		d.each do |dc|
			if dc.at('name').to_str == name.to_s 
				return Abiquo::Datacenter.new(dc.to_xml)
			end
		end
	end

	def self.create(name, uuid, location, rs={})
		url = "#{@@admin_api}#{@@resource_url}"
		builder = Builder::XmlMarkup.new

		if rs.length == 1 
			ip, port = rs[:all].split(':')
			entity = builder.datacenter do |dc|
				dc.uuid(uuid)
				dc.name(name)
				dc.location(location)
				dc.remoteServices {
					dc.totalSize(7)
					dc.remoteService {
						dc.type("VIRTUAL_FACTORY")
						dc.uri("http://#{ip}:#{port}/virtualfactory")
						dc.status(0)
					}
					dc.remoteService {
						dc.type("VIRTUAL_SYSTEM_MONITOR")
						dc.uri("http://#{ip}:#{port}/vsm")
						dc.status(0)
					}
					dc.remoteService {
						dc.type("APPLIANCE_MANAGER")
						dc.uri("http://#{ip}:#{port}/am")
						dc.status(0)
					}
					dc.remoteService {
						dc.type("NODE_COLLECTOR")
						dc.uri("http://#{ip}:#{port}/nodecollector")
						dc.status(0)
					}
					dc.remoteService {
						dc.type("STORAGE_SYSTEM_MONITOR")
						dc.uri("http://#{ip}:#{port}/ssm")
						dc.status(0)
					}
					dc.remoteService {
						dc.type("BPM_SERVICE")
						dc.uri("http://#{ip}:#{port}/bpm-async")
						dc.status(0)
					}
					dc.remoteService {
						dc.type("DHCP_SERVICE")
						dc.uri("http://#{ip}:7911")
						dc.status(0)
					}
				}
			end
		elsif rs.length == 7
			entity = builder.datacenter do |dc|
				dc.uuid(uuid)
				dc.name(name)
				dc.location(location)
				dc.remoteServices { 
					dc.totalSize(7)
					dc.remoteService { 
						dc.type("VIRTUAL_FACTORY")
						dc.uri("http://#{rs[:vf]}/virtualfactory")
						dc.status(0)
					}
					dc.remoteService { 
						dc.type("VIRTUAL_FACTORY")
						dc.uri("http://#{rs[:vsm]}/vsm")
						dc.status(0)
					}
					dc.remoteService { 
						dc.type("VIRTUAL_FACTORY")
						dc.uri("http://#{rs[:am]}/am")
						dc.status(0)
					}
					dc.remoteService { 
						dc.type("VIRTUAL_FACTORY")
						dc.uri("http://#{rs[:nc]}/nodecollector")
						dc.status(0)
					}
					dc.remoteService { 
						dc.type("VIRTUAL_FACTORY")
						dc.uri("http://#{rs[:ssm]}/ssm")
						dc.status(0)
					}
					dc.remoteService { 
						dc.type("BPM-ASYNC")
						dc.uri("http://#{rs[:bpm]}/bpm-async")
						dc.status(0)
					}
					dc.remoteService { 
						dc.type("DHCP")
						dc.uri("http://#{rs[:dhcp]}:7911")
						dc.status(0)
					}
				}
			end
		end

		begin 
			content = 'application/vnd.abiquo.datacenter+xml'
			resour = RestClient::Resource.new("#{url}", :user => @@username, :password => @@password)
			resp = resour.post entity, :content_type => content
			return Abiquo::Datacenter.new(resp)
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

	def delete()
		req = RestClient::Request.new(:method => :delete, :url => @url, :user => @@username, :password => @@password)
		response = req.execute
	end

	def update()
		url = "#{@url}"
		builder = Builder::XmlMarkup.new

		entity = builder.datacenter do |dc|
			dc.uuid(@uuid)
			dc.name(@name)
			dc.location(@location)
		end

		begin 
			content = 'application/vnd.abiquo.datacenter+xml'
			resour = RestClient::Resource.new("#{url}", :user => @@username, :password => @@password)
			resp = resour.put entity, :content_type => content
			return Abiquo::Datacenter.new(resp)
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

	def update_remote_service(type, uri)
		rsxml = RestClient::Request.new(:method => :get, :url => @rs, :user => @@username, :password => @@password).execute
		r = Nokogiri::XML.parse(rsxml).xpath('//remoteServices/remoteService')
		r.each do |rs|
			rstype = rs.at('type').to_str
			if rstype == type then
				url = rs.xpath('./link[@rel="edit"]').attribute("href")
				rs.at('uri').content = uri
				
				begin 
					content = 'application/vnd.abiquo.remoteservice+xml'
					resour = RestClient::Resource.new("#{url}", :user => @@username, :password => @@password)
					resp = resour.put rs.to_xml, :content_type => content
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
end
