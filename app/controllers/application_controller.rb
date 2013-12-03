class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :set_ref

=begin
	In this controller, orderings are passed as a second parameter of create_search_form.
	This is a tweak while waiting for the orderings to be officially added in the API forms,
	you should NEVER do that in production code, as it is a hack and is not guaranteed
	to work forever.
	Rather, the proper method will be to pass the orderings in the `ordering` method
	to apply on the search form, that doesn't exist yet. It will look like this:

	api.create_search_form("arguments")
       .query(%([[:d = at(document.tags, ["userfriendly"])][:d = at(document.tags, ["featured"])]]))
       .orderings("[my.argument.priority desc]")
       .submit(@ref)
=end

  def index
  	@document = PrismicService.get_document(api.bookmark("homepage"), api, @ref)
    @user_friendly_arguments = api.create_search_form("arguments", {"orderings" => "[my.argument.priority desc]"})
                    .query(%([[:d = at(document.tags, ["userfriendly"])][:d = at(document.tags, ["featured"])]]))
                    .submit(@ref)
    @design_arguments = api.create_search_form("arguments", {"orderings" => "[my.argument.priority desc]"})
                    .query(%([[:d = at(document.tags, ["design"])][:d = at(document.tags, ["featured"])]]))
                    .submit(@ref)
    @minimum_price = api.create_search_form("plans", {"orderings" => "[my.pricing.price]"}).submit(@ref)[0]
                    .fragments['price'].value.to_i
    @questions = api.create_search_form("questions", {"orderings" => "[my.faq.priority desc]"})
                    .query(%([[:d = at(document.tags, ["featured"])]]))
                    .submit(@ref)
  end

  def tour
    @document = PrismicService.get_document(api.bookmark("tour"), api, @ref)
    @arguments = api.create_search_form("arguments", {"orderings" => "[my.argument.priority desc]"})
                    .submit(@ref)
  end

  def pricing
    @document = PrismicService.get_document(api.bookmark("pricing"), api, @ref)
    @plans = api.create_search_form("plans", {"orderings" => "[my.pricing.price]"})
                    .submit(@ref)
  end

  def about
  	@document = PrismicService.get_document(api.bookmark("about"), api, @ref)
  	@staff = api.create_search_form("staff", {"orderings" => "[my.author.level]"})
                    .submit(@ref)
  end

  def faq
    @document = PrismicService.get_document(api.bookmark("faq"), api, @ref)
    @questions = api.create_search_form("questions", {"orderings" => "[my.faq.priority desc]"})
                    .submit(@ref)
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

  # OAuth pages controllers

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

  def api
    @access_token = session['ACCESS_TOKEN']
    begin
      @api ||= PrismicService.init_api(@access_token)
    rescue Prismic::API::PrismicWSConnectionError
      # In case there is a connection error, it could come from an expired token,
      # so let's try it again after discarding the access token
      session['ACCESS_TOKEN'] = @access_token = nil
      @api ||= PrismicService.init_api(@access_token)
    end
  end

end
