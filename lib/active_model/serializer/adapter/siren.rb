class ActiveModel::Serializer::Adapter::Siren < ActiveModel::Serializer::Adapter
  extend ActiveSupport::Autoload
  autoload :PaginationLinks
  autoload :FragmentCache

  def serializable_hash(options = nil)
    {
      class: render_class,
      entities: render_entities
    }
  end

  private
  
  def render_class(resource = serializer)
    if resource.respond_to?(:key)
      [resource.key.to_s, 'collection']
    else
      [resource.object.class.model_name.singular]
    end
  end
  
  def render_entities(resource = serializer)
    resource.associations.map do |association|
      render_association association
    end
  end
  
  def render_rel(resource)
    #TODO: make this real
    ['http://rels.not-foo.org/...']
  end
  
  def render_href(resource)
    #TODO: make this real
    'http://rels.not-foo.org/...'
  end
  
  def render_association(association)
    render_entity(association).merge(render_subentities(association.serializer))
  end
  
  def render_entity(resource)
    {
      class: render_class(resource),
      rel: render_rel(resource),
      href: render_href(resource)
    }
  end
  
  def render_subentities(serializer, options = {})
    if serializer.respond_to?(:each)
      {
        entities: serializer.map { |s| render_entity s }
      }
    else
      if options[:virtual_value]
        options[:virtual_value]
      elsif serializer && serializer.object
        render_entity serializer
      end
    end
  end
  
end