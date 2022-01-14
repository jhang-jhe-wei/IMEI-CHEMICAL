class Comment < ApplicationRecord
  default_scope {where(:visited => true)}
end
