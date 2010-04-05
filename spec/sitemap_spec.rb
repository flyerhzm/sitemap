require 'spec_helper'

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

  class Category
    attr_accessor :id, :name, :posts

    def initialize(id, name)
      @id = id
      @name = name
    end

    def to_param
      id
    end
  end

  before(:each) do
    @datetime1 = DateTime.new(2009, 8, 9, 0, 0, 0)
    @datetime2 = DateTime.new(2009, 8, 10, 0, 0, 0)
    @post1 = Post.new(1, 'post1', @datetime1)
    @post2 = Post.new(2, 'post2', @datetime2)

    Post.stubs(:all).returns([@post1, @post2])
  end

  context "location" do
    context "namespaces" do
      it "should get index and show for resources" do
        Sitemap::Routes.draw do |map|
          map.resources :posts
        end
        Sitemap::Routes.parse
        Sitemap::Routes.results.collect {|result| result[:location]}.should == ['/posts', '/posts/1', '/posts/2']
      end

      it "should add collection" do 
        Sitemap::Routes.draw do |map|
          map.resources :posts, :collection => {:all => :get}
        end
        Sitemap::Routes.parse
        Sitemap::Routes.results.collect {|result| result[:location]}.should == ['/posts/all', '/posts', '/posts/1', '/posts/2']
      end

      it "should add member" do 
        Sitemap::Routes.draw do |map|
          map.resources :posts, :member => {:display => :get}
        end
        Sitemap::Routes.parse
        Sitemap::Routes.results.collect {|result| result[:location]}.should == ['/posts', '/posts/1/display', '/posts/2/display', '/posts/1', '/posts/2']
      end

      it "should add except" do
        Sitemap::Routes.draw do |map|
          map.resources :posts, :except => 'show'
        end
        Sitemap::Routes.parse
        Sitemap::Routes.results.collect {|result| result[:location]}.should == ['/posts']
      end
    end

    it "should parse root" do
      Sitemap::Routes.draw do |map|
        map.root :controller => 'posts', :action => 'index'
      end
      Sitemap::Routes.parse
      Sitemap::Routes.results.collect {|result| result[:location]}.should == ['']
    end

    it "should parse namespace" do
      Sitemap::Routes.draw do |map|
        map.namespace(:admin) do |admin|
          admin.resources :posts
        end
      end
      Sitemap::Routes.parse
      Sitemap::Routes.results.collect {|result| result[:location]}.should == ['/admin/posts', '/admin/posts/1', '/admin/posts/2']
    end

    it "should parse connect" do
      Sitemap::Routes.draw do |map|
        map.connect 'posts/:year/:month/:day', :controller => 'posts', :action => 'find_by_date', :substitution => {:model => 'Post', :year => 'year', :month => 'month', :day => 'day'}
      end
      Sitemap::Routes.parse
      Sitemap::Routes.results.collect {|result| result[:location]}.should == ['/posts/2009/8/9', '/posts/2009/8/10']
    end

    it "should parse connect without duplicate" do
      @post3 = Post.new(3, 'post2', DateTime.new(2009, 8, 10, 0, 0, 0))
      Post.stubs(:all).returns([@post1, @post2, @post3])

      Sitemap::Routes.draw do |map|
        map.connect 'posts/:year/:month/:day', :controller => 'posts', :action => 'find_by_date', :substitution => {:model => 'Post', :year => 'year', :month => 'month', :day => 'day'}
      end
      Sitemap::Routes.parse
      Sitemap::Routes.results.collect {|result| result[:location]}.should == ['/posts/2009/8/9', '/posts/2009/8/10', '/posts/2009/8/10']
    end

    it "should parse connect with substitution array" do
      Sitemap::Routes.draw do |map|
        map.connect 'posts/:locale', :controller => 'posts', :action => 'index', :substitution => {:locale => ['en', 'zh', 'fr']}
      end
      Sitemap::Routes.parse
      Sitemap::Routes.results.collect {|result| result[:location]}.should == ['/posts/en', '/posts/zh', '/posts/fr']
    end

    it "should parse named_route" do
      Sitemap::Routes.draw do |map|
        map.sitemap '/sitemap', :controller => 'sitemaps', :action => 'index'
      end
      Sitemap::Routes.parse
      Sitemap::Routes.results.collect {|result| result[:location]}.should == ['/sitemap']
    end

    it "should parse nested resources" do
      @category = Category.new(1, 'category')
      @category.posts = [@post1, @post2]
      Category.stubs(:all).returns([@category])

      Sitemap::Routes.draw do |map|
        map.resources :categories do |category|
          category.resources :posts
        end
      end
      Sitemap::Routes.parse
      Sitemap::Routes.results.collect {|result| result[:location]}.should == ['/categories/1/posts', '/categories/1/posts/1', '/categories/1/posts/2', '/categories', '/categories/1']
    end
  end

  context 'priority' do 
    it "should parse resources" do
      Sitemap::Routes.draw do |map|
        map.resources :posts, :priority => 0.9
      end
      Sitemap::Routes.parse
      Sitemap::Routes.results.collect {|result| result[:priority]}.should == [0.9, 0.9, 0.9]
    end

    it "should parse connect" do
      Sitemap::Routes.draw do |map|
        map.connect 'posts/:year/:month/:day', :controller => 'posts', :action => 'find_by_date', :substitution => {:model => 'Post', :year => 'year', :month => 'month', :day => 'day'}, :priority => 0.8
      end
      Sitemap::Routes.parse
      Sitemap::Routes.results.collect {|result| result[:priority]}.should == [0.8, 0.8]
    end
  end

  context "changefreq" do
    it "should parse resources" do
      Sitemap::Routes.draw do |map|
        map.resources :posts, :changefreq => Sitemap::ChangeFreq::ALWAYS
      end
      Sitemap::Routes.parse
      Sitemap::Routes.results.collect {|result| result[:changefreq]}.should == ['always', 'always', 'always']
    end

    it "should parse connect" do
      Sitemap::Routes.draw do |map|
        map.connect 'posts/:year/:month/:day', :controller => 'posts', :action => 'find_by_date', :substitution => {:model => 'Post', :year => 'year', :month => 'month', :day => 'day'}, :changefreq => Sitemap::ChangeFreq::MONTHLY
      end
      Sitemap::Routes.parse
      Sitemap::Routes.results.collect {|result| result[:changefreq]}.should == ['monthly', 'monthly']
    end

    it "should parse root" do
      Sitemap::Routes.draw do |map|
        map.root :controller => 'posts', :action => 'index', :changefreq => Sitemap::ChangeFreq::MONTHLY
      end
      Sitemap::Routes.parse
      Sitemap::Routes.results.collect {|result| result[:changefreq]}.should == ['monthly']
    end
  end

  context "lastmod" do
    it "should get lastmod by resource" do
      now = Time.now
      Time.stubs(:now).returns(now)
      Sitemap::Routes.draw do |map|
        map.resources :posts
      end
      Sitemap::Routes.parse
      Sitemap::Routes.results.collect {|result| result[:lastmod]}.should == [nil, @datetime1, @datetime2]
    end
  end

end
