require 'spec_helper'

RSpec.describe Issue, :type => :model do

  fixtures :issues, :trackers, :issue_statuses, :enabled_modules,
           :projects, :enumerations, :users, :roles, :members, :member_roles

  let!(:issue_7) { Issue.find(7) }
  let!(:user_2) { User.find(2) }
  let!(:user_7) { User.find(7) }
  let!(:user_8) { User.find(8) }
  let!(:author_parent_organization) { Organization.find_or_create_by(name: "author parent organisation") }
  let!(:author_organization) { Organization.find_or_create_by(name: "coauthors organisation") }

  before do
    user_2.update_attribute(:organization_id, author_organization.id)
    user_7.update_attribute(:organization_id, author_organization.id)
    user_7.update_attribute(:mail_notification, 'all')
    user_8.update_attribute(:organization_id, author_parent_organization.id) # let's say user8 is a member of the parent organization

    # issue 7 is shared with author organization
    issue_7.update_attribute(:coauthors_organization_id, author_organization.id)
    issue_7.update_attribute(:coauthors_status, 1)

    # Activate co-authors module
    issue_7.project.enable_module!("coauthored_issues")

    # author organization has a parent organization
    author_organization.update_attribute(:parent_id, author_parent_organization.id)

    # Remove role for non members
    Role.builtin(true).each { |role| role.remove_permission! :view_issues }
  end

  context "An issue have multiple coauthors" do
    it "returns an array with only the author if the issue has no coauthors-organization" do
      issue_7.update_attribute(:coauthors_organization_id, nil)
      expect(issue_7.coauthors).to eq [user_2]
    end

    it "returns an array with only the author if the co-authors module is not enabled in the project" do
      issue_7.project.disable_module!("coauthored_issues")
      issue_7.reload
      issue_7.update_attribute(:coauthors_organization_id, author_organization.id)
      expect(author_organization.users).to include(user_2)
      expect(author_organization.users).to include(user_7)
      expect(issue_7.coauthors).to eq [user_2]
    end

    it "returns an array with the author and the organization users if the issue has an coauthors-organization" do
      issue_7.update_attribute(:coauthors_organization_id, author_organization.id)
      expect(author_organization.users).to include(user_2)
      expect(author_organization.users).to include(user_7)
      expect(issue_7.coauthors).to eq [user_2, user_7]
    end

    it "returns an array with the author and the organizations users if the issue has several coauthors-organizations" do
      issue_7.update_attribute(:coauthors_status, 2) # shared with author organization & parent organization
      issue_7.update_attribute(:coauthors_organization_id, author_organization.id)
      expect(author_organization.users).to include(user_2)
      expect(author_organization.users).to include(user_7)
      expect(author_organization.users).to_not include(user_8)
      expect(issue_7.coauthors.sort).to eq [user_8, user_2, user_7].sort
    end

    describe "visible?" do
      it "does not allow access when we are not coauthor" do
        issue_7.update_attribute(:coauthors_organization_id, nil)
        expect(issue_7.visible?(user_7)).to be false
        expect(issue_7.visible?(user_8)).to be false
      end

      it "allows a user to see an issue created by a coauthor" do
        issue_7.update_attribute(:coauthors_organization_id, author_organization.id)
        expect(issue_7.visible?(user_7)).to be true
        expect(issue_7.visible?(user_8)).to be false
      end

      it "does not allow access when the issue coauthor status is set to zero / not shared" do
        issue_7.update_attribute(:coauthors_status, 0)
        issue_7.update_attribute(:coauthors_organization_id, author_organization.id)
        expect(issue_7.visible?(user_7)).to be false
        expect(issue_7.visible?(user_8)).to be false
      end

      it "allows a user to see an issue created by a coauthor from a child organization" do
        issue_7.update_attribute(:coauthors_status, 2) # shared with author organization & parent organization
        issue_7.update_attribute(:coauthors_organization_id, author_organization.id)
        expect(issue_7.visible?(user_7)).to be true
        expect(issue_7.visible?(user_8)).to be true
      end
    end

    describe "notified_users" do
      it "notifies users who are co-authors" do
        notified_as_coauthor = issue_7.notified_as_coauthor
        expect(notified_as_coauthor).to_not be_nil
        expect(notified_as_coauthor).to_not include User.anonymous
        expect(notified_as_coauthor).to_not include user_2 # author
        expect(notified_as_coauthor).to include user_7 # co-author
        expect(notified_as_coauthor).to_not include user_8 # not co-author
      end

      it "notifies all co-authors" do
        notified_users = issue_7.notified_users
        expect(notified_users).to_not be_nil
        expect(notified_users).to_not include User.anonymous
        expect(notified_users).to include user_2 # author
        expect(notified_users).to include user_7 # co-author
        expect(notified_users).to_not include user_8 # not co-author
      end

      it "notifies all co-authors and organization parent users when status is 2" do
        issue_7.update_attribute(:coauthors_status, 2) # shared with author organization & parent organization
        user_8.update_attribute(:mail_notification, 'all')
        notified_users = issue_7.notified_users
        expect(notified_users).to_not be_nil
        expect(notified_users).to_not include User.anonymous
        expect(notified_users).to include user_2 # author
        expect(notified_users).to include user_7 # co-author
        expect(notified_users).to include user_8 # co-author as member of parent organization
      end
    end

  end

end
