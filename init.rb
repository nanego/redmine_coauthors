Redmine::Plugin.register :redmine_coauthors do
  name 'Redmine Coauthors plugin'
  author 'Vincent ROBERT'
  description 'This is a plugin for Redmine which adds coauthors to issues.'
  version '0.0.1'
  url 'https://github.com/nanego/redmine_coauthors'
  author_url 'https://github.com/nanego'
  requires_redmine_plugin :redmine_base_rspec, :version_or_higher => '0.0.4' if Rails.env.test?
end

