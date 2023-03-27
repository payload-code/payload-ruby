require_relative "../exceptions"
require_relative "../utils"
require "net/http"
require "uri"
require "json"

module Payload
	class ARMRequest
		@cls = nil

		def initialize(cls=nil)
			@cls = cls
			@filters = {}
		end

		def select(*args, **data)
			if @cls.poly
				data = data.merge(@cls.poly)
			end

			return self
		end

		def filter_by(*args, **data)
			if @cls.poly
				data = data.merge(@cls.poly)
			end

			@filters = @filters.merge(data)

			return self
		end

		def all()
			return self._request('Get')
		end

		def get(id)
			if id.nil? || id.empty?
				throw 'id cannot be empty'
			end

			return self._request('Get', id: id)
		end

		def update(**updates)
			return self.filter_by(mode: 'query')
				._request('Put', json: updates)
		end

		def delete(objects)
			deletes = objects.map {|o| o.id }.join('|')
			return self.filter_by(mode: 'query', id: deletes)
				._request('Delete')
		end

		def create(data)
			if data.is_a? Array
				data = data.map do |obj|
					if obj.kind_of?(ARMObject)
						if @cls and not obj.instance_of?(@cls)
							throw "All objects must be of the same type"
						end

						@cls = obj.class
						obj = obj.data
					end

					if @cls.poly
						obj = obj.merge(@cls.poly)
					end

					obj
				end

				data = { object: 'list', values: data }
			else
				if @cls.poly
					data = data.merge(@cls.poly)
				end
			end

			return self._request('Post', json: data)
		end

		def _request(method, id: nil, json: nil)
			if @cls.spec.key?("endpoint")
				endpoint = @cls.spec["endpoint"]
			else
				endpoint = "/"+@cls.spec["object"]+"s"
			end

			if id
				endpoint = File.join(endpoint, id)
			end

			url = URI.join(Payload::api_url, endpoint)
			url.query = URI.encode_www_form(@filters)

			http = Net::HTTP.new(url.host, url.port)

			if url.port == 443
				http.use_ssl = true
			end

			request = Net::HTTP.const_get(method).new(url.request_uri)
			request.basic_auth(Payload::api_key, '')

			if json
				request.body = json.to_json
				request.add_field('Content-Type', 'application/json')
			end

			response = http.request(request)

			begin
				data = JSON.parse(response.body)
			rescue JSON::ParserError
				if response.code == '500'
					raise Payload::InternalError.new
				else
					raise Place::UnknownResponse.new
				end
			end

			if response.code == '200'
				if data['object'] == 'list'
					return data['values'].map do |obj|
						cls = Payload::get_cls(obj)
						if cls.nil?
							obj
						else
							cls.new(obj)
						end
					end
				else
					return Payload::get_cls(data).new(data)
				end
			else
				for error in Payload::subclasses(Payload::PayloadError)
					if error.code != response.code or error.name.split('::')[-1] != data['error_type']
						next
					end

					raise error.new(data['description'], data)
				end

				raise Payload::BadRequest.new(data['description'], data)
			end
		end
	end
end
