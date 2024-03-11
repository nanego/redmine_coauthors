require_dependency 'application_controller'

module RedmineCoauthors::Controllers
  module ApplicationControllerPatch

    def authorize(ctrl = params[:controller], action = params[:action], global = false)
      if ctrl == "issues" && (%w(show edit update).include?(action))
        if @issue.present? && @issue.shared_with_coauthors?(User.current)
          true
        else
          super
        end
      else
        super
      end
    end

  end
end

ApplicationController.prepend RedmineCoauthors::Controllers::ApplicationControllerPatch
