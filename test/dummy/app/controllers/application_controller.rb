class ApplicationController < ActionController::Base
  include Terrier::RenderingBase

  def page_title
    @title || self.class.name.gsub('Controller', '').titleize
  end

  def home
    @title = "Home"
  end

end
