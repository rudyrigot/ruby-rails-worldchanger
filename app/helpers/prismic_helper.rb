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

  def link_resolver(maybe_ref)
    Prismic::LinkResolver.new(maybe_ref) do |doc|
      maybe_ref_param = maybe_ref ? "?ref=#{maybe_ref}" : '' ;
      case doc.link_type
      when "homepage"
        root_path + maybe_ref_param
      when "article"
        tour_path + maybe_ref_param if doc.id == api.bookmark("tour")
        pricing_path + maybe_ref_param if doc.id == api.bookmark("pricing")
        about_path + maybe_ref_param if doc.id == api.bookmark("about")
        faq_path + maybe_ref_param if doc.id == api.bookmark("faq")
      when "argument"
        tour_path + maybe_ref_param + "#" + doc.id
      when "pricing"
        pricing_path + maybe_ref_param + "#" + doc.id
      when "author"
        about_path + maybe_ref_param + "#" + doc.id
      when "faq"
        faq_path + maybe_ref_param + "#" + doc.id
      when "blog"
        blogpost_path(doc.id, doc.slug) + maybe_ref_param
      else
        "#unsupportedtype/"+doc.link_type
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
