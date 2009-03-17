Before do
  User.delete_all
end
 
Given /^a user "(.+)" with the password "(.+)"$/ do |login, password|
  User.make :login => login, :password => password, :password_confirmation => password
end
 
Given /a user "([^"]+)"$/ do |login|
  User.make :login => login
end
 
Given /^"([^"]+)" is logged in$/ do |login|
  When 'I go to the start page'
  When 'I follow "Log in"'
  When "I fill in \\\"\#{login}\\\" for \\\"Login\\\""
  When 'I fill in "testtest" for "Password"'
  When 'I press "Login"'
end