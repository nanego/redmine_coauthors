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
          coauthored_issues_statement = Issue.joins(:coauthors_organization).where(organizations: { id: user_organization.id }).select(:id).to_sql
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

  def shared_with_coauthors?(user = User.current)
    coauthors_status > 0 && coauthors.include?(user)
  end

  def allow_coauthors?(current_user)
    self.project.module_enabled?("coauthored_issues") &&
      current_user.allowed_to?(:edit_coauthors, self.project) &&
      current_user == self.author &&
      author.organization.present?
  end

end
