require_dependency 'issue'

module RedmineCoauthors
  module IssuePatch

    # Returns true if usr or current user is allowed to view the issue
    def visible?(usr = nil)
      visibility = super
      if visibility
        return visibility
      else
        usr ||= User.current
        if coauthors.include?(usr)
          super(author)
        else
          visibility
        end
      end
    end

    module ClassMethods
      def visible_condition(user, options = {})
        user_organization = user.organization
        if user_organization.present?
          coauthored_issues_statement = Issue.joins(:author => :organization).where(organizations: { id: user_organization.id }).select(:id).to_sql
          "(#{super} OR #{Issue.table_name}.id IN (#{coauthored_issues_statement}) )"
        else
          super
        end
      end
    end

    def self.prepended(base)
      class << base
        prepend ClassMethods
      end
    end

  end
end

class Issue < ActiveRecord::Base

  prepend RedmineCoauthors::IssuePatch

  POSSIBLE_COAUTHORS_STATUSES = { 0 => :share_with_no_one,
                                  1 => :share_with_my_organization }

  belongs_to :coauthors_organization,
             class_name: 'Organization',
             optional: true

  safe_attributes 'coauthors_status', 'coauthors_organization_id'

  def coauthors
    coauthors = [author]
    coauthors |= self.coauthors_organization.users if author.present? && self.coauthors_organization.present?
    coauthors
  end

  def allow_coauthors?(current_user)
    self.project.module_enabled?("coauthored_issues") &&
      current_user.allowed_to?(:edit_coauthors, self.project) &&
      current_user == self.author
  end

  # def authors_organizations
  #  [author.organization]
  # end

end
