module PrismicHelper

  def url_to_doc(doc, ref)
    document_path(id: doc.id, slug: doc.slug, ref: ref)
  end
  def link_to_doc(doc, ref, html_options={}, &blk)
    link_to(url_to_doc(doc, ref), html_options, &blk)
  end

  def display_doc(doc, ref)
    doc.as_html(link_resolver(ref)).html_safe
  end

  def link_resolver(ref)
    Prismic::LinkResolver.new(ref) do |doc|
      case doc.link_type
      when "homepage"
        root_path
      when "article"
        tour_path if doc.id == api.bookmark("tour")
        pricing_path if doc.id == api.bookmark("pricing")
      when "argument"
        tour_path + "#" + doc.id
      when "pricing"
        pricing_path + "#" + doc.id
      else
        # I'm leaving this here as long as I'm not done developing all the templates, it gives me a default one
        document_path(id: doc.id, slug: doc.slug)
      end
    end
  end

  def privileged_access?
    connected? || PrismicService.access_token
  end

  def connected?
    !!@access_token
  end

  def current_ref
    @ref
  end

  def master_ref
    @api.master_ref.ref
  end

  def api
    @api
  end

end
