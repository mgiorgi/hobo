module Hobo::ControllerHelpers

  protected

  def current_user
    # simple one-hit-per-request cache
    @current_user or
      @current_user = if Hobo.user_model and session and id = session[:user]
                             Hobo.user_model.find(id)
                           else 
                             Guest.new
                           end 
  end


  def urlb
    request.relative_url_root
  end


  def controller_for(obj)
    if obj.is_a? Class
      obj.name.underscore.pluralize
    else
      obj.class.name.underscore.pluralize
    end
  end


  def object_url(obj, action=nil, *param_hashes)
    parts = if obj.is_a? Class
              [urlb, controller_for(obj)]
            elsif obj.is_a? ActiveRecord::Base
              if obj.new_record?
                [urlb, controller_for(obj)]
              else
                raise HoboError.new("invalid object url: new for existing object") if action == "new"

                klass = obj.class
                id = if klass.id_name?
                       obj.id_name(true)
                     else
                       obj.id
                     end
                [urlb, controller_for(obj), id]
              end
            elsif obj.is_a? Array    # warning - this breaks if we use `case/when Array`
              owner = obj.proxy_owner
              new_model = obj.proxy_reflection.klass
              [object_url(owner), obj.proxy_reflection.name]
            else
              raise HoboError.new("cannot create url for #{obj.inspect}")
            end
    basic = parts.join("/")
    url = case action
          when "new"
            basic + "/new"
          when "destroy"
            basic + "?_method=DELETE"
          when "update"
            basic + "?_method=PUT"
          when nil
            basic
          else
            basic + ";" + action
          end
    params = make_params(*param_hashes)
    params.blank? ? url : url + "?" + params
  end


  def _as_params(name, obj)
    if obj.is_a? Array
      obj.map {|x| _as_params("#{name}[]", x)}.join("&")
    elsif obj.is_a? Hash
      obj.map {|k,v| _as_params("#{name}[#{k}]", v)}.join("&")
    elsif obj.is_a? Hobo::RawJs
      "#{name}=' + #{obj} + '"
    else
      v = if obj.is_a?(ActiveRecord::Base) or obj.is_a?(Array)
            "@" + dom_id(obj)
          else
            obj.to_s.gsub("'"){"\\'"}
          end
      "#{name}=#{v}"
    end
  end


  def make_params(*hashes)
    hash = {}
    hashes.each {|h| hash.update(h) if h}
    hash.map {|k,v| _as_params(k, v)}.join("&")
  end


  def dom_id(x, attr=nil)
    Hobo.dom_id(x, attr)
  end


end