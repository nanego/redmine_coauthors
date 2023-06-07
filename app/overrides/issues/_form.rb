Deface::Override.new :virtual_path => 'issues/_form',
                     :name => 'add-coauthors-form-field',
                     :original => '8f374ec2439b27545906aae44228462dfe14d196',
                     :insert_after => 'erb[loud]:contains("hidden_field_tag \'back_url\'")',
                     :partial => 'redmine_coauthors/form'

Deface::Override.new :virtual_path => 'issues/_form_with_positions',
                     :name => 'add-coauthors-form-field',
                     :original => '8f374ec2439b27545906aae44228462dfe14d196',
                     :insert_after => 'erb[loud]:contains("hidden_field_tag \'back_url\'")',
                     :partial => 'redmine_coauthors/form'
