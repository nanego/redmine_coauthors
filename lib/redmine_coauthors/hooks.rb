# frozen_string_literal: true

module RedmineCoauthors
  module Hooks
    class ModelHook < Redmine::Hook::Listener
      def after_plugins_loaded(_context = {})
        require_relative 'models/issue_patch'
      end
    end
  end
end
