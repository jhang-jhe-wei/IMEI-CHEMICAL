# All Administrate controllers inherit from this
# `Administrate::ApplicationController`, making it the ideal place to put
# authentication logic or other before_actions.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
module Admin
  class ApplicationController < Administrate::ApplicationController
    before_action :authenticate_user!
    Admin_roles = ["admin"]
    Admin_actions = [:new, :destroy, :edit]

    def show_action?(_action, _resource)
      if Admin_actions.include?(_action)
        Admin_roles.include?(current_user.role)? true:false
      else
        true
      end
    end
  end
end
