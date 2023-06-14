require "spec_helper"

describe "IssuesHelperPatch" do
  include ApplicationHelper
  include IssuesHelper
  include CustomFieldsHelper
  include ERB::Util
  include ActionView::Helpers::TagHelper

  fixtures :projects, :trackers, :issue_statuses, :issues,
           :enumerations, :users, :issue_categories,
           :projects_trackers,
           :roles,
           :member_roles,
           :members,
           :enabled_modules,
           :custom_fields,
           :versions

  before do
    set_language_if_valid('en')
    User.current = nil
  end

  let(:journal) { Journal.new(:journalized => User.find(5), :user_id => 1) }

  describe "coauthors' changes" do
    it "displays a journal entry when coatuhor_status has changed" do
      detail = JournalDetail.new(:journal => journal, :property => 'attr', :old_value => "0", :value => "1", :prop_key => 'coauthors_status')
      expect(show_detail(detail, true)).to eq "Coauthors changed from 'No, I'm the only author' to 'Yes, share with my organization'"
    end
  end
end
