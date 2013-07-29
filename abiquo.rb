#
#
# Abiquo API Interface
#
# Author: Sergio Pena
#
#

#
# Main class
#

require 'builder'
require 'rest_client'

class Abiquo
	attr_reader :admin_api
	attr_reader :cloud_api
	attr_reader :apiversion
	#
	# 
	# 
	def initialize(apiurl,username,password)
		@@apiurl = apiurl
		@@username = username
		@@password = password
		@@admin_api = "#{apiurl}/admin"
		@@cloud_api = "#{apiurl}/cloud"

		@@apiversion = RestClient::Request.new(:method => :get, :url => "#{apiurl}/version", :user => username, :password => password).execute.to_s
	end

	def self.get(resource, headers={})
		if headers.nil? then
			res = RestClient::Resource.new(resource, @@username, @@password)
			response = res.get
		else
			res = RestClient::Resource.new(resource, @@username, @@password)
			response = res.get(headers)
		end
		
		if response.code == 201 then
			return response.body
		else
			return nil
		end
	end

	def self.post(resource, data, headers={})
		begin 
			resource = RestClient::Resource.new(resource, :user => @@username, :password => @@password)
			if headers.nil? then
				response = resource.post(data)
			else
				response = resource.post(data, headers)
			end
			if response.code == 201 then
				return response.body
			else
				return nil
			end
		rescue RestClient::Exception => conflict
			errormsg = Nokogiri::XML.parse(conflict.response).xpath('//errors/error')
			if not errormsg.nil? then
				errormsg.each do |error|
					raise "Abiquo error code #{error.at('code').to_str} - #{error.at('message').to_str}"
				end
			else
				raise e.message
			end
		end
	end

	def self.put(resource, data, headers={})
		begin 
			resource = RestClient::Resource.new(resource, :user => @@username, :password => @@password)
			if headers.nil? then
				response = resource.put(data)
			else
				response = resource.put(data, headers)
			end
			$log.info "Response code : #{response.code}"
			if response.code == 200 then
				return response.body
			else
				return nil
			end
		rescue RestClient::Exception => conflict
			errormsg = Nokogiri::XML.parse(conflict.response).xpath('//errors/error')
			if not errormsg.nil? then
				errormsg.each do |error|
					raise "Abiquo error code #{error.at('code').to_str} - #{error.at('message').to_str}"
				end
			else
				raise e.message
			end
		end
	end

	def self.delete(resource)
		begin
			resource = RestClient::Resource.new(resource, :user => @@username, :password => @@password)
			response = resource.delete()
		rescue RestClient::Exception => conflict
			errormsg = Nokogiri::XML.parse(conflict.response).xpath('//errors/error')
			if not errormsg.nil? then
				errormsg.each do |error|
					raise "Abiquo error code #{error.at('code').to_str} - #{error.at('message').to_str}"
				end
			else
				raise e.message
			end
		end
	end

