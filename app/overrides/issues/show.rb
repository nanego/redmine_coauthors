Deface::Override.new :virtual_path => 'issues/show',
                     :name => 'add-coauthors-to-show-page',
                     :insert_bottom => 'p.author',
                     :partial => 'issues/show_coauthors'
