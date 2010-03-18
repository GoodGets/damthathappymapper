module HappyMapper
  class Item
    attr_accessor :name, :type, :tag, :options, :namespace

    Types = [String, Float, Time, Date, DateTime, Integer, Boolean]

    # options:
    #   :deep   =>  Boolean False to only parse element's children, True to include
    #               grandchildren and all others down the chain (// in xpath)
    #   :namespace => String Element's namespace if it's not the global or inherited
    #                  default
    #   :parser =>  Symbol Class method to use for type coercion.
    #   :raw    =>  Boolean Use raw node value (inc. tags) when parsing.
    #   :single =>  Boolean False if object should be collection, True for single object
    #   :tag    =>  String Element name if it doesn't match the specified name.
    def initialize(name, type, o={})
      self.name = name.to_s
      self.type = type
      #self.tag = o.delete(:tag) || name.to_s
      self.tag = o[:tag] || name.to_s
      self.options = { :single => true }.merge(o.merge(:name => self.name))

      @xml_type = self.class.to_s.split('::').last.downcase
    end

    def constant
      @constant ||= constantize(type)
    end
        
    def from_xml_node(node, namespace, xpath_options)
      if primitive?
        find(node, namespace, xpath_options) do |n|
          if n.respond_to?(:content)
            typecast(n.content)
          else
            typecast(n.to_s)
          end
        end
      elsif constant == XmlContent
        find(node, namespace, xpath_options) do |n|
          n = n.children if n.respond_to?(:children)
          n.respond_to?(:to_xml) ? n.to_xml : n.to_s
        end
      else
        if options[:parser]
          find(node, namespace, xpath_options) do |n|
            if n.respond_to?(:content) && !options[:raw]
              value = n.content
            else
              value = n.to_s
            end

            begin
              constant.send(options[:parser].to_sym, value)
            rescue
              nil
            end
          end
        else
          constant.parse(node, options.merge(:namespaces => xpath_options))
        end
      end
    end

    def xpath(namespace = self.namespace)
      xpath  = ''
      xpath += './/' if options[:deep]
      xpath += "#{namespace}:" if namespace
      xpath += tag
      # puts "xpath: #{xpath}"
      xpath
    end

    def primitive?
      Types.include?(constant)
    end

    def element?
      @xml_type == 'element'
    end

    def attribute?
      @xml_type == 'attribute'
    end

    def text_node?
      @xml_type == 'textnode'
    end

    def method_name
      @method_name ||= name.tr('-', '_')
    end

    def typecast(value)
      return value if value.kind_of?(constant) || value.nil?
      begin        
        if    constant == String    then value.to_s
        elsif constant == Float     then value.to_f
        elsif constant == Time      then Time.parse(value.to_s) rescue Time.at(value.to_i)
        elsif constant == Date      then Date.parse(value.to_s)
        elsif constant == DateTime  then DateTime.parse(value.to_s)
        elsif constant == Boolean   then ['true', 't', '1'].include?(value.to_s.downcase)
        elsif constant == Integer
          # ganked from datamapper
          value_to_i = value.to_i
          if value_to_i == 0 && value != '0'
            value_to_s = value.to_s
            begin
              Integer(value_to_s =~ /^(\d+)/ ? $1 : value_to_s)
            rescue ArgumentError
              nil
            end
          else
            value_to_i
          end
        else
          value
        end
      rescue
        value
      end
    end

    private

      def constantize(type)
        if type.is_a?(String)
          names = type.split('::')
          constant = Object
          names.each do |name|
            constant =
              if constant.const_defined?(name)
                constant.const_get(name)
              else
                constant.const_missing(name)
              end
          end
          constant
        else
          type
        end
      end


      def find(node, namespace, xpath_options, &block)
        if self.namespace && xpath_options["xmlns:#{self.namespace}"]
          # from the class definition
          namespace = self.namespace
        elsif options[:namespace] && xpath_options["xmlns:#{options[:namespace]}"]
          namespace = options[:namespace]
        end
        
        if element?
          if options[:single]
            result = node.xpath(xpath(namespace), xpath_options)

            if result
              value = options[:single] ? yield(result.first) : result.map {|r| yield r }
              handle_attributes_option(result, value, xpath_options)

              value
            end
          else
            results = node.xpath(xpath(namespace), xpath_options).collect do |result|
              value = yield(result)
              handle_attributes_option(result, value, xpath_options)
              value
            end
            results
          end
        elsif attribute?
          yield(node[tag])
        else # text node
          yield(node.children.detect{|c| c.text?})
        end
      end

      def handle_attributes_option(result, value, xpath_options)
        if options[:attributes].is_a?(Hash)
          result = result.first if result.respond_to?(:first)

          result.attribute_nodes.each do |xml_attribute|
            if attribute_options = options[:attributes][xml_attribute.name.to_sym]
              attribute_value = Attribute.new(xml_attribute.name.to_sym, *attribute_options).from_xml_node(result, namespace, xpath_options)

              result.instance_eval <<-EOV
                def value.#{xml_attribute.name}
                  #{attribute_value.inspect}
                end
              EOV
            end # if attributes_options
          end # attribute_nodes.each
        end # if options[:attributes]
      end # def handle...

    # end private methods
  end
end
