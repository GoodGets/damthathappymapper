# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{damthathappymapper}
  s.version = "0.3.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Nunemaker and Damien Le Berrigaud"]
  s.date = %q{2009-10-24}
  s.description = %q{object to xml mapping library (ported to use Nokogiri instead of libxml-ruby)}
  s.email = %q{nunemaker@gmail.com}
  s.extra_rdoc_files = ["lib/happymapper/attribute.rb", "lib/happymapper/element.rb", "lib/happymapper/item.rb", "lib/happymapper/version.rb", "lib/happymapper.rb", "README"]
  s.files = ["damthathappymapper.gemspec", "History", "lib/happymapper/attribute.rb", "lib/happymapper/element.rb", "lib/happymapper/item.rb", "lib/happymapper/version.rb", "lib/happymapper.rb", "License", "Manifest", "Rakefile", "README", "spec/happymapper_attribute_spec.rb", "spec/happymapper_element_spec.rb", "spec/happymapper_item_spec.rb", "spec/happymapper_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "website/css/common.css", "website/index.html"]
  s.homepage = %q{http://happymapper.rubyforge.org}
  s.post_install_message = %q{May you have many (dam) happy mappings!}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Happymapper", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{happymapper}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{object to xml mapping library (ported to use Nokogiri instead of libxml-ruby)}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<nokogiri>, ["= 1.4.1"])
    else
      s.add_dependency(%q<nokogiri>, ["= 1.4.1"])
    end
  else
    s.add_dependency(%q<nokogiri>, ["= 1.4.1"])
  end
end
