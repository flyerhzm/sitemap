describe "Sitemap::Routes" do
  class Post
    attr_accessor :id, :name, :updated_at

    def initialize(id, name, updated_at)
      @id = id
      @name = name
      @updated_at = updated_at
    end

    def to_param
      id
    end

    def year 
      updated_at.year
    end
    def month
      updated_at.month
    end
    def day
      updated_at.day
    end
  end

  before(:each) do
    @post1 = Post.new(1, 'post1', DateTime.new(2009, 8, 9, 0, 0, 0))
    @post2 = Post.new(2, 'post2', DateTime.new(2009, 8, 10, 0, 0, 0))

    Post.stubs(:all).returns([@post1, @post2])
  end

  context "namespaces" do
    it "should get index and show for resources" do
      Sitemap::Routes.draw do |map|
        map.resources :posts
      end
      Sitemap::Routes.parse
      Sitemap::Routes.paths.should == ['/posts', '/posts/1', '/posts/2']
    end

    it "should add collection" do 
      Sitemap::Routes.draw do |map|
        map.resources :posts, :collection => {:all => :get}
      end
      Sitemap::Routes.parse
      Sitemap::Routes.paths.should == ['/posts/all', '/posts', '/posts/1', '/posts/2']
    end

    it "should add member" do 
      Sitemap::Routes.draw do |map|
        map.resources :posts, :member => {:display => :get}
      end
      Sitemap::Routes.parse
      Sitemap::Routes.paths.should == ['/posts', '/posts/1/display', '/posts/2/display', '/posts/1', '/posts/2']
    end
  end

  it "should parse root" do
    Sitemap::Routes.draw do |map|
      map.root :controller => 'posts', :action => 'index'
    end
    Sitemap::Routes.parse
    Sitemap::Routes.paths.should == ['']
  end

  it "should parse namespace" do
    Sitemap::Routes.draw do |map|
      map.namespace(:admin) do |admin|
        admin.resources :posts
      end
    end
    Sitemap::Routes.parse
    Sitemap::Routes.paths.should == ['/admin/posts', '/admin/posts/1', '/admin/posts/2']
  end

  it "should parse connect" do
    Sitemap::Routes.draw do |map|
      map.connect 'posts/:year/:month/:day', :controller => 'posts', :action => 'find_by_date', :substitution => {:model => 'Post', :year => 'year', :month => 'month', :day => 'day'}
    end
    Sitemap::Routes.parse
    Sitemap::Routes.paths.should == ['/posts/2009/8/9', '/posts/2009/8/10']
  end

  it "should parse named_route" do
    Sitemap::Routes.draw do |map|
      map.sitemap '/sitemap', :controller => 'sitemaps', :action => 'index'
    end
    Sitemap::Routes.parse
    Sitemap::Routes.paths.should == ['/sitemap']
  end
end
