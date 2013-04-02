class Abiquo::Datacenter < Abiquo
	attr_accessor :url
	attr_accessor :id
	attr_accessor :dc

	def initialize(dc)
		self.dc = dc
	end

	def show_id
		return self.dc["id"]
	end

	def list_racks()
		url = self._getlinks self.dc,'racks'
		xml = self._httpget(url)
		racks = []
		xml['rack'].each { |r|
			racks << r["id"][0]
		}
		return racks
	end

	def get_rack_by_id(id)
		url = "api/admin/datacenters/#{self.dc["id"]}/racks"
		xml = self._httpget(url)

		xml['rack'].each { |r|
			$log.debug "Iterating rack #{r['id']} #{r['id'].class} #{r['id'][0].class}"
			$log.debug "Parameter id #{id} #{id.class}"
				
			if r["id"][0] == id
				$log.info "Found rack #{r['id']}"
				return r
			end
		}

	return nil
	end

end