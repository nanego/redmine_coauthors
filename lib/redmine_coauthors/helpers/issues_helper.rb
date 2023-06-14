require_dependency 'issues_helper'

module PluginRedmineCoauthors
  module IssuesHelper
    def options_for_coauthors_select(issue)
      possible_values = Issue::POSSIBLE_COAUTHORS_STATUSES.map do |key, value|
        case key
        when 2
          val = "#{l(value)} (#{issue.author.organization&.name_with_parents} #{l(:and)} #{issue.author.organization&.parent&.name_with_parents})"
        when 1
          val = "#{l(value)} (#{issue.author.organization&.name_with_parents})"
        else
          val = l(value)
        end
        [val, key]
      end
      options_for_select(possible_values, issue.persisted? ? issue.coauthors_status : "1")
    end

    # Returns the textual representation of a single journal detail
    # Core properties are 'attr', 'attachment' or 'cf' : this patch specify how to display 'attr' journal details when the updated field is 'authorized_viewers'
    def show_detail(detail, no_html = false, options = {})
      if detail.property == 'attr' && detail.prop_key == 'coauthors_status'
        field = detail.prop_key.to_s.gsub(/\_id$/, "")
        label = l(("field_" + field).to_sym)

        value = "'#{l(Issue::POSSIBLE_COAUTHORS_STATUSES[detail.value.to_i])}'"
        old_value = "'#{l(Issue::POSSIBLE_COAUTHORS_STATUSES[detail.old_value.to_i])}'"

        if detail.old_value.present?
          l(:text_journal_changed, :label => label, :old => old_value, :new => value).html_safe
        elsif multiple
          l(:text_journal_added, :label => label, :value => value).html_safe
        else
          l(:text_journal_set_to, :label => label, :value => value).html_safe
        end
      else
        # Process standard fields
        super
      end
    end
  end
end

IssuesHelper.prepend PluginRedmineCoauthors::IssuesHelper
ActionView::Base.prepend IssuesHelper
