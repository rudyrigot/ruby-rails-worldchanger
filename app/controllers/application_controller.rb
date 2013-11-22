class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :set_ref

  def index
  	@document = PrismicService.get_document(api.bookmark("homepage"), api, @ref)
    @title = first_title(@document) # will be suppressed with next gem
    @user_friendly_arguments = api.create_search_form("everything", {"orderings" => "[my.argument.priority desc]"})
                    .query(%([[:d = at(document.type, "argument")][:d = at(document.tags, ["userfriendly"])][:d = at(document.tags, ["featured"])]]))
                    .submit(@ref)
    @design_arguments = api.create_search_form("everything", {"orderings" => "[my.argument.priority desc]"})
                    .query(%([[:d = at(document.type, "argument")][:d = at(document.tags, ["design"])][:d = at(document.tags, ["featured"])]]))
                    .submit(@ref)
    # the second argument in the create_search_form methog is put here while waiting
    # for the "orderings" field to be made available in /api
  end

  def tour
    @document = PrismicService.get_document(api.bookmark("tour"), api, @ref)
    @title = first_title(@document) # will be suppressed with next gem
    @user_friendly_arguments = api.create_search_form("everything", {"orderings" => "[my.argument.priority desc]"})
                    .query(%([[:d = at(document.type, "argument")][:d = at(document.tags, ["userfriendly"])]]))
                    .submit(@ref)
    @design_arguments = api.create_search_form("everything", {"orderings" => "[my.argument.priority desc]"})
                    .query(%([[:d = at(document.type, "argument")][:d = at(document.tags, ["design"])]]))
                    .submit(@ref)
    # the second argument in the create_search_form methog is put here while waiting
    # for the "orderings" field to be made available in /api
  end

  def document
    id = params[:id]
    slug = params[:slug]

    @document = PrismicService.get_document(id, api, @ref)
    if @document.nil?
      render inline: "Document not found", status: :not_found
    elsif slug == @document.slug
      @document
    elsif document.slugs.contains(slug)
      redirect_to document_application_path(id, slug), status: :moved_permanently
    else
      render inline: "Document not found", status: :not_found
    end
  end

  def search
    @documents = api.create_search_form("everything")
                    .query(%([[:d = fulltext(document, "#{params[:q]}")]]))
                    .submit(@ref)
  end

  def get_callback_url
    callback_url(redirect_uri: request.env['referer'])
  end

  def signin
    url = api.oauth_initiate_url({
      client_id: PrismicService.config("client_id"),
      redirect_uri: get_callback_url,
      scope: "master+releases"
    })
    redirect_to url
  end

  def callback
    access_token = api.oauth_check_token({
      grant_type: "authorization_code",
      code: params[:code],
      redirect_uri: get_callback_url,
      client_id: PrismicService.config("client_id"),
      client_secret: PrismicService.config("client_secret"),
    })
    if access_token
      session['ACCESS_TOKEN'] = access_token
      url = params['redirect_uri'] || root_path
      redirect_to url
    else
      render "Can't sign you in", status: :unauthorized
    end
  end

  def signout
    session['ACCESS_TOKEN'] = nil
    redirect_to :root
  end

  private

  # Before_action

  def set_ref
    @ref = params[:ref].blank? ? api.master_ref.ref : params[:ref]
  end

  # Helper methods

  # gets either the first, highest title in the document, or if there's none, the homepage's headline.
  # to be suppressed when the mext RubyGem makes it through with the Document::first_title method
  def first_title(document)
    title = false
  	if document
  		max_level = 6 # any title with a higher level kicks the current one out
  		document.fragments.each do |_, fragment|
  			if fragment.is_a? Prismic::Fragments::StructuredText
  				fragment.blocks.each do |block|
  					if block.is_a?(Prismic::Fragments::StructuredText::Block::Heading)
  						if block.level < max_level
  							title = block.text
  							max_level = block.level # new maximum
  						end
  					end
  				end
  			end
  		end
  	end
	 title
  end

  def api
    @access_token = session['ACCESS_TOKEN']
    @api ||= PrismicService.init_api(@access_token)
  end

end
