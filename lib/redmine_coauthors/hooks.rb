# frozen_string_literal: true

module RedmineCoauthors
  module Hooks

    class ModelHook < Redmine::Hook::Listener
      def after_plugins_loaded(_context = {})
        require_relative 'models/issue'
        require_relative 'helpers/issues_helper'
        require_relative 'controllers/issues_controller'
        require_relative 'controllers/application_controller_patch'
      end
    end

    class Hooks < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(context)
        stylesheet_link_tag("coauthors", :plugin => "redmine_coauthors")
      end
    end
  end
end
