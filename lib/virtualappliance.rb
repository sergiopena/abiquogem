class Abiquo::VirtualAppliance < Abiquo::VirtualDatacenter
	attr_accessor :url
	attr_accessor :state
	attr_accessor :vapp
	attr_accessor :vdc
	attr_accessor :id

	def initialize(vapp)
		self.vapp = vapp 
		self.id = vapp["id"][0]
		self.vdc = self._getlinks(self.vapp, 'virtualdatacenter').split('/')[-1]
	end

	def list_virtualmachines
		url = self._getlinks self.vapp,'virtualmachines'
		xml = self._httpget(url)
		output = []
		xml['virtualMachine'].each { |x|
			output << x["id"][0]
		}
		return output
	end

	def get_vm_by_id(id)
		url = "api/cloud/virtualdatacenters/#{self.vdc}/virtualappliances/#{self.id}/virtualmachines/#{id}"
		xml = self._httpget(url)

		return xml
	end

	def get_state()
		response = RestClient.get(@url)
		xml = XmlSimple.xml_in(response)
		$log.debug "Vapp.getstate #{xml['state']}"
		@state = xml['state']
		return xml['state']
	end

	def delete()
		$log.debug "Trying to delte #{url}"
		self.get_state
		case @state[0]
		when "NOT_DEPLOYED"
			RestClient.delete(@url)
			$log.info "Deleted #{url}"
		when "DEPLOYED"
			$log.info "Vapps is deployed #{url}"
			self.undeploy
			RestClient.delete(@url)

		end
	end

	def undeploy()
		$log.info "Trying to undeploy #{url}"
		builder = Builder::XmlMarkup.new()
		virtualmachinetask = builder.virtualmachinetask { |x| x.forceUndeploy("true")}
		response = RestClient.post( @url+'/action/undeploy', virtualmachinetask, 
				:Accept => "application/vnd.abiquo.acceptedrequest+xml", 
				:Content_type => "application/vnd.abiquo.virtualmachinetask+xml")
		$log.debug response
		xml = XmlSimple.xml_in(response)
		xml['link'].each do |x|
			if x['rel'] == "status"
				while self.check_task(x['href']) == "STARTED" do
					$log.debug "Task #{self.check_task(x['href'])} #{x['href']}"
					sleep 5
				end
			end
		end
	end	

	def check_task(url)
		$log.info "Checking task #{url}"
		link = url.to_s.split('/').slice(2,url.length).join("/")
		task_url = "http://#{@@username}:#{@@password}@#{link}"	
		$log.info "Task returned #{task_url}"
		response = RestClient.get(task_url)
		return XmlSimple.xml_in(response)['state'][0]
	end

end