class Abiquo::API
	attr_read :host
	attr_read :user
	attr_read :password

	def initialize(host, user, password)
		@host = host
		@user = user
		@password = password
	end

	def _httpget(url)
		tmpurl = url.split('/')
		(0..tmpurl.index('api')-1).each do |x|
			tmpurl.delete_at(0)
		end
		parsedurl = "http://#{@user}:#{@password}@#{@host}/#{tmpurl.join('/')}"

		$log.info "Retrieving to #{parsedurl}"
		response = RestClient.get( parsedurl )


		if response.code == 200
			xmloutput = XmlSimple.xml_in(response)
			return xmloutput
		end

	rescue => e
		$log.error e.message

	end

	def _httppost(url, entity)
		#TODO
	end
