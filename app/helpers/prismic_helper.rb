module PrismicHelper

  def link_to_doc(doc, ref, html_options={}, &blk)
    link_to(url_to_doc(doc, ref), html_options, &blk)
  end

  # For a given document, describes its URL on your front-office.
  # You really should edit this method, so that it supports all the document types your users might link to.
  #
  # Beware: doc is not a Prismic::Document, but a Prismic::Fragments::DocumentLink,
  # containing only the information you already have without querying more (see DocumentLink documentation)
  def link_resolver(maybe_ref)
    @link_resolver ||= Prismic::LinkResolver.new(maybe_ref) do |doc|
      case doc.link_type
      when "homepage"
        root_path(ref: maybe_ref)
      when "article" # This type is special: the URL is built depending on the document's prismic.io bookmark
        case doc.id
        when api.bookmark("tour")
          tour_path(ref: maybe_ref)
        when api.bookmark("pricing")
          pricing_path(ref: maybe_ref)
        when api.bookmark("about")
          about_path(ref: maybe_ref)
        when api.bookmark("faq")
          faq_path(ref: maybe_ref)
        else
          raise "Article of id #{doc.id} doesn't have a known bookmark"
        end
      when "argument"
        tour_path(ref: maybe_ref) + "#" + doc.id
      when "pricing"
        pricing_path(ref: maybe_ref) + "#" + doc.id
      when "author"
        about_path(ref: maybe_ref) + "#" + doc.id
      when "faq"
        faq_path(ref: maybe_ref) + "#" + doc.id
      when "blog"
        blogpost_path(doc.id, doc.slug, ref: maybe_ref)
      else
        raise "link_resolver doesn't know how to write URLs for #{doc.link_type} type."
      end
    end
  end

  # Checks if the user is connected or the app has an access token set for all users.
  def privileged_access?
    connected? || PrismicService.access_token
  end

  # Checks if the user is connected to prismic.io's OAuth2.
  def connected?
    !!@access_token
  end

  # Allows to call api directly in the view
  # (to check the bookmarks, for instance, you shouldn't query in the view!)
  def api
    @api
  end

  # Return the actual used reference
  def ref
    @ref ||= maybe_ref || api.master_ref.ref
  end

  # Return the set reference
  def maybe_ref
    @maybe_ref ||= (params[:ref].blank? ? nil : params[:ref])
  end

end
