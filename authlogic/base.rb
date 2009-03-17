# Setup Authlogic
raise "BOOM"
plugin 'authlogic', :git => 'git://github.com/cduhard/authlogic.git'
plugin 'declarative_authorization', :git => 'git://github.com/stffn/declarative_authorization.git'

# add gems to gems.yml
file_append('config/gems.yml',
  open("#{SOURCE}/authlogic/config/gems.yml").read)
run 'sudo gemtools install'

file_append('config/locales/en.yml',
  open("#{SOURCE}/authlogic/config/locales/en.yml").read)

# rails gets cranky when this isn't included in the config
generate 'session user_session'
generate 'rspec_controller user_sessions'
generate 'scaffold user email:string \
  first_name:string \
  last_name:string \
  crypted_password:string \
  password_salt:string \
  persistence_token:string \
  login_count:integer \
  last_request_at:datetime \
  last_login_at:datetime \
  current_login_at:datetime \
  last_login_ip:string \
  current_login_ip:string \
  time_zone:string' 

# get rid of the generated templates
Dir.glob('app/views/users/*.erb').each do |file|
  run "rm #{file}"
end
run "rm app/views/layouts/users.html.erb"

generate 'controller password_resets'

route "map.logout '/logout', :controller => 'user_sessions', :action => 'destroy'"
route "map.login '/login', :controller => 'user_sessions', :action => 'new'"
route "map.signup '/signup', :controller => 'users', :action => 'new'"
route 'map.resource :user_session'
route 'map.resource :account, :controller => "users"'
route 'map.resources :password_resets'
route "map.register '/register/:activation_code', :controller => 'activations', :action => 'new'"
route "map.activate '/activate/:id', :controller => 'activations', :action => 'create'"

# migrations
file Dir.glob('db/migrate/*_create_users.rb').first,
  open("#{SOURCE}/authlogic/db/migrate/create_users.rb").read

# models
%w( user notifier ).each do |name|
  file "app/models/#{name}.rb",
    open("#{SOURCE}/authlogic/app/models/#{name}.rb").read
end

# controllers
%w( activations user_sessions password_resets users ).each do |name|
  file "app/controllers/#{name}_controller.rb",
    open("#{SOURCE}/authlogic/app/controllers/#{name}_controller.rb").read
end

#declarative authorization
file "app/config/authorization_rules.rb", open("#{SOURCE}/authlogic/app/views/authorization_rules.rb").read

# views
type = if yes?("Using haml views?")
         "haml"
        else
          "erb"
        end

%w(
  activations/new.html
  notifier/password_reset_instructions
  notifier/activation_confirmation
  notifier/activation_instructions
  password_reset/edit.html
  password_reset/new.html
  user_sessions/new.html
  users/_form
  users/edit.html
  users/new.html
  users/show.html
).each do |name|
  file "app/views/#{name}.#{type}", open("#{SOURCE}/authlogic/app/views/#{name}.#{type}").read
end

# testing goodies
file_inject('/spec/spec_helper.rb',
  "require 'spec/rails'",
  "require 'authlogic/testing/test_unit_helpers'\n",
  :after
)

# specs
run 'mkdir -p spec/fixtures'

%w(
  fixtures/users.yml
  controllers/application_controller_spec.rb
  controllers/password_reset_controller_spec.rb
  controllers/user_sessions_controller_spec.rb
  controllers/users_controller_spec.rb
  views/home/index.html.haml_spec.rb
).each do |name|
  file "spec/#{name}", open("#{SOURCE}/authlogic/spec/#{name}").read
end

rake('db:migrate')
git :add => "."
git :commit => "-a -m 'Added Authlogic'"

# Add ApplicationController
file 'app/controllers/application_controller.rb',
  open("#{SOURCE}/authlogic/app/controllers/application_controller.rb").read
git :add => "."
git :commit => "-a -m 'Added ApplicationController'"

# Application Layout
file 'app/views/layouts/application.html.haml',
  open("#{SOURCE}/authlogic/app/views/layouts/application.html.haml").read
git :add => "."
git :commit => "-a -m 'Added Layout'"

@auth_message = 'Authlogic authentication installed'
