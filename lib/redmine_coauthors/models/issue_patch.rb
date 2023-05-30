require_dependency 'issue'

class Issue < ActiveRecord::Base

  def authors
    authors = [author]
    authors |= author.organization.users if author.organization.present?
    authors
  end

  # def authors_organizations
  #  [author.organization]
  # end

end