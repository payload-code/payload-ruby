require 'payload/arm/request'


module Payload

    class Session
        attr_accessor :api_key, :api_url

        def initialize(api_key, api_url=nil)
            @api_key = api_key
            @api_url = api_url || Payload.URL
        end

        def query(cls)
            return Payload::ARMRequest.new(cls, self)
        end

        def create(*args, **data)
            return Payload::ARMRequest.new(session: self).create(*args, **data)
        end

        def update(**update)
            return Payload::ARMRequest.new(session: self)._request('Put', id: update.id, json: update)
        end

        def delete(objects)
            return Payload::ARMRequest.new(session: self).delete(objects)
        end

        def ==(other)
            return false unless other.is_a?(Session)
    
            # Compare the attributes for equality
            api_key == other.api_key &&
            api_url == other.api_url
        end  
    end
end