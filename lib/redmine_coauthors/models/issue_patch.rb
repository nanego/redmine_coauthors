require_dependency 'issue'

module RedmineCoauthors::Models
  module IssuePatch

    # Returns true if usr or current user is allowed to view the issue
    def visible?(usr = nil)
      visibility = super
      if visibility
        return visibility
      else
        usr ||= User.current
        if coauthors.include?(usr) && usr != author
          super(author)
        else
          visibility
        end
      end
    end

    # Returns the users that should be notified
    def notified_users
      super | notified_as_coauthor
    end

    def editable?(user = User.current)
      super || (shared_with_coauthors?(user) && author.present? ? super(author.present? ? author : user) : false)
    end

    # Returns true if user or current user is allowed to edit the issue
    def attributes_editable?(user = User.current)
      super || (shared_with_coauthors?(user) && author.present? ? super(author.present? ? author : user) : false)
    end

    def attachments_addable?(user = User.current)
      super || (shared_with_coauthors?(user) && author.present? ? super(author.present? ? author : user) : false)
    end

    # Overrides Redmine::Acts::Attachable::InstanceMethods#attachments_editable?
    def attachments_editable?(user = User.current)
      super || (shared_with_coauthors?(user) && author.present? ? super(author) : false)
    end

    # Returns true if user or current user is allowed to add notes to the issue
    def notes_addable?(user = User.current)
      super || (shared_with_coauthors?(user) && author.present? ? super(author) : false)
    end

    # Returns true if user or current user is allowed to delete the issue
    def deletable?(user = User.current)
      super || (shared_with_coauthors?(user) && author.present? ? super(author) : false)
    end

    # Overrides Redmine::Acts::Attachable::InstanceMethods#attachments_deletable?
    def attachments_deletable?(user = User.current)
      super || (shared_with_coauthors?(user) && author.present? ? super(author) : false)
    end

    def visible_custom_field_values(user = nil)
      if shared_with_coauthors?(user)
        super | super(author)
      else
        super
      end
    end

    def safe_attributes=(attrs, user = User.current)
      if shared_with_coauthors?(user)
        super | super(attrs, author)
      else
        super
      end
    end

    def workflow_rule_by_attribute(user = nil)
      if shared_with_coauthors?(user)
        super(author)
      else
        super
      end
    end

    def visible_journals_with_index(user = User.current)
      if shared_with_coauthors?(user)
        super(author)
      else
        super
      end
    end

    def new_statuses_allowed_to(user = User.current, include_default = false)
      if shared_with_coauthors?(user)
        super | super(author, include_default)
      else
        super
      end
    end

    def css_classes(user = User.current)
      if shared_with_coauthors?(user)
        super(author)
      else
        super
      end
    end

    def allowed_target_projects_for_subtask(user = User.current)
      if shared_with_coauthors?(user)
        super(author)
      else
        super
      end
    end

    def allowed_target_projects(user = User.current, scope = nil)
      if shared_with_coauthors?(user)
        super(author, scope)
      else
        super
      end
    end

    def allowed_target_trackers(user = User.current)
      if shared_with_coauthors?(user)
        super(author)
      else
        super
      end
    end

    module ClassMethods
      def visible_condition(user, options = {})
        user_organization = user.organization
        if user_organization.present?

          user_organization_child_ids = user_organization.child_ids

          # coauthors_status 1, 2 or 3
          coauthored_issues_statement_from_user_organization = Issue.joins(:coauthors_organization)
                                                                    .where(organizations: { id: user_organization.id })
                                                                    .where(coauthors_status: [1, 2, 3])
                                                                    .select(:id)
                                                                    .to_sql
          coauthors_statement_through_same_organization = "#{Issue.table_name}.id IN (#{coauthored_issues_statement_from_user_organization})"

          # coauthors_status 2 or 3
          coauthored_issues_statement_from_child_organization = Issue.joins(:coauthors_organization)
                                                                     .where(organizations: { id: user_organization_child_ids })
                                                                     .where(coauthors_status: [2, 3])
                                                                     .select(:id)
                                                                     .to_sql
          coauthors_statement_through_child_organization = "#{Issue.table_name}.id IN (#{coauthored_issues_statement_from_child_organization})"

          # coauthors_status 3
          coauthored_issues_statement_from_grandchild_organization = Issue.joins(:coauthors_organization)
                                                                          .where(organizations: { parent_id: user_organization_child_ids })
                                                                          .where(coauthors_status: 3)
                                                                          .select(:id)
                                                                          .to_sql
          coauthors_statement_through_grandchild_organization = "#{Issue.table_name}.id IN (#{coauthored_issues_statement_from_grandchild_organization})"

          "(#{super}
              OR #{coauthors_statement_through_same_organization}
              OR #{coauthors_statement_through_child_organization}
              OR #{coauthors_statement_through_grandchild_organization})"
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

class Issue

  prepend RedmineCoauthors::Models::IssuePatch

  POSSIBLE_COAUTHORS_STATUSES = { 0 => :share_with_no_one,
                                  1 => :share_with_my_organization,
                                  2 => :share_with_my_organization_and_parent,
                                  3 => :share_with_my_organization_and_two_parents }

  belongs_to :coauthors_organization,
             class_name: 'Organization',
             optional: true

  safe_attributes 'coauthors_status', 'coauthors_organization_id'

  def coauthors_organizations(status: nil, author_organization: nil)
    status ||= coauthors_status
    author_organization ||= self.coauthors_organization
    return [] if author_organization.blank?

    case status
    when 3
      [author_organization.parent.try(:parent), author_organization.parent, author_organization].compact
    when 2
      [author_organization.parent, author_organization].compact
    when 1
      [author_organization].compact
    else
      []
    end
  end

  def coauthors
    coauthors = [author]
    if module_coauthors_enable? && author.present? && self.coauthors_organizations.any?
      coauthors |= self.coauthors_organizations.map(&:users).flatten.uniq.compact
    end
    coauthors
  end

  def shared_with_coauthors?(user = User.current)
    module_coauthors_enable? &&
      coauthors_status > 0 &&
      coauthors.include?(user)
  end

  def allow_coauthors_edition?(current_user)
    module_coauthors_enable? &&
      (current_user == self.author && current_user.allowed_to?(:edit_coauthors, self.project) || current_user.admin?) &&
      author.organization.present?
  end

  def notified_as_coauthor
    # Co-Authors are always notified unless they have been
    # locked or don't want to be notified
    return [] unless module_coauthors_enable?
    notified_coauthors = coauthors - [author]
    notified_coauthors.select { |u| u.active? && u.notify_about?(self) }
  end

  def module_coauthors_enable?
    project&.module_enabled?("coauthored_issues")
  end

end