=begin
	def create_virtualdatacenter(	enterpriselink, iddatacenter )
		$log.info "Instanciated virtualdatacenter for enterprise #{enterpriselink}"

		builder = builder::xmlmarkup.new()
		entity = builder.virtualdatacenter  do |x|
			x.link(enterpriselink)
			x.link(:rel => "datacenter", :href => "http://#{@@server}/api/admin/datacenters/#{iddatacenter}") 
			x.hypervisorType("KVM")
			x.name("Default VDC")
			x.network {
			x.address("192.168.1.0")
			x.gateway("192.168.1.1")
			x.mask("24")
			x.name("defaultnetwork")
			x.type("INTERNAL")
				x.unmanaged("false")
			}
		end

		$log.debug @url
		$log.debug entity

		response = RestClient.post @url, entity, :accept => @accept, :content_type => @content

		if response.code == 201 # Resource created ok
			xml = XmlSimple.xml_in(response)
			$log.debug xml
			xml['link'].each { |x| 
				if x["rel"] == 'topurchase'
					self.topurchaselink = x
				end
				if x["rel"] == 'edit'
					self.editlink = x
				end
			}
			$log.info "Default VirtualDatacenter created OK"
			#$log.error self.editlink
		end
	end

	#
	# Wrapper to the REST get operation 
	#
	def _httpget(url)
		tmpurl = url.split('/')
		(0..tmpurl.index('api')-1).each do |x|
			tmpurl.delete_at(0)
		end
		parsedurl = "http://#{@@username}:#{@@password}@#{@@server}/#{tmpurl.join('/')}"

		$log.info "Retrieving to #{parsedurl}"
		response = RestClient.get( parsedurl )


		if response.code == 200
			xmloutput = XmlSimple.xml_in(response)
			return xmloutput
		end

	rescue => e
		$log.error e.message

	end

	def _getlinks(object, type)
		object['link'].each { |l|
			if l['rel'] == type 
				return l['href']
			end
		}

		return nil
	end

	def list_enterprises()
		url = "http://#{@@username}:#{@@password}@#{@@server}/api/admin/enterprises"
		xml = self._httpget(url)
		ents = []
		xml['enteprise'].each { |ent|
			ent << ents["id"][0]
		}
		return ents
	end

	def get_enteprise_by_id(id)
		url = "http://#{@@username}:#{@@password}@#{@@server}/api/admin/enterprises"
		xml = self._httpget(url)

		xml['enteprise'].each { |ent|
			if ent["id"][0] == id
				$log.debug "Found ent #{ent['id']}"
				return ent
			end
		}

		return nil
	end
	
	def list_virtualdatacenters()
		url = "http://#{@@username}:#{@@password}@#{@@server}/api/cloud/virtualdatacenters"
		xml = self._httpget(url)
		vdcs = []
		xml['virtualDatacenter'].each { |vdc|
			vdcs << vdc["id"][0]
		}
		return vdcs
	end

	def get_vdc_by_id(id)
		url = "http://#{@@username}:#{@@password}@#{@@server}/api/cloud/virtualdatacenters"
		xml = self._httpget(url)

		xml['virtualDatacenter'].each { |vdc|
			if vdc["id"][0] == id
				$log.debug "Found VDC #{vdc['id']}"
				return vdc
			end
		}

<<<<<<< HEAD
	return nil
	end

	# Methods moved to Datacenter class methods
	# def list_datacenters()
	# 	url = "http://#{@@username}:#{@@password}@#{@@server}/api/admin/datacenters"
	# 	xml = self._httpget url
	# 	dcs = []
	# 	xml['datacenter'].each { |dc|
	# 		dcs << dc["id"][0]
	# 	}
	# 	return dcs
	# end

	# def get_dc_by_id(id)
	# 	url = "http://#{@@username}:#{@@password}@#{@@server}/api/admin/datacenters"
	# 	xml = self._httpget url

	# 	xml['datacenter'].each { |dc|
	# 		if dc["id"][0] == id
	# 			$log.debug "Found DC #{dc['id']}"
	# 			return dc
	# 		end
	# 	}

	# 	return nil
	# end
=======
		return nil
	end
>>>>>>> mcirauqui-api

	def get_kvm_definition(vmID)
		# call login to get the link to VMs
		url = "http://#{@@username}:#{@@password}@#{@@server}/api/login"
		login = _httpget(url)
		login['link'].each do |x|
			if x['rel'] == 'virtualmachines'
				url = x['href']
			end
		end
		vms = _httpget(url)
		$log.info "VMs count: #{vms.length}"
	end
=end
end

<<<<<<< HEAD
require './lib/enterprise'
require './lib/virtualdatacenter'
require './lib/virtualappliance'
require './lib/virtualmachine'
require './lib/datacenter'
require './lib/rack'
require './lib/machine'
#require 'lib/roles'
require './lib/user'
=======
require 'lib/datacenter'
require 'lib/rack'
require 'lib/machine'
require 'lib/device'
#require 'lib/enterprise'
require 'lib/virtualdatacenter'
require 'lib/virtualappliance'
require 'lib/virtualmachine'
#require 'lib/roles'
#require 'lib/user'
>>>>>>> mcirauqui-api
