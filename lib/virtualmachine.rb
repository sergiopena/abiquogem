require 'nokogiri'

class Abiquo::VirtualMachine < Abiquo::VirtualAppliance
	attr_accessor :url
	attr_accessor :state
	attr_accessor :vapp
	attr_accessor :id

#	def initialize(vm)
#		self.vm = vm
#		self.id = vm["id"][0]
#		self.vdc = self._getlinks(self.vapp, 'virtualdatacenter').split('/')[-1]
#	end

	def get_vm_by_id(idVM)
		# Loop every vdc, vapp to find the vm.
		url = "api/cloud/virtualdatacenters"
		vdcs = _httpget(utl)
		vdcs.each do |vdc|
			virtapps = _httpget(_getlinks(vdc, "virtualappliances"))
			virtapps.each do |vapp|
				vms = _httpget(_getlinks(vdc, "virtualmachines"))
				vms.each do |vm|
					vm_id = vm['id']
					if vm_id == idVM #VM found
						return vm
					end
				end
			end
		end
		return nil
	end
