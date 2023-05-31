require_dependency 'issue'

require_dependency 'issue'

module RedmineCoauthors
  module IssuePatch

    # Returns true if usr or current user is allowed to view the issue
    def visible?(usr = nil)
      usr ||= User.current
      if authors.include?(usr)
        usr = author
      end
      super(usr)
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
