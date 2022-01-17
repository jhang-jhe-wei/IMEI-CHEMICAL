# All Administrate controllers inherit from this
# `Administrate::ApplicationController`, making it the ideal place to put
# authentication logic or other before_actions.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
module Admin
  class ApplicationController < Administrate::ApplicationController
    before_action :authenticate_user!
    before_action :authorization_action
    Admin_roles = ["admin"]
    Admin_actions = [:new, :destroy, :edit, :update, :put, :create]

    def authorization?
      return true if controller_is_comments? && action_name == "visited"
      return false if controller_is_comments? && !is_index_or_show?
      return false if controller_is_users? && !is_admin?
      return false if !is_admin? && !is_index_or_show?
      true
    end

    def authorization_action
      head :forbidden unless authorization?
    end

    def show_action?(_action, _resource)
      return false if _resource.class == Comment && !(_action == :index || _action == :show )
      return false if _resource == User && !is_admin?
      return false if !is_admin? && !(_action == :index || _action == :show )
      true
    end

    private
    def is_index_or_show?
      action_name == "index" || action_name == "show"
    end

    def is_admin?
      Admin_roles.include?(current_user.role)
    end

    def controller_is_users?
      controller_name == "users"
    end

    def controller_is_comments?
      controller_name == "comments"
    end
  end
end
