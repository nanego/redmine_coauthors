require_dependency 'issue'

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
        if authors.include?(usr)
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
          coauthored_issues_statement = Issue.joins(:author => :organization).where(organizations: {id: user_organization.id}).select(:id).to_sql
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

  def authors
    authors = [author]
    authors |= author.organization.users if author.present? && author.organization.present?
    authors
  end

  # def authors_organizations
  #  [author.organization]
  # end

end
