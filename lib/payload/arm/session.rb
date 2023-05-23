require 'payload/arm/request'


module Payload

    class Session
        attr_accessor :api_key, :api_url

        def initialize(api_key, api_url=nil)
            @api_key = api_key
            @api_url = api_url || Payload.URL

            Payload.constants.each do |c|
                val = Payload.const_get(c)
                if val.is_a?(Class) && val < Payload::ARMObject
                    define_singleton_method(c) { Payload::ARMObjectWrapper.new(val, self) }
                end
            end
        end

        def _get_request(cls = nil)
            return Payload::ARMRequest.new(cls, self)
        end

        def query(cls)
            return self._get_request(cls)
        end

        def create(objects)
            return self._get_request().create(objects)
        end

        def update(objects)
            return self._get_request().update_all(objects)
        end

        def delete(objects)
            return self._get_request().delete_all(objects)
        end

        def ==(other)
            return false unless other.is_a?(Session)

            # Compare the attributes for equality
            api_key == other.api_key &&
            api_url == other.api_url
        end

        def to_s
            "#{api_key} @ #{api_url}"
        end
    end
end
