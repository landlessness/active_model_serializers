# TODO: use the Oat-style schema proc model create
# a module called something like 
# ActiveModel::Serializer::Adapter::Schema
# include it in this class then let the 


class ActiveModel::Serializer::Adapter::Siren < ActiveModel::Serializer::Adapter
  extend ActiveSupport::Autoload
  autoload :PaginationLinks
  autoload :FragmentCache

  attr_reader :href_url, :rel_url

  def initialize(serializer, options = {})
    super
    @included = ActiveModel::Serializer::Utils.include_args_to_hash(@options[:include])
    puts "@@@included " + @included.inspect
  end

  def serializable_hash(options = nil)
    @href_url=options[:context].href
    @rel_url=options[:context].rel
    {
      class: render_class,
      properties: render_properties,
      entities: render_entities,
      actions: render_actions,
      links: render_links
    }
  end

  private
  
  # Primary renderers: class, properties, entities, actions, links

  def render_class(resource = serializer)
    [resource.object.class.model_name.singular]
  end
  
  def render_properties
    {}
  end
  
  def render_entities
    serializer.class._reflections.map do |r|
      render_collection r
    end
    # resource.associations.map do |association|
    #   render_collection association, resource
    # end
  end
  
  def render_actions
    {}
  end

  def render_links
    {}
  end

  # helper methods

  def render_collection(reflection)
    {
      class: render_collection_class(reflection),
      rel: render_collection_rel(reflection),
      href: render_collection_href(reflection)
    }
  end

  def render_collection_class(reflection)
    [reflection.name.to_s, 'collection']
  end

  def render_rel(resource)
    [rel_url_for(resource), rel_type_for(resource)].compact
  end

  def render_collection_rel(reflection)
    ["#{rel_url}/#{reflection.name}", rel_type_for(reflection)].compact
  end

  def render_href(resource)
    "#{href_url}/#{type_id_for(resource)}"
  end

  def render_collection_href(reflection)
    "#{href_url}/#{type_id_for(serializer)}/#{reflection.name}"
  end
  
  def render_entity(resource, parent=nil)
    {
      class: render_class(resource),
      rel: render_rel(resource),
      href: render_href(resource, parent)
    }
  end

  def rel_url_for(resource)
    "#{rel_url}/#{type_for(resource)}"
  end

  def rel_type_for(reflection)
    case 
    when reflection.class == ActiveModel::Serializer::BelongsToReflection
      'belongsTo'
    when reflection.class == ActiveModel::Serializer::HasManyReflection
      'hasMany'
    when reflection.class == ActiveModel::Serializer::HasOneReflection
      'hasOne'
    when reflection.class == ActiveModel::Serializer::Singular
      'singular'
    else
      nil
    end
  end

  def type_id_for(resource)
    s = type_for resource
    unless resource.respond_to?(:key)
      s += "/#{id_for(resource)}"
    end
    s
  end

  def type_for(resource)
    if resource.respond_to?(:key)
      resource.key.to_s
    else
      resource.object.class.model_name.plural
    end
  end

  def id_for(resource)
    if resource.respond_to?(:id)
      resource.id
    else
      resource.object.id
    end
  end

end