module Admin
  class CommentsController < Admin::ApplicationController
    # Overwrite any of the RESTful controller actions to implement custom behavior
    # For example, you may want to send an email after a foo is updated.
    #
    # def update
    #   super
    #   send_foo_updated_email(requested_resource)
    # end

    # Override this method to specify custom lookup behavior.
    # This will be used to set the resource for the `show`, `edit`, and `update`
    # actions.
    #
    # def find_resource(param)
    #   Foo.find_by!(slug: param)
    # end

    # The result of this lookup will be available as `requested_resource`

    # Override this if you have certain roles that require a subset
    # this will be used to set the records shown on the `index` action.
    #
    # def scoped_resource
    #   if current_user.super_admin?
    #     resource_class
    #   else
    #     resource_class.with_less_stuff
    #   end
    # end

    # Override `resource_params` if you want to transform the submitted
    # data before it's persisted. For example, the following would turn all
    # empty values into nil values. It uses other APIs such as `resource_class`
    # and `dashboard`:
    #
    # def resource_params
    #   params.require(resource_class.model_name.param_key).
    #     permit(dashboard.permitted_attributes).
    #     transform_values { |value| value == "" ? nil : value }
    # end

    # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
    # for more information
    #
    def visited
      if ["PTT", "Dcard", "蝦皮", "樂天"].include?(params[:platform])
        new_comments = Comment.unscoped.where(source_type: params[:platform], visited: false).order("RANDOM()").limit(3)
        new_comments.update(visited: true)
        authorize_resource(resource_class)
        search_term = params[:search].to_s.strip
        resources = new_comments
        page = Administrate::Page::Collection.new(dashboard, order: order)

        render "admin/comments/visited", :layout => false, locals: {
          resources: resources,
          page: page,
        }
      else
        render :nothing => true
      end
    end

    def default_sorting_attribute
      :id
    end

    def default_sorting_direction
      :desc
    end
  end
end
