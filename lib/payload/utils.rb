module Payload

	def self.subclasses(super_cls)
		ObjectSpace.each_object(Class).select { |cls| cls < super_cls }
	end

	def self.get_cls(data)
		match = nil
		for cls in subclasses(Payload::ARMObject)
			if cls.spec['object'] != data['object']
				next
			end

			if not cls.poly and not match
				match = cls

			elsif cls.poly

				invalid = false
				cls.poly.each do |key, value|
					if data[key] != value
						invalid = true
					end
				end

				if invalid
					next
				end

				match = cls
				break
			end
		end

		match
	end

end
