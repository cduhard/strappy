Feature: sign up
  In order to use all the platform's features
  As a user
  I want to sign up

Scenario: sign up successfully
  When I go to the start page
  And I follow "Sign up"
  And I fill in "alex" for "Login"
  And I fill in "testtest" for "Password"
  And I fill in "testtest" for "Password confirmation"
  And I press "Register"
  Then I should see "Welcome alex"
 
Scenario: signing up fails because login is taken
  Given a user "alex"
  When I go to the start page
  And I follow "Sign up"
  And I fill in "alex" for "Login"
  And I fill in "testtest" for "Password"
  And I fill in "testtest" for "Password confirmation"
  And I press "Register"
  Then I should not see "Welcome alex"
  And I should see "Login ist bereits vergeben"