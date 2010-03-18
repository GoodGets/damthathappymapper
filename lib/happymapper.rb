dir = File.dirname(__FILE__)

require 'date'
require 'time'
require 'rubygems'
require 'nokogiri'

class Boolean; end
class XmlContent; end

module HappyMapper

  DEFAULT_NS = "happymapper"

  def self.included(base)
    base.instance_variable_set("@attributes", {})
    base.instance_variable_set("@elements", {})
    base.extend ClassMethods
  end

  module ClassMethods
    def attribute(name, type, options={})
      attribute = Attribute.new(name, type, options)
      @attributes[to_s] ||= []
      @attributes[to_s] << attribute
      attr_accessor attribute.method_name.intern
    end

    def attributes
      @attributes[to_s] || []
    end

    def element(name, type, options={})
      element = Element.new(name, type, options)
      @elements[to_s] ||= []
      @elements[to_s] << element
      attr_accessor element.method_name.intern
    end

    def elements
      @elements[to_s] || []
    end

    def text_node(name, type, options={})
      @text_node = TextNode.new(name, type, options)
      attr_accessor @text_node.method_name.intern
    end

    def has_xml_content
      attr_accessor :xml_content
    end
    
    def has_one(name, type, options={})
      element name, type, {:single => true}.merge(options)
    end

    def has_many(name, type, options={})
      element name, type, {:single => false}.merge(options)
    end

    # Specify a namespace if a node and all its children are all namespaced
    # elements. This is simpler than passing the :namespace option to each
    # defined element.
    def namespace(namespace = nil)
      @namespace = namespace if namespace
      @namespace
    end

    def tag(new_tag_name)
      @tag_name = new_tag_name.to_s unless new_tag_name.nil? || new_tag_name.to_s.empty?
    end

    def tag_name
      @tag_name ||= to_s.split('::')[-1].downcase
    end

    def parse(xml, options = {})
      # locally scoped copy of namespace for this parse run
      namespace = @namespace

      if xml.is_a?(Nokogiri::XML::Node)
        node = xml
      else
        if xml.is_a?(Nokogiri::XML::Document)
          node = xml.root
        else
          xml = Nokogiri::XML(xml)
          node = xml.root
        end

        root = node.name == tag_name
      end

      # This is the entry point into the parsing pipeline, so the default
      # namespace prefix registered here will propagate down
      namespaces = options[:namespaces] || xml.namespaces
      if namespaces.has_key?("xmlns")
        namespace ||= DEFAULT_NS
        namespaces[namespace] = namespaces.delete("xmlns")
      elsif namespaces.has_key?(DEFAULT_NS)
        namespace ||= DEFAULT_NS
      end

      xpath = root ? '/' : './/'
      xpath += "#{namespace}:" if namespace
      #puts "parse: #{xpath}"

      nodes = []
      # when finding nodes, do it in this order:
      # 1. specified tag
      # 2. name of element
      # 3. tag_name (derived from class name by default)
      [options[:tag], options[:name], tag_name].compact.each do |xpath_ext|
        nodes = node.xpath(xpath + xpath_ext.to_s, namespaces)
        break if nodes && nodes.size > 0
      end

      collection = nodes.collect do |n|
        obj = new

        attributes.each do |attr|
          obj.send("#{attr.method_name}=",
                    attr.from_xml_node(n, namespace, namespaces))
        end

        elements.each do |elem|
          obj.send("#{elem.method_name}=", 
                    elem.from_xml_node(n, namespace, namespaces))
        end

        obj.send("#{@text_node.method_name}=", 
                  @text_node.from_xml_node(n, namespace, namespaces)) if @text_node

        if obj.respond_to?('xml_content=')
          n = n.children if n.respond_to?(:children)
          obj.xml_content = n.to_xml 
        end
        
        obj
      end

      # per http://libxml.rubyforge.org/rdoc/classes/LibXML/XML/Document.html#M000354
      nodes = nil

      if options[:single] || root
        collection.first
      else
        collection
      end
    end
  end
end

require File.join(dir, 'happymapper/item')
require File.join(dir, 'happymapper/attribute')
require File.join(dir, 'happymapper/element')
require File.join(dir, 'happymapper/text_node')
