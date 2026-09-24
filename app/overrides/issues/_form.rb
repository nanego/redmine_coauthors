Deface::Override.new :virtual_path => 'issues/_form',
                     :name => 'add-coauthors-form-field',
                     :insert_after => 'erb[loud]:contains("hidden_field_tag \'back_url\'")',
                     :partial => 'issues/coauthors_form'

Deface::Override.new :virtual_path => 'issues/_form_with_positions',
                     :name => 'add-coauthors-form-field',
                     :insert_after => 'erb[loud]:contains("hidden_field_tag \'back_url\'")',
                     :partial => 'issues/coauthors_form'
