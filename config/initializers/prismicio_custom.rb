module Prismic

	class Document
		# Simply to avoid typing .html_safe at the end of each as_html call.
		def as_html_safe(link_resolver = nil)
			as_html(link_resolver).html_safe
		end
	end

	module Fragments
		class Fragment

			# Simply to avoid typing .html_safe at the end of each as_html call.
			def as_html_safe(link_resolver = nil)
				as_html(link_resolver).html_safe
			end
		end

		class StructuredText
			class Block
				class Image

					# Overriding the way the official kit serialized images (simply because it is needed in the design)
					def as_html(link_resolver = nil)
						%(<p class="image"><img src="#{url}"></p>)
					end
				end
			end
		end

	end
end