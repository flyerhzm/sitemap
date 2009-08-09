describe "Sitemap::Routes" do
  class Post
    attr_accessor :id, :name

    def initialize(id, name)
      @id = id
      @name = name
    end

    def to_param
      id
    end
  end

  before(:each) do
    @post1 = Post.new(1, 'post1')
    @post2 = Post.new(2, 'post2')

    Post.stubs(:all).returns([@post1, @post2])
  end

  it "should get index and show for resources" do
    Sitemap::Routes.draw do |map|
      map.resources :posts
    end
    Sitemap::Routes.parse
    Sitemap::Routes.paths.should == ['/posts', '/posts/1', '/posts/2']
  end

  it "should parse root" do
    Sitemap::Routes.draw do |map|
      map.root :controller => 'posts', :action => 'index'
    end
    Sitemap::Routes.parse
    Sitemap::Routes.paths.should == ['']
  end
end
