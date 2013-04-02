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
class Abiquo

	#
	# 
	# 
	def initialize(server,username,password)
		@@server = server
		@@username = username
		@@password = password
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

	def list_datacenters()
		url = "http://#{@@username}:#{@@password}@#{@@server}/api/admin/datacenters"
		xml = self._httpget url
		dcs = []
		xml['datacenter'].each { |dc|
			dcs << dc["id"][0]
		}
		return dcs
	end

	def get_dc_by_id(id)
		url = "http://#{@@username}:#{@@password}@#{@@server}/api/admin/datacenters"
		xml = self._httpget url

		xml['datacenter'].each { |dc|
			if dc["id"][0] == id
				$log.debug "Found DC #{dc['id']}"
				return dc
			end
		}

		return nil
	end

end

#require 'lib/enterprise'
require 'lib/virtualdatacenter'
require 'lib/virtualappliance'
require 'lib/datacenter'
require 'lib/rack'
#require 'lib/roles'
# require 'lib/user'