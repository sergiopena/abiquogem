require 'rest-client'
require 'nokogiri'

class Abiquo::StorageDev < Abiquo
	attr_accessor :xml
	attr_accessor :url
	attr_accessor :pools
	attr_accessor :tiers
	attr_accessor :datacenter
	attr_accessor :deviceid
	attr_accessor :name
	attr_accessor :technology
	attr_accessor :managementip
	attr_accessor :managementport
	attr_accessor :iscsiip
	attr_accessor :iscsiport
	attr_accessor :user
	attr_accessor :password

	def initialize(devxml)
		d = Nokogiri::XML.parse(devxml)
		@xml = devxml
		@url = d.xpath('//link[@rel="edit"]').attribute('href').to_str
		@pools = d.xpath('//link[@rel="pools"]').attribute('href').to_str
		@tiers = d.xpath('//link[@rel="tiers"]').attribute('href').to_str
		@datacenter = d.xpath('//link[@rel="datacenter"]').attribute('href').to_str
		@deviceid = d.at('id').to_str
		@name = d.at('name').to_str
		@technology = d.at('storageTechnology').to_str
		@managementip = d.at('managementIp').to_str
		@managementport = d.at('managementPort').to_str
		@iscsiip = d.at('iscsiIp').to_str
		@iscsiport = d.at('iscsiPort').to_str
		if not d.at('username').nil? then
			@user = d.at('username').to_str
			@password = d.at('password').to_str
		end
	end

	def self.create(dc, params={})
		if [:name, :technology, :mgmt, :iscsi].all? {|s| params.key? s} then
			mgmtip, mgmtport = params[:mgmt].to_str.split(":")
			iscsiip, iscsiport = params[:iscsi].to_str.split(":")

			builder = Builder::XmlMarkup.new
			entity = builder.device do |device|
				device.name(params[:name])
				device.storageTechnology(params[:technology])
				device.managementIp(mgmtip)
				device.managementPort(mgmtport)
				device.iscsiIp(iscsiip)
				device.iscsiPort(iscsiport)
				if params.has_key?(:username) then
					device.username(params[:username])
					device.password(params[:password])
				end
			end
			
			begin 
				content = "application/vnd.abiquo.storagedevice+xml;"
				resour = RestClient::Resource.new(dc.storagedevs, :user => @@username, :password => @@password)
				resp = resour.post entity, :content_type => content
				return Abiquo::StorageDev.new(resp)
			rescue => e
				errormsg = Nokogiri::XML.parse(e.response).xpath('//errors/error')
				if not errormsg.nil? then
					errormsg.each do |error|
						if error.at('code').to_str == "DEVICE-1" then
							puts "#{mgmtip}"
							return Abiquo::StorageDev.get_by_ip(mgmtip)
						end
						raise "Abiquo error code #{error.at('code').to_str} - #{error.at('message').to_str}"
					end
				else
					raise e.message
				end
			end
		else
			raise ArgumentError, "Missing required argument."
		end
	end

	def self.get_by_id(id)
		dcurl = "#{@@admin_api}/datacenters"
  		dcxml = RestClient::Request.new(:method => :get, :url => dcurl, :user => @@username, :password => @@password, :headers => { 'accept' => 'application/vnd.abiquo.datacenters+xml'}).execute
  		Nokogiri::XML.parse(dcxml).xpath('//datacenters/datacenter').each do |dc|
  			devsurl = dc.xpath('./link[@rel="devices"]').attribute('href').to_str
			devxml = RestClient::Request.new(:method => :get, :url => devsurl, :user => @@username, :password => @@password).execute
  			Nokogiri::XML.parse(devxml).xpath('/devices/device').each do |device|
  				if device.at('id').to_str == id.to_s
					return Abiquo::StorageDev.new(device.to_xml)
				end
			end
		end
	end

	def self.get_by_name(device_name)
  		dcurl = "#{@@admin_api}/datacenters"
  		dcxml = RestClient::Request.new(:method => :get, :url => dcurl, :user => @@username, :password => @@password, :headers => { 'accept' => 'application/vnd.abiquo.datacenters+xml'}).execute
  		Nokogiri::XML.parse(dcxml).xpath('//datacenters/datacenter').each do |dc|
  			devsurl = dc.xpath('./link[@rel="devices"]').attribute('href').to_str
			devxml = RestClient::Request.new(:method => :get, :url => devsurl, :user => @@username, :password => @@password).execute
  			Nokogiri::XML.parse(devxml).xpath('//devices/device').each do |device|
				if device.at('name').to_str == device_name
					return Abiquo::StorageDev.new(device.to_xml)
				end
			end
		end
  	end

  	def self.get_by_ip(device_ip)
  		dcurl = "#{@@admin_api}/datacenters"
  		dcxml = RestClient::Request.new(:method => :get, :url => dcurl, :user => @@username, :password => @@password, :headers => { :accept => 'application/vnd.abiquo.datacenters+xml'}).execute
  		Nokogiri::XML.parse(dcxml).xpath('//datacenters/datacenter').each do |dc|
  			devsurl = dc.xpath('./link[@rel="devices"]').attribute('href').to_str
			devxml = RestClient::Request.new(:method => :get, :url => devsurl, :user => @@username, :password => @@password).execute
  			Nokogiri::XML.parse(devxml).xpath('//devices/device').each do |device|
				if device.at('managementIp').to_str == device_ip
					return Abiquo::StorageDev.new(device.to_xml)
				end
			end
		end
  	end

	def delete()
		req = RestClient::Request.new(:method => :delete, :url => @url, :user => @@username, :password => @@password)
		response = req.execute
	end

	def update()
		
		builder = Builder::XmlMarkup.new
		entity = builder.device do |device|
			device.name(@name)
			device.storageTechnology(@technology)
			device.managementIp(@managementip)
			device.managementPort(@managementport)
			device.iscsiIp(@iscsiip)
			device.iscsiPort(@iscsiport)
			if not device.at('username').nil? then
				device.username(@user)
				device.password(@password)
			end
		end
		
		begin 
			content = "application/vnd.abiquo.storagedevice+xml;"
			resour = RestClient::Resource.new(@url, :user => @@username, :password => @@password)
			resp = resour.put entity, :content_type => content
			return Abiquo::StorageDev.new(resp)
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

	def get_pools(params={})
		pools = Array.new
		poolsurl = params.has_key?(:sync) ? "#{@url}/pools?sync=true" : "#{@url}/pools"
		poolsxml = RestClient::Request.new(:method => :get, :url => poolsurl, :user => @@username, :password => @@password).execute
		Nokogiri::XML.parse(poolsxml).xpath('/storagePools/storagePool').each do |pool|
			pool_ = Hash.new 
			pool_[:name] = pool.at('name').to_str
			pool_[:sizeinmb] = pool.at('totalSizeInMb').to_str
			pool_[:usedinmb] = pool.at('usedSizeInMb').to_str
			pool_[:availableinmb] = pool.at('availableSizeInMb').to_str

			pools.push(pool_)
		end

		return pools
	end

	def add_pool(pool_data={})
		if pool_data.has_key?(:pool) then
			devpools = get_pools(:sync => true)
			devpools.each do |pool_|
				if pool_[:name].to_s == pool_data[:pool].to_s then
					builder = Builder::XmlMarkup.new
					entity = builder.storagePool do |storagePool|
						storagePool.name(pool_[:name])
						storagePool.totalSizeInMb(pool_[:sizeinmb])
						storagePool.usedSizeInMb(pool_[:usedinmb])
						storagePool.availableSizeInMb(pool_[:availableinmb])

						if pool_data.has_key?(:tier) then
							storagePool.link('rel' => 'tier', 'type' => 'application/vnd.abiquo.tier+xml', 'href' => get_tier(pool_data[:tier])) unless get_tier(pool_data[:tier]).nil?
						end
					end
					
					begin 
						content = "application/vnd.abiquo.storagepool+xml"
						resour = RestClient::Resource.new(@pools, :user => @@username, :password => @@password)
						resp = resour.post entity, :content_type => content
						return pool_
					rescue => e
						errormsg = Nokogiri::XML.parse(e.response).xpath('//errors/error')
						if not errormsg.nil? then
							errormsg.each do |error|
								if error.at('code').to_str == "SP-8" then
									return pool_
								end
								raise "Abiquo error code #{error.at('code').to_str} - #{error.at('message').to_str}"
							end
						else
							raise e.message
						end
					end
				end
			end
			return nil
		else
			raise ArgumentError, "Need at least pool name to add a pool."
			return nil
		end
	end

	def get_tier(tier_name)
		tiersxml = RestClient::Request.new(:method => :get, :url => "#{@datacenter}/storage/tiers", :user => @@username, :password => @@password).execute
		Nokogiri::XML.parse(tiersxml).xpath('/tiers/tier').each do |tier|
			if tier.at('name').to_str == tier_name then
				linkstr = tier.xpath('./link[@rel="edit"]').attribute('href').to_str
				return linkstr
			end
		end
		return nil
	end
end
