Puppet::Parser::Functions::newfunction(:permute, :doc => '
') do |args|
  raise ArgumentError, ("create_resources(): wrong number of arguments (#{args.length}; must be 2)") if args.length != 2
  #raise ArgumentError, 'requires resource type and param hash' if args.size < 2
  # figure out what kind of resource we are
  type_of_resource = nil
  type_name = args[0].downcase
  if type_name == 'class'
    type_of_resource = :class
  else
    if resource = Puppet::Type.type(type_name.to_sym)
      type_of_resource = :type
    elsif resource = find_definition(type_name.downcase)
      type_of_resource = :define
    else
      raise ArgumentError, "could not create resource of unknown type #{type_name}"
    end
  end
  Puppet.notice "args[1] is #{args[1]} #{args[1].class}"
  # iterate through the resources to create
  args[1].each do |title, params|
    Puppet.notice :type_of_resource
    Puppet.notice "title is #{title}"
    Puppet.notice "params is #{params}"
    Puppet.notice "params class is #{params.class}"

    raise ArgumentError, 'params should not contain title' if(params['title'])
    case type_of_resource
    when :type
      res = resource.hash2resource(params.merge(:title => title))
      catalog.add_resource(res)
    when :define
      p_resource = Puppet::Parser::Resource.new(type_name, title, :scope => self, :source => resource)
      params.merge(:name => title).each do |k,v|
        p_resource.set_parameter(k,v)
        Puppet.notice "v is #{v} #{v.class}"
        Puppet.notice "k is #{k} #{k.class}"
      end
      #resource.instantiate_resource(self, p_resource)
      #compiler.add_resource(self, p_resource)
    when :class
      klass = find_hostclass(title)
      raise ArgumentError, "could not find hostclass #{title}" unless klass
      klass.ensure_in_catalog(self, params)
      compiler.catalog.add_class([title])
    end
  end
end

