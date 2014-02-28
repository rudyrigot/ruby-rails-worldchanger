class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :set_ref, :set_maybe_ref
  before_action :set_blog_categories, only: [:blog, :blogcategory, :blogpost, :blogsearch]

  def index
  	@document = PrismicService.get_document(api.bookmark("homepage"), api, @ref)
    @user_friendly_arguments = api.form("arguments")
                    .query(%([[:d = at(document.tags, ["userfriendly"])][:d = at(document.tags, ["featured"])]]))
                    .orderings("[my.argument.priority desc]")
                    .submit(@ref)
    @design_arguments = api.form("arguments")
                    .query(%([[:d = at(document.tags, ["design"])][:d = at(document.tags, ["featured"])]]))
                    .orderings("[my.argument.priority desc]")
                    .submit(@ref)
    @questions = api.form("questions")
                    .query(%([[:d = at(document.tags, ["featured"])]]))
                    .orderings("[my.faq.priority desc]")
                    .submit(@ref)
    set_minimum_price
  end

  def tour
    @document = PrismicService.get_document(api.bookmark("tour"), api, @ref)
    @arguments = api.form("arguments")
                    .orderings("[my.argument.priority desc]")
                    .submit(@ref)
    @homepage = PrismicService.get_document(api.bookmark("homepage"), api, @ref)
    set_minimum_price
  end

  def pricing
    @document = PrismicService.get_document(api.bookmark("pricing"), api, @ref)
    @plans = api.form("plans")
                    .orderings("[my.pricing.price]")
                    .submit(@ref)
    @questions = api.form("questions")
                    .query(%([[:d = any(document.tags, ["pricing"])]]))
                    .orderings("[my.faq.priority desc]")
                    .submit(@ref)
  end

  def about
  	@document = PrismicService.get_document(api.bookmark("about"), api, @ref)
  	@staff = api.form("staff")
                    .orderings("[my.author.level]")
                    .submit(@ref)
  end

  def faq
    @document = PrismicService.get_document(api.bookmark("faq"), api, @ref)
    @questions = api.form("questions")
                    .orderings("[my.faq.priority desc]")
                    .submit(@ref)
  end

  def blog
    @documents = api.form("blog")
                    .orderings("[my.blog.date desc]")
                    .submit(@ref)
    render :bloglist
  end

  def blogcategory
    @documents = api.form("blog")
                    .query(%([[:d = at(my.blog.category, "#{params[:slug]}")]]))
                    .orderings("[my.blog.date desc]")
                    .submit(@ref)
    render :bloglist
  end

  def blogsearch
    @documents = api.form("blog")
                    .query(%([[:d = fulltext(document, "#{params[:q]}")]]))
                    .orderings("[my.blog.date desc]")
                    .submit(@ref)
    render :bloglist
  end

  def blogpost
    id = params[:id]
    slug = params[:slug]

    @document = PrismicService.get_document(id, api, @ref)

    # Checking if the doc / slug combination is right, and doing what needs to be done
    @slug_checker = PrismicService.slug_checker(@document, slug)
    if !@slug_checker[:correct]
      render status: :not_found, file: "#{Rails.root}/public/404", layout: false if !@slug_checker[:redirect]
      redirect_to blogpost_path(id, @document.slug), status: :moved_permanently if @slug_checker[:redirect]
    else # slug is right

      # Retrieving the author in order to display their full name and title
      @author = PrismicService.get_document(@document.fragments['author'].id, api, @ref)

      # Retieving the potential related posts
      if @document.fragments['relatedpost']
        @relatedposts = @document.fragments['relatedpost'].fragments.select do |doclink|
          !doclink.broken? # suppressing if broken
        end
        @relatedposts.map! do |doclink|
          PrismicService.get_document(doclink.id, api, @ref) #replacing doclinks with documents
        end
      end

    end
  end

  private

  def set_minimum_price
    plans_by_price = api.form("plans")
      .orderings("[my.pricing.price]")
      .submit(@ref)
    begin
      @minimum_price = plans_by_price[0]['pricing.price'].value.to_i
    rescue
      logger.info("Minimum requirements to display the minimum price are not met (is there any plan published right now?)")
      @minimum_price = 0
    end
  end

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
