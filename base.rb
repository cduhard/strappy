# use this for local installs
SOURCE=ENV['LOCAL'] || 'http://github.com/cduhard/strappy/raw/master'

def file_append(file, data)
  File.open(file, 'a') {|f| f.write(data) }
end

def file_inject(file_name, sentinel, string, before_after=:after)
  gsub_file file_name, /(#{Regexp.escape(sentinel)})/mi do |match|
    if :after == before_after
      "#{match}\n#{string}"
    else
      "#{string}\n#{match}"
    end
  end
end

app_name = `pwd`.split('/').last.strip

# Git
file '.gitignore', open("#{SOURCE}/gitignore").read
git :init
git :add => '.gitignore'
run 'rm -f public/images/rails.png'
run "rm config/database.yml"
file "config/database.yml", <<-FILE
development:
  adapter: mysql
  database: #{app_name}_development
  user: root
  encoding: utf8
 
test:
  adapter: mysql
  database: #{app_name}_test
  user: root
  encoding: utf8
 
production:
  username: rails
  password:
  adapter: mysql
  database: #{app_name}_production
  pool: 5
  encoding: utf8
 
FILE
run 'cp config/database.yml config/database.template.yml'
git :add => "."
git :commit => "-a -m 'Initial commit'"

#region ########### Haml, doing this before gemtools install since we are using 2.1
haml, type = false, "erb"
if yes?("Install haml?")
  haml, type = true, "haml"
  if `gem list haml | grep 2.1.0`.chomp == ''
    unless File.exist?('tmp/haml')
      inside('tmp') do
        run 'rm -rf ./haml' if File.exist?('haml')
        run 'git clone git://github.com/nex3/haml.git'
      end
    end

    inside('tmp/haml') do
      run 'rake install'
    end
  end


  run 'echo N\n | haml --rails .'
  run 'mkdir -p public/stylesheets/sass'
  %w( main reset ).each do |file|
    file "public/stylesheets/sass/#{file}.sass",
      open("#{SOURCE}/common/public/stylesheets/sass/#{file}.sass").read
  end
  git :add => "."
  git :commit => "-a -m 'Added Haml and Sass stylesheets'"
end
#endregion #########

# GemTools
file 'config/gems.yml', open("#{SOURCE}/common/config/gems.yml").read
run 'sudo gem install gem_tools --no-rdoc --no-ri'
run 'sudo gemtools install'
initializer 'gem_tools.rb', "require 'gem_tools'\nGemTools.load_gems"
git :add => "."
git :commit => "-a -m 'Added GemTools config'"


# install strappy rake tasks
rakefile 'strappy.rake', open("#{SOURCE}/common/lib/tasks/strappy.rake").read

#region ############## RSpec/Testing  #############
  plugin 'cucumber', :git => 'git://github.com/aslakhellesoy/cucumber.git'
  plugin 'machinist', :git => 'git://github.com/notahat/machinist.git'
  generate("rspec")
  generate("cucumber")

  inside ('spec') {
    run "mkdir blueprints"
    run "rm -rf fixtures"
    run "rm spec_helper.rb spec.opts rcov.opts"
  }


file 'spec/spec_helper.rb', open("#{SOURCE}/common/spec/spec_helper.rb").read
file 'spec/spec.opts', open("#{SOURCE}/common/spec/spec.opts").read
file 'spec/rcov.opts', open("#{SOURCE}/common/spec/rcov.opts").read
git :add => "."
git :commit => "-a -m 'Added RSpec'"
#endregion

# SiteConfig
file 'config/site.yml', open("#{SOURCE}/common/config/site.yml").read
lib 'site_config.rb', open("#{SOURCE}/common/lib/site_config.rb").read
initializer 'session_store.rb', <<-END
ActionController::Base.session = { :session_key => '_#{(1..6).map { |x| (65 + rand(26)).chr }.join}_session', :secret => '#{(1..40).map { |x| (65 + rand(26)).chr }.join}' }
ActionController::Base.session_store = :active_record_store
END
git :add => "."
git :commit => "-a -m 'Added SiteConfig'"

#region ##### Capistrano    ############
  capify!
  file 'config/deploy.rb', open("#{SOURCE}/common/config/deploy.rb").read

  %w( production staging ).each do |env|
    file "config/deploy/#{env}.rb", "set :rails_env, \"#{env}\""
  end

  inside('config/environments') do
    run 'cp development.rb staging.rb'
  end

  git :add => "."
  git :commit => "-a -m 'Added Capistrano config'"
#endregion

#region ##### JQUERY        ############

puts "Installing Jquery related files......"
  plugin 'jrails', :svn => 'http://ennerchi.googlecode.com/svn/trunk/plugins/jrails'

  # remove the installed files, we're using a newer version below
  inside('public/javascripts') do
    %w(
      jquery-ui.js
      jquery.js
    ).each do |file|
      run "rm -f #{file}"
    end
  end

  git :add => "."
  git :commit => "-a -m 'Added jRails plugin'"

  #jQuery

  #clean up prototype files
  inside('public/javascripts') do
    %w(
      application.js
      controls.js
      dragdrop.js
      effects.js
      prototype.js
    ).each do |file|
      run "rm -f #{file}"
    end
  end

  file 'public/javascripts/jquery.js',
    open('http://ajax.googleapis.com/ajax/libs/jquery/1.3/jquery.min.js').read
  file 'public/javascripts/jquery.full.js',
    open('http://ajax.googleapis.com/ajax/libs/jquery/1.3/jquery.js').read
  file 'public/javascripts/jquery-ui.js',
    open('http://ajax.googleapis.com/ajax/libs/jqueryui/1.5/jquery-ui.min.js').read
  file 'public/javascripts/jquery-ui.full.js',
    open('http://ajax.googleapis.com/ajax/libs/jqueryui/1.5/jquery-ui.js').read
  file 'public/javascripts/jquery.form.js',
    open('http://jqueryjs.googlecode.com/svn/trunk/plugins/form/jquery.form.js').read

  file "public/javascripts/application.js", <<-JS
  $(function() {
  });
  JS

  git :add => "."
  git :commit => "-a -m 'Added jQuery with UI and form plugin'"
#endregion  ######## END JQUERY ##############

#region ##### Blackbird     ############
puts "Installing Blackbird js files.........."
run 'mkdir -p public/blackbird'
file 'public/blackbird/blackbird.js',
  open('http://blackbirdjs.googlecode.com/svn/trunk/blackbird.js').read
file 'public/blackbird/blackbird.css',
  open('http://blackbirdjs.googlecode.com/svn/trunk/blackbird.css').read
file 'public/blackbird/blackbird.png',
  open('http://blackbirdjs.googlecode.com/svn/trunk/blackbird.png').read

git :add => "."
git :commit => "-a -m 'Added Blackbird'"
#endregion ###### END BLACKBIRD #############

#region ##### BLUEPRINT CSS ############
if yes?("Install Blueprint css?")
  puts "Installing Blueprint CSS files......."
  run "curl -L http://github.com/joshuaclayton/blueprint-css/tarball/master > public/stylesheets/blueprint.tar && tar xf public/stylesheets/blueprint.tar"
  run 'rm public/stylesheets/blueprint.tar'
  blueprint_dir = Dir.entries('.').grep(/blueprint/).first
  run "mv #{blueprint_dir}/blueprint/*.css public/stylesheets"
  run "rm -rf #{blueprint_dir}"
end
#endregion

#region ##### Add Base App Files ############

# Add ApplicationController#######
puts "Creating Application Controller....."
file 'app/controllers/application_controller.rb',
  open("#{SOURCE}/common/app/controllers/application_controller.rb").read
git :add => "."
git :commit => "-a -m 'Added ApplicationController'"


# Add Misc Application Helpers #
puts "Creating Application Helpers....."
file 'app/helpers/application_helper.rb',
  open("#{SOURCE}/common/app/helpers/application_helper.rb").read
file "app/form_builders/labeled_form_builder.rb",
  open("#{SOURCE}/common/app/form_builders/labeled_form_builder.rb").read

git :add => "."
git :commit => "-a -m 'Added Misc Application Helper'"


# Add Layout
puts "Creating Application Layout....."
  file "app/views/layouts/application.html.#{type}",
    open("#{SOURCE}/common/app/views/layouts/application.html.#{type}").read
  git :add => "."
  git :commit => "-a -m 'Added Layout'"


# remove index.html and add HomeController #
git :rm => 'public/index.html'

puts "Creating Home Controller"
generate :rspec_controller, 'home'
route "map.root :controller => 'home'"

if haml
  file 'app/views/home/index.html.haml', '%h1 Welcome' 
  file "spec/views/home/index.html.haml_spec.rb",
    open("#{SOURCE}/common/spec/views/home/index.html.haml_spec.rb").read
else
  file 'app/views/home/index.html.erb', '<h1> Welcome </h1>' 
  file "spec/views/home/index.html.erb_spec.rb",
    open("#{SOURCE}/common/spec/views/home/index.html.erb_spec.rb").read
end

file "spec/controllers/home_controller_spec.rb",
  open("#{SOURCE}/common/spec/controllers/home_controller_spec.rb").read

git :add => "."
git :commit => "-a -m 'Removed index.html. Added HomeController'"
#endregion

#region #####  Plugins      ############

puts "Installing Base Plugins......"
plugin 'asset_packager', :git => 'git://github.com/sbecker/asset_packager.git'
plugin 'exception_notifier', :git => 'git://github.com/rails/exception_notification.git'
plugin 'custom-err-msg', :git => 'git://github.com/gumayunov/custom-err-msg.git'
plugin 'validation_reflection', :git  => 'git://github.com/redinger/validation_reflection.git'
plugin 'object_daddy', :git => 'git://github.com/flogic/object_daddy.git'
plugin 'vasco', :git => 'git://github.com/relevance/vasco.git'
plugin 'bundle-fu', :git => 'git://github.com/timcharper/bundle-fu.git'
plugin 'excessive_support', :git => 'git://github.com/yizzreel/excessive_support.git'

git :add => "."
git :commit => "-a -m 'Added plugins'"
#endregion

if yes?("Create database?")
  puts "Creating databases....."
  rake "db:create:all"
end

# Setup Authentication
templ = case ask(<<-EOQ

Choose an Authentication method:
  1) Authlogic
  2) Clearance
  3) restful_authentication
  4) None of the above
EOQ
).to_s
  when '1'
    "#{SOURCE}/authlogic/base.rb"
  when '2'
    "#{SOURCE}/clearance/base.rb"
  when '3'
    "#{SOURCE}/restful_authentication/base.rb"
  else
    nil
end

if templ.nil?

else
  load_template(templ)
end

puts "\n#{'*' * 80}\n\n"
unless @auth_message.nil?
  puts "#{@auth_message}"
  puts ''
end
puts "All done. Enjoy."
puts "\n#{'*' * 80}\n\n"
