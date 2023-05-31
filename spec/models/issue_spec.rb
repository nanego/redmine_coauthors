require 'spec_helper'

RSpec.describe Issue, :type => :model do

  fixtures :issues, :trackers, :issue_statuses, :enabled_modules,
           :projects, :enumerations, :users, :roles, :members, :member_roles

  let!(:issue_7) { Issue.find(7) }
  let!(:organization) { Organization.create(name: "coauthors organisation") }
  let!(:user_2) { User.find(2) }
  let!(:user_7) { User.find(7) }

  before do
    user_2.update_attribute(:organization_id, organization.id)
    user_7.update_attribute(:organization_id, organization.id)

    # Remove role for non members
    Role.builtin(true).each { |role| role.remove_permission! :view_issues }
  end

  context "An issue have multiple authors" do
    it "returns an array with only the author if the author has no organization" do
      user_2.update_attribute(:organization_id, nil)
      expect(issue_7.authors).to eq [user_2]
    end

    it "returns an array with the author and the organization users if the author has an organization" do
      expect(organization.users).to include(user_2)
      expect(issue_7.authors).to eq [user_2, user_7]
    end

    describe "visible?" do
      it "does not allow access when we are not coauthor" do
        user_2.update_attribute(:organization_id, nil)
        issue_7.reload
        expect(issue_7.visible?(user_7)).to be false
      end

      it "allows a user to see an issue created by a coauthor" do
        user_2.update_attribute(:organization_id, organization.id)
        issue_7.reload
        expect(issue_7.visible?(user_7)).to be true
      end
    end

  end

end
