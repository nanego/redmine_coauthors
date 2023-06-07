require_dependency 'issues_controller'

class IssuesController

  append_before_action :set_author_organization, :only => [:create]

  private

  def set_author_organization
    if params[:issue].present?
      if params[:issue][:coauthors_status].present?
        @issue.coauthors_organization_id = @issue.author.organization_id
      end
    end
  end

end
