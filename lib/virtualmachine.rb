require 'rest_client'
require 'nokogiri'

class Abiquo::VirtualMachine < Abiquo
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
								newvm.url = vm.xpath('./link[@rel="edit"]').attribute('href').to_str()
								newvm.vapp = vm.xpath('./link[@rel="virtualappliance"]').attribute('href').to_str()
								newvm.id = vm.at('id').to_str
								newvm.cpu = vm.at('cpu').to_strque 
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

	end
end
