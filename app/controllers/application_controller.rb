class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :set_ref, :set_maybe_ref
  before_action :set_blog_categories, only: [:blog, :blogcategory, :blogpost, :blogsearch]

  def index
  	@document = PrismicService.get_document(api.bookmark("homepage"), api, @ref)
    @user_friendly_arguments = api.create_search_form("arguments")
                    .query(%([[:d = at(document.tags, ["userfriendly"])][:d = at(document.tags, ["featured"])]]))
                    .set("orderings", "[my.argument.priority desc]")
                    .submit(@ref)
    @design_arguments = api.create_search_form("arguments")
                    .query(%([[:d = at(document.tags, ["design"])][:d = at(document.tags, ["featured"])]]))
                    .set("orderings", "[my.argument.priority desc]")
                    .submit(@ref)
    @minimum_price = api.create_search_form("plans")
                    .set("orderings", "[my.pricing.price]").submit(@ref)[0]
                    .fragments['price'].value.to_i
    @questions = api.create_search_form("questions")
                    .query(%([[:d = at(document.tags, ["featured"])]]))
                    .set("orderings", "[my.faq.priority desc]")
                    .submit(@ref)
  end

  def tour
    @document = PrismicService.get_document(api.bookmark("tour"), api, @ref)
    @arguments = api.create_search_form("arguments")
                    .set("orderings", "[my.argument.priority desc]")
                    .submit(@ref)
  end

  def pricing
    @document = PrismicService.get_document(api.bookmark("pricing"), api, @ref)
    @plans = api.create_search_form("plans")
                    .set("orderings", "[my.pricing.price]")
                    .submit(@ref)
    @questions = api.create_search_form("questions")
                    .query(%([[:d = any(document.tags, ["pricing"])]]))
                    .set("orderings", "[my.faq.priority desc]")
                    .submit(@ref)
  end

  def about
  	@document = PrismicService.get_document(api.bookmark("about"), api, @ref)
  	@staff = api.create_search_form("staff")
                    .set("orderings", "[my.author.level]")
                    .submit(@ref)
  end

  def faq
    @document = PrismicService.get_document(api.bookmark("faq"), api, @ref)
    @questions = api.create_search_form("questions")
                    .set("orderings", "[my.faq.priority desc]")
                    .submit(@ref)
  end

  def blog
    @documents = api.create_search_form("blog")
                    .set("orderings", "[my.blog.date desc]")
                    .submit(@ref)
    render :bloglist
  end

  def blogcategory
    @documents = api.create_search_form("blog")
                    .query(%([[:d = at(my.blog.category, "#{params[:slug]}")]]))
                    .set("orderings", "[my.blog.date desc]")
                    .submit(@ref)
    render :bloglist
  end

  def blogsearch
    @documents = api.create_search_form("blog")
                    .query(%([[:d = fulltext(document, "#{params[:q]}")]]))
                    .set("orderings", "[my.blog.date desc]")
                    .submit(@ref)
    render :bloglist
  end

  def blogpost
    id = params[:id]
    slug = params[:slug]

    @document = PrismicService.get_document(id, api, @ref)
    if @document.nil?
      render inline: "Document not found", status: :not_found, file: "#{Rails.root}/public/404", layout: false
    elsif slug == @document.slug

      # Retrieving the author in order to display their full name and title
      @author = PrismicService.get_document(@document.fragments['author'].id, api, @ref)

      # Overriding the way images in structured text are rendered into HTML.
      # The problem was that they are rendered with "width" and "height", making them non-flexible.
      # Also, the overriding method nests them in a <p>, in order to be able to center them.
      @document.fragments['body'].blocks.each do |block|
        if block.is_a? Prismic::Fragments::StructuredText::Block::Image
          def block.as_html(linkresolver = nil); %(<p class="image"><img src="#{self.url}"></p>); end
        end
      end

      # Retieving the potential related posts
      if @document.fragments['relatedpost']
        @relatedposts = @document.fragments['relatedpost'].fragments.select do |doclink|
          !doclink.broken? # suppressing if broken
        end
        @relatedposts.map! do |doclink|
          PrismicService.get_document(doclink.id, api, @ref) #replacing doclinks with documents
        end
      end

    elsif @document.slugs.include?(slug)
      redirect_to blogpost_path(id, @document.slug), status: :moved_permanently
    else
      render inline: "Document not found", status: :not_found, file: "#{Rails.root}/public/404", layout: false
    end
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

  def set_maybe_ref
    @maybe_ref = (params[:ref] != '' ? params[:ref] : nil)
  end

  def set_blog_categories
    @blog_categories = PrismicService.config('blog_categories')
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
