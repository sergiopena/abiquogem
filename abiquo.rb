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
	attr_accessor :admin_api
	#
	# 
	# 
	def initialize(apiurl,username,password)
		@@apiurl = apiurl
		@@username = username
		@@password = password
		@@admin_api = "#{apiurl}/admin"
		@@cloud_api = "#{apiurl}/cloud"
	end

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

		return nil
	end

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
end

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
