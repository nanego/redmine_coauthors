require "spec_helper"

RSpec.describe IssuesController, type: :controller do

  render_views

  fixtures :issues, :trackers, :issue_statuses, :enabled_modules,
           :projects, :enumerations, :users, :roles, :members, :member_roles,
           :projects_trackers, :workflows

  let!(:issue_7) { Issue.find(7) }
  let!(:author_organization) { Organization.find_or_create_by(name: "coauthors organisation") }
  let!(:different_organization) { Organization.find_or_create_by(name: "different organisation") }
  let!(:user_2) { User.find(2) }
  let!(:user_7) { User.find(7) }

  before do
    @request.session[:user_id] = 7

    # Add users to organization
    user_2.update_attribute(:organization_id, author_organization.id)
    user_7.update_attribute(:organization_id, author_organization.id)

    # Activate coauthors module
    issue_7.project.enable_module! :coauthored_issues

    # issue 7 is shared with author organization
    issue_7.update_attribute(:coauthors_organization_id, author_organization.id)
    issue_7.update_attribute(:coauthors_status, 1)

    # Remove role for non members
    Role.builtin(true).each { |role| role.remove_permission! :view_issues }
    # Add a role to another project
    membership = Member.new(user: user_7, project_id: 2) # Member of an other project
    membership.roles << Role.find(1)
    membership.save!
  end

  describe "#show" do
    it "allows access to coauthors" do
      get :show, params: { id: issue_7.id }
      expect(response).to be_successful
      expect(response.body).to have_selector("div.subject:contains('Issue due today')")
    end

    it "forbid access to other users" do
      user_7.update_attribute(:organization_id, different_organization.id)
      get :show, params: { id: issue_7.id }
      expect(response).to be_forbidden
    end
  end

  describe "issues#index" do

    context "in a project" do
      it "forbid access to other users" do
        user_7.update_attribute(:organization_id, different_organization.id)
        get :index, params: { project_id: issue_7.project.identifier }
        expect(response).to have_http_status(:forbidden)
      end

      # pending "allows access to coauthors, or not..."
    end

    context "outside any project" do
      it "does not list the issue when the current user is not in the same organization" do
        user_7.update_attribute(:organization_id, different_organization.id)
        get :index, params: {}
        expect(response).to be_successful
        expect(response.body).to have_selector("td.subject:contains('Issue on project 2')")
        expect(response.body).to_not have_selector("td.subject:contains('#{issue_7.subject}')")
      end

      it "lists the issue when the current user is in the same organization" do
        get :index, params: {}
        expect(response).to be_successful
        expect(response.body).to have_selector("td.subject:contains('Issue on project 2')")
        expect(response.body).to have_selector("td.subject:contains('#{issue_7.subject}')")
      end
    end

  end

end
