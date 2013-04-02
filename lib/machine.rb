class Abiquo::Rack < Abiquo
	attr_accessor :url
	attr_accessor :id
	attr_accessor :dc

	def initialize(entity)
		self.entity = entity 
		self.id = entity["id"][0]
	end

	def list_machines()
		url = self._getlinks self.dc,'machines'
		xml = self._httpget(url)
		output = []
		xml['machine'].each { |x|
			output << x["id"][0]
		}
		return output
	end

	def get_machine_by_id(id)
		url = "api/admin/datacenters/#{self.dc["id"]}/racks"
		xml = self._httpget(url)

		xml['rack'].each { |r|
			$log.debug "Iterating rack #{r['id']} #{r['id'].class} #{r['id'][0].class}"
			$log.debug "Parameter id #{id} #{id.class}"
				
			if r["id"][0] == id
				$log.error "Found rack #{r['id']}"
				return r
			end
		}

	return nil
	end

end