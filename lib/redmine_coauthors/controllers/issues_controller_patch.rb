require_dependency 'issues_controller'

module RedmineCoauthors::Controllers
  module IssuesControllerPatch

    def set_author_organization
      if params[:issue].present?
        if params[:issue][:coauthors_status].present?
          @issue.coauthors_organization_id = @issue.author.organization_id
        end
      end
    end

  end
end

class IssuesController
  include RedmineCoauthors::Controllers::IssuesControllerPatch

  append_before_action :set_author_organization, :only => [:create, :update]

end
