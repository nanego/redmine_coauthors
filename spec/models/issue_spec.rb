require 'spec_helper'

RSpec.describe Issue, :type => :model do

  fixtures :issues, :trackers, :issue_statuses, :enabled_modules,
           :projects, :enumerations, :users, :roles, :members, :member_roles

  let!(:issue_7) { Issue.find(7) }
  let!(:user_2) { User.find(2) }
  let!(:user_7) { User.find(7) }
  let!(:author_organization) { Organization.find_or_create_by(name: "coauthors organisation") }

  before do
    user_2.update_attribute(:organization_id, author_organization.id)
    user_7.update_attribute(:organization_id, author_organization.id)

    # issue 7 is shared with author organization
    issue_7.update_attribute(:coauthors_organization_id, author_organization.id)
    issue_7.update_attribute(:coauthors_status, 1)

    # Remove role for non members
    Role.builtin(true).each { |role| role.remove_permission! :view_issues }
  end

  context "An issue have multiple coauthors" do
    it "returns an array with only the author if the issue has no coauthors-organization" do
      issue_7.update_attribute(:coauthors_organization_id, nil)
      expect(issue_7.coauthors).to eq [user_2]
    end

    it "returns an array with the author and the organization users if the issue has an coauthors-organization" do
      issue_7.update_attribute(:coauthors_organization_id, author_organization.id)
      expect(author_organization.users).to include(user_2)
      expect(author_organization.users).to include(user_7)
      expect(issue_7.coauthors).to eq [user_2, user_7]
    end

    describe "visible?" do
      it "does not allow access when we are not coauthor" do
        issue_7.update_attribute(:coauthors_organization_id, nil)
        expect(issue_7.visible?(user_7)).to be false
      end

      it "allows a user to see an issue created by a coauthor" do
        issue_7.update_attribute(:coauthors_organization_id, author_organization.id)
        expect(issue_7.visible?(user_7)).to be true
      end
    end

  end

end
