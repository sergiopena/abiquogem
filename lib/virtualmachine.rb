require 'rest_client'
require 'nokogiri'

class Abiquo::VirtualMachine < Abiquo
	attr_accessor :apixml
	attr_accessor :url
	attr_accessor :vapp
	attr_accessor :id
	attr_accessor :cpu
	attr_accessor :hdsize
	attr_accessor :ha
	attr_accessor :idstate
	attr_accessor :idtype
	attr_accessor :name
	attr_accessor :password
	attr_accessor :ram
	attr_accessor :state
	attr_accessor :uuid
	attr_accessor :vdrpPort
	attr_accessor :vdrpIP

	def initialize()

	end

	def poweron()
			
	end

	def poweroff()

	end
	
	def self.get_vm_by_id(idVM)
		# Loop every vdc, vapp to find the vm.
		url = "http://#{@@server}/api/cloud/virtualdatacenters"
		vdcxml = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute
		Nokogiri::XML.parse(vdcxml).xpath('//virtualDatacenters/virtualDatacenter').each do |vdc|
			#$log.debug "#{vdc.inspect}"
			#$log.debug "Start VDC #{vdc.at('name').to_str}"
			virtapps = vdc.xpath('./link[@rel="virtualappliances"]')
			#$log.debug "ELPATH : #{virtapps.inspect}"
			unless virtapps.nil? or virtapps.to_s == ""
				url = virtapps.attribute("href").to_s
				#$log.info "VAPPURL: #{url}"
				vapxml = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute
				Nokogiri::XML.parse(vapxml).xpath('//virtualAppliances/virtualAppliance').each do |vapp|
					#$log.debug "VAPP: #{vapp.inspect}"
					#$log.info "Start vapp: #{vapp.at('name').to_str}"
					urlink = vapp.xpath('./link[@rel="virtualmachines"]')
					unless urlink.nil? or urlink.to_s == ""
						#$log.debug "URLINK: #{urlink.inspect}"
						url = urlink.attribute("href").to_s
						#$log.info "VMURL: #{url}"
						vmsxml = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute
					
						Nokogiri::XML.parse(vmsxml).xpath('//virtualMachines/virtualMachine').each do |vm|
							id = vm.at('id').to_str
							#$log.debug "NAME: #{name}"
							if id == idVM #VM found
								newvm = Abiquo::VirtualMachine.new()
								newvm.url = vm.xpath('./link[@rel="edit"]').attribute('href').to_str()
								newvm.vapp = vm.xpath('./link[@rel="virtualappliance"]').attribute('href').to_str()
								newvm.id = vm.at('id').to_str
								newvm.cpu = vm.at('cpu').to_str
								newvm.hdsize = vm.at('hdInBytes').to_str
								newvm.ha = vm.at('highDisponibility').to_str
								newvm.idstate = vm.at('idState').to_str
								newvm.idtype = vm.at('idType').to_str
								newvm.name = vm.at('name').to_str
								newvm.password = vm.at('password').to_str
								newvm.ram = vm.at('ram').to_str
								newvm.state = vm.at('state').to_str
								newvm.uuid = vm.at('uuid').to_str
								newvm.vdrpPort = vm.at('vdrpPort').to_str
								newvm.vdrpIP = vm.at('vdrpIP').to_str

								#$log.info "VM Object: #{newvm.inspect}"
								return newvm
							end
						end
					end
				end
			end
		end
		return nil
	end
		
	def self.get_vm_by_name(vmName)
		# Loop every vdc, vapp to find the vm.
		url = "http://#{@@server}/api/cloud/virtualdatacenters"
		vdcxml = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute
		Nokogiri::XML.parse(vdcxml).xpath('//virtualDatacenters/virtualDatacenter').each do |vdc|
			#$log.debug "#{vdc.inspect}"
			#$log.debug "Start VDC #{vdc.at('name').to_str}"
			virtapps = vdc.xpath('./link[@rel="virtualappliances"]')
			#$log.debug "ELPATH : #{virtapps.inspect}"
			unless virtapps.nil? or virtapps.to_s == ""
				url = virtapps.attribute("href").to_s
				#$log.info "VAPPURL: #{url}"
				vapxml = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute
				Nokogiri::XML.parse(vapxml).xpath('//virtualAppliances/virtualAppliance').each do |vapp|
					#$log.debug "VAPP: #{vapp.inspect}"
					#$log.info "Start vapp: #{vapp.at('name').to_str}"
					urlink = vapp.xpath('./link[@rel="virtualmachines"]')
					unless urlink.nil? or urlink.to_s == ""
						#$log.debug "URLINK: #{urlink.inspect}"
						url = urlink.attribute("href").to_s
						#$log.info "VMURL: #{url}"
						vmsxml = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute
					
						Nokogiri::XML.parse(vmsxml).xpath('//virtualMachines/virtualMachine').each do |vm|
							name = vm.at('name').to_str
							#$log.debug "NAME: #{name}"
							if name == vmName #VM found
								newvm = Abiquo::VirtualMachine.new()
								newvm.apixml = vm.to_xml
								newvm.url = vm.xpath('./link[@rel="edit"]').attribute('href').to_str()
								newvm.vapp = vm.xpath('./link[@rel="virtualappliance"]').attribute('href').to_str()
								newvm.id = vm.at('id').to_str
								newvm.cpu = vm.at('cpu').to_str
								newvm.hdsize = vm.at('hdInBytes').to_str
								newvm.ha = vm.at('highDisponibility').to_str
								newvm.idstate = vm.at('idState').to_str
								newvm.idtype = vm.at('idType').to_str
								newvm.name = vm.at('name').to_str
								newvm.password = vm.at('password').to_str
								newvm.ram = vm.at('ram').to_str
								newvm.state = vm.at('state').to_str
								newvm.uuid = vm.at('uuid').to_str
								newvm.vdrpPort = vm.at('vdrpPort').to_str
								newvm.vdrpIP = vm.at('vdrpIP').to_str

								#$log.info "VM Object: #{newvm.inspect}"
								return newvm
							end
						end
					end
				end
			end
		end
		return nil
	end

	def get_xml()
		# TODO
		# Generate XML definition for this VM
		# We need disks and network devices
		vmxml = Nokogiri::XML.parse(apixml)
		## ROOT DISK
		url = vmxml.xpath('//linkp[@rel="virtualmachinetemplate"]').attribute("href")
		template_resp = RestClient::Request.new(:method => :get, :url => url, :user => @@username, :password => @@password).execute
		template_xml = Nokogiri::XML.parse(template_resp)

	end

