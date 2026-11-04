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

  describe "sharing permissions" do
    let(:new_issue_params) { { tracker_id: 1, subject: "Shared issue", priority_id: 5 } }

    before { Role.find(1).add_permission! :edit_coauthors }

    def update_issue_7(user_id, attributes)
      @request.session[:user_id] = user_id
      patch :update, params: { id: issue_7.id, issue: attributes }
      expect(response).to have_http_status(:found)
      issue_7.reload
    end

    it "lets an author with edit_coauthors share a new issue with their own organization only" do
      @request.session[:user_id] = 2
      post :create, params: { project_id: 1, issue: new_issue_params.merge(coauthors_status: 1, coauthors_organization_id: different_organization.id) }

      issue = Issue.find_by!(subject: "Shared issue")
      expect(issue.coauthors_status).to eq(1)
      expect(issue.coauthors_organization_id).to eq(author_organization.id)
    end

    it "does not let an author without edit_coauthors share a new issue" do
      Role.find(1).remove_permission! :edit_coauthors
      @request.session[:user_id] = 2
      post :create, params: { project_id: 1, issue: new_issue_params.merge(coauthors_status: 1, coauthors_organization_id: different_organization.id) }

      issue = Issue.find_by!(subject: "Shared issue")
      expect(issue.coauthors_status).to eq(0)
      expect(issue.coauthors_organization_id).to be_nil
    end

    it "does not let another user with edit rights widen the sharing" do
      update_issue_7(3, coauthors_status: 3)
      expect(issue_7.coauthors_status).to eq(1)
    end

    it "does not let another user with edit rights change the shared organization" do
      update_issue_7(3, coauthors_organization_id: different_organization.id)
      expect(issue_7.coauthors_organization_id).to eq(author_organization.id)
    end

    it "does not let the author pick another organization" do
      update_issue_7(2, coauthors_organization_id: different_organization.id)
      expect(issue_7.coauthors_organization_id).to eq(author_organization.id)
    end

    [2, 3].each do |status|
      it "lets an author with edit_coauthors choose sharing level #{status}" do
        update_issue_7(2, coauthors_status: status)
        expect(issue_7.coauthors_status).to eq(status)
        expect(issue_7.coauthors_organization_id).to eq(author_organization.id)
      end
    end

    context "when copying a shared issue" do
      before do
        Role.find(1).add_permission! :copy_issues
        Role.find(2).add_permission! :copy_issues
      end

      def copy_issue_7(user_id, attributes = {})
        @request.session[:user_id] = user_id
        post :create, params: { project_id: 1, copy_from: issue_7.id, issue: new_issue_params.merge(attributes) }
        Issue.find_by!(subject: "Shared issue")
      end

      it "resets the sharing for the new author" do
        copy = copy_issue_7(3)
        expect(copy.author_id).to eq(3)
        expect(copy.coauthors_status).to eq(0)
        expect(copy.coauthors_organization_id).to be_nil
      end

      it "lets an author with edit_coauthors share the copy with their own organization" do
        copy = copy_issue_7(2, coauthors_status: 2)
        expect(copy.coauthors_status).to eq(2)
        expect(copy.coauthors_organization_id).to eq(author_organization.id)
      end
    end

    it "lets an admin change the sharing of an issue" do
      update_issue_7(1, coauthors_status: 2)
      expect(issue_7.coauthors_status).to eq(2)
      expect(issue_7.coauthors_organization_id).to eq(author_organization.id)
    end
  end

end
