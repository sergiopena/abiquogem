class Abiquo::Rack < Abiquo::Datacenter
	attr_accessor :url
	attr_accessor :rack
	attr_accessor :id
	attr_accessor :datacenter

	def initialize(rack)
		self.rack = rack 
		self.id = rack["id"][0]
		self.datacenter = self._getlinks(self.rack, 'datacenter').split('/')[-1]
	end

	def save
		pp XmlSimple.xml_out(self.rack)
=begin
		builder = Builder::XmlMarkup.new()
		entity = builder.Rack  do |x|
			x.link(enterpriselink)
			x.link(:rel => "datacenter", :href => "http://#{@@server}/api/admin/datacenters/#{iddatacenter}") 
			x.hypervisorType("KVM")
			x.name("Default VDC")
			x.network {
				x.address("192.168.1.0")
				x.gateway("192.168.1.1")
				x.mask("24")
				x.name("DefaultNetwork")
				x.type("INTERNAL")
				x.unmanaged("false")
			}
		end
=end
	end

	def list_machines()
		url = self._getlinks self.rack,'machines'
		xml = self._httpget(url)
		output = []
		xml['machine'].each { |x|
			output << x["id"][0]
		}
		return output
	end

	def get_machine_by_id(id)
		url = "api/admin/datacenters/#{self.datacenter}/racks/#{self.id}/machines/#{id}"
		xml = self._httpget(url)

		return xml
	end

end