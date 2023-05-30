require "spec_helper"

describe "User" do

  fixtures :users, :projects, :issues,
           :trackers, :issue_statuses, :enabled_modules,
           :projects, :enumerations, :roles, :members, :member_roles,
           :organizations

  let!(:issue_7) { Issue.find(7) }
  let!(:organization_1) { Organization.find(1) }
  let!(:user_2) { User.find(2) }
  let!(:user_3) { User.find(3) }

  before do
    user_2.update_attribute(:organization_id, organization_1.id)
    user_3.update_attribute(:organization_id, organization_1.id)
    User.current = user_2
  end

  context "User is allowed_to to view issues created by coauthors" do

    it "allows a user to see an issue created by a coauthor" do
      # expect(user_3.allowed_to?(:view_issues, issue_7.project)).to be true
    end

  end

end