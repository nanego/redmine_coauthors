require_dependency 'issues_helper'

module PluginRedmineCoauthors
  module IssuesHelper
    def options_for_coauthors_select(issue)
      possible_values = Issue::POSSIBLE_COAUTHORS_STATUSES.map do |key, value|
        case key
        when 1
          val = "#{l(value)} (#{issue.author.organization&.name_with_parents})"
        else
          val = l(value)
        end
        [val, key]
      end
      options_for_select(possible_values, issue.persisted? ? issue.coauthors_status : "1")
    end
  end
end

IssuesHelper.prepend PluginRedmineCoauthors::IssuesHelper
ActionView::Base.send(:include, IssuesHelper)
