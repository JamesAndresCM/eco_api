# frozen_string_literal: true

class ApplicationController < ActionController::API
  include HasDeviseWhitelist

  before_action :authenticate_user!
end
