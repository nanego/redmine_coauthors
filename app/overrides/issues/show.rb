Deface::Override.new :virtual_path => 'issues/show',
                     :name => 'add-coauthors-to-show-page',
                     :original => '8f374ec2439b27545906aae44228462dfe14d196',
                     :insert_bottom => 'p.author',
                     :partial => 'issues/show_coauthors'