#	def buildxml(data...)
#		builder = Nokogiri::XML::Builder.new do |xml|
#			xml.domain('type' => 'kvm') {
#				xml.name(name)
#				xml.uuid(uuid)
#				xml.memory(ram)
#				xml.currentMemory(ram)
#				xml.vcpu(cpu)
#				xml.os {
#					xml.type_('arch' => 'x86_64', 'machine' => 'pc-0.13') { xml.text('hvm') }
#					xml.loader('/usr/bin/qemu-kvm')
#					xml.boot('dev' => 'hd')
#				}
#				xml.features {
#					xml.acpi
#					xml.apic
#					xml.pae
#				}
#				xml.clock('offset' => 'utc')
#				xml.on_poweroff('destroy')
#				xml.on_reboot('restart')
#				xml.on_crash('destroy')
#				xml.devices {
#					xml.emulator('/usr/bin/qemu-kvm')
#					xml.disk('type' => 'file') {
#
#					}
#					xml.controller('type' => 'ide', 'index' => '0') {
#						xml.address('type' => 'pci', 'domain' => '0x0000', 'bus' => '0x00', 'slot' => '0x01', 'function' => '0x1')
#					}
#					xml.interface {
#
#					}
#					xml.serial('type' => 'pty') {
#						xml.target('port' => '0')
#					}
#					xml.console('type' => 'pty') {
#						xml.target('type' => 'serial', 'port' => '0')
#					}
#					xml.input('type' => 'mouse', 'bus' => 'ps2')
#					xml.graphics('type' => 'vnc', 'port' => vdrpPort, 'autoport' => 'no', 'listen' => '0.0.0.0') {
#						xml.listen('type' => 'address', 'address' => '0.0.0.0')
#					}
#					xml.video {
#						xml.model('type' => 'cirrus', 'vram' => '9216', 'heads' => '1')
#						xml.address('type' => 'pci', 'domain' => '0x0000', 'bus' => '0x00', 'slot' => '0x02', 'function' => '0x0')
#					}
#					xml.memballoon('model' => 'virtio') {
#						xml.address('type' => 'pci', 'domain' => '0x0000', 'bus' => '0x00', 'slot' => '0x04', 'function' => '0x0')
#					}
#				}
#			}
#		end
#		return builder.to_xml
#	end
end


#    <emulator>/usr/bin/qemu-kvm</emulator>
#    <disk type='file' device='disk'>
#      <driver name='qemu' type='raw'/>
#      <source file='/ABQ_4ad7e10e-3c0f-4af0-8623-6714491fc456'/>
#      <target dev='hda' bus='ide'/>
#      <address type='drive' controller='0' bus='0' unit='0'/>
#    </disk>

#    <interface type='bridge'>
#      <mac address='52:54:00:16:95:98'/>
#      <source bridge='abiquo_2'/>
#      <model type='e1000'/>
#      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
#    </interface>

#    <memballoon model='virtio'>
#      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
#    </memballoon>
#  </devices>
#</domain>
