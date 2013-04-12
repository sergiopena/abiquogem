require 'rest-client'
require 'nokogiri'

class Abiquo::Rack < Abiquo::Datacenter
	attr_accessor :xml
	attr_accessor :url
	attr_accessor :datacenter
	attr_accessor :machines
	attr_accessor :id
	attr_accessor :haEnabled
	attr_accessor :longDescription
	attr_accessor :name
	attr_accessor :nrsq
	attr_accessor :shortDescription
	attr_accessor :vlanIdMin
	attr_accessor :vlanIdMax
	attr_accessor :vlansIdAvoided
	attr_accessor :vlanPerVdcReserved

  	def initialize(rackxml)
  		r = Nokogiri::XML.parse(rackxml.to_xml)
  		@xml = rackxml.to_xml
  		@url = r.xpath('//link[@rel="edit"]').attribute('href').to_str
  		@datacenter = r.xpath('//link[@rel="datacenter"]').attribute('href').to_str
  		@machines = r.xpath('//link[@rel="machines"]').attribute('href').to_str
  		@id = r.at('id').to_str
		@haEnabled = r.at('haEnabled').to_str
		@longDescription = r.at('longDescription').to_str
		@name = r.at('name').to_str
		@nrsq = r.at('nrsq').to_str
		@shortDescription = r.at('shortDescription').to_str
		@vlanIdMin = r.at('vlanIdMin').to_str
		@vlanIdMax = r.at('vlanIdMax').to_str
		@vlansIdAvoided = r.at('vlansIdAvoided').to_str
		@vlanPerVdcReserved = r.at('vlanPerVdcReserved').to_str
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

	def add_physicalmachine(node_hash)
		rsurl = "#{@datacenter}/remoteservices"
		rsxml = RestClient::Request.new(:method => :get, :url => rsurl, :user => @@username, :password => @@password).execute
		Nokogiri::XML.parse(rsxml).xpath('//remoteServices/remoteService').each do |rs|
			if rs.at('type').to_str == 'NODE_COLLECTOR'
				ncurl = rs.at('uri').to_str
				hyp_type = RestClient::Request.new(:method => :get, :url => "#{ncurl}/#{node_hash[:ip]}/hypervisor").execute
				hypervisor_info = RestClient::Request.new(:method => :get, :url => "#{ncurl}/#{node_hash[:ip]}/host?hyp=VMX_04&user=#{node_hash[:user]}&passwd=#{node_hash[:pass]}").execute
				info = Nokogiri::XML.parse(hypervisor_info).xpath("/ns2:Host")
				
				machine = Nokogiri::XML::Builder.new() do |m|
					m.machine {
						node_hash[:name].nil? ? m.name(info.at('name').to_str) : m.name(node_hash[:name])
						m.password(node_hash[:pass])
						m.user(node_hash[:user])
						m.type_(hyp_type)
						m.cpu(info.at('cpu').to_str)
						m.ram(info.at('ram').to_str)
						m.initiatorIQN(info.at('initiatorIQN').to_str)
						m.ip(node_hash[:ip])
						node_hash[:ipService].nil? ? m.ipService(node_hash[:ip]) : m.ipService(node_hash[:ipService])
						node_hash[:ipmiIP].nil? ? m.ipService : m.ipmiIP(node_hash[:ipmiIP])
						node_hash[:ipmiPassword].nil? ? m.ipmiPassword : m.ipmiPassword(node_hash[:ipmipass])
						node_hash[:ipmiPort].nil? ? m.ipmiport : m.ipmiport(node_hash[:ipmiport])
						node_hash[:ipmiUser].nil? ? m.ipmiuser : m.ipmiuser(node_hash[:ipmiuser])
						node_hash[:description].nil? ? m.description : m.description(node_hash[:description])
						m.port
						m.id_
						m.state
						m.cpuUsed
						m.ramUsed
						m.datastores {
							dsname = ""
							if not node_hash[:datastore].nil?
								dsname = node_hash[:datastore]
							end
							datastores = Nokogiri::XML.parse(hypervisor_info).xpath("/ns2:Host/resources/resourceType[text()='17']")
							m.totalSize(datastores.length)
		 					datastores.each do |dstore|
		 						m.datastore {
		 							thisname = info.at('elementName').to_str
		 							m.datastoreUUID
		 							m.directory(info.at('address').to_str)
		 							thisname == dsname ? m.enabled(true) : m.enabled(false)
		 							m.id_
		 							m.name(thisname)
		 							m.rootPath(info.at('address').to_str)
		 							m.size(info.at('units').to_str)
		 							m.usedSize(Integer(info.at('units').to_str) - Integer(info.at('availableUnits').to_str))
		 						}
							end
						}
						m.networkInterfaces {
							nicname = ""
							if not node_hash[:vswitch].nil?
								nicname = node_hash[:vswitch]
							end
							nics = Nokogiri::XML.parse(hypervisor_info).xpath("/ns2:Host/resources/resourceType[text()='10']")
							m.totalSize(nics.length)
							nics.each do |nic|
								m.networkinterface {
									tnicname = nic.parent.at('elementName').to_str
									if tnicname == nicname 
										m.link('rel' => 'networkservicetype', 'type' => 'application/vnd.abiquo.networkservicetype+xml', 'href' => "#{datacenter}/networkservicetypes/1")
									end
									m.name(tnicname)
									m.mac(nic.parent.at('address').to_str)
								}
							end
						}
					}
				end
				# Let's see if ther is no ds enabled, to enable one of them
				ent = Nokogiri::XML.parse(machine.to_xml)
				if ent.xpath("/machine/datastores/datastore/enabled[text()='true']").length == 0
					ent.xpath('/machine/datastores/datastore/enabled').first.content = 'true'
				end
				# same with nics
				if ent.xpath("/machine/networkInterfaces/networkinterface/link[@rel='networkservicetype']").length == 0
					t = Nokogiri::XML::Node.new('link', ent)
					t.set_attribute('rel', 'networkservicetype')
					t.set_attribute('type', 'application/vnd.abiquo.networkservicetype+xml')
					t.set_attribute('href', "#{datacenter}/networkservicetypes/1")
					ent.xpath('/machine/networkInterfaces/networkinterface').first.add_child(t)
				end
				begin 
					content = 'application/vnd.abiquo.machine+xml'
					resour = RestClient::Resource.new("#{@url}/machines", :user => @@username, :password => @@password)
					resp = resour.post "#{ent.xpath('/machine').to_xml}", :content_type => content
					return Abiquo::Machine.new(resp)
				rescue RestClient::Conflict
					$log.info "Requested Machine already exists."
					return nil
				end
			end
		end
	end
end

